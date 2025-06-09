# iOS Token Refresh Implementation Guide

## Problem Summary
- **Backend**: ✅ Working correctly, rejecting expired Firebase tokens
- **iOS App**: ❌ Sending expired tokens (Firebase ID tokens only last 1 hour)
- **Result**: 401 "Authentication required" errors after token expiration

## Implementation Plan

### 1. Update APIClient Token Provider

The current implementation in `clarity_loop_frontendApp.swift` fetches a fresh token every time, but we need to ensure this happens correctly:

```swift
// Current implementation (line 41-77)
guard let client = APIClient(tokenProvider: {
    // This is already forcing refresh, which is good!
    let tokenResult = try await user.getIDTokenResult(forcingRefresh: true)
    return tokenResult.token
}) else {
    fatalError("Failed to initialize APIClient with a valid URL.")
}
```

### 2. Fix the Real Issue: Token Provider Not Being Called

The problem is that the token provider is being called, but the Firebase token has genuinely expired on Firebase's servers. We need to handle this case properly.

### 3. Update APIClient to Handle Token Expiration

Modify `APIClient.swift` to better handle token refresh:

```swift
// In APIClient.swift, update performRequest method around line 208-346

private func performRequest<T: Decodable>(
    for endpoint: Endpoint,
    requiresAuth: Bool = true
) async throws -> T {
    print("🚀 APIClient: Starting request to \(endpoint.path)")
    
    guard let request = try? endpoint.asURLRequest(baseURL: baseURL, encoder: encoder) else {
        print("❌ APIClient: Invalid URL for endpoint \(endpoint.path)")
        throw APIError.invalidURL
    }
    
    var authorizedRequest = request
    if requiresAuth {
        print("🔑 APIClient: Attempting to retrieve auth token...")
        
        // Get fresh token
        guard let token = await tokenProvider() else {
            print("❌ APIClient: Failed to retrieve auth token")
            throw APIError.unauthorized
        }
        
        print("✅ APIClient: Token retrieved (length: \(token.count))")
        
        // IMPORTANT: Check if this is a test token
        if token == "test-token-123" {
            print("⚠️ WARNING: Using test token! This will fail authentication!")
        }
        
        authorizedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    do {
        let (data, response) = try await session.data(for: authorizedRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown(URLError(.badServerResponse))
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            // Success - decode response
            do {
                if data.isEmpty, let empty = EmptyResponse() as? T {
                    return empty
                }
                return try decoder.decode(T.self, from: data)
            } catch {
                print("❌ APIClient: Decoding error: \(error)")
                throw APIError.decodingError(error)
            }
            
        case 401:
            print("❌ APIClient: Unauthorized (401)")
            
            // If we have auth and got 401, try ONE more time with a fresh token
            if requiresAuth {
                print("🔄 APIClient: Attempting token refresh...")
                
                // Force Firebase to refresh its token
                if let user = Auth.auth().currentUser {
                    do {
                        // Force refresh from Firebase servers
                        _ = try await user.getIDToken(forcingRefresh: true)
                        print("✅ APIClient: Firebase token refreshed")
                        
                        // Now try our token provider again
                        if let refreshedToken = await tokenProvider() {
                            print("🔑 APIClient: Retrying with refreshed token...")
                            authorizedRequest.setValue("Bearer \(refreshedToken)", forHTTPHeaderField: "Authorization")
                            
                            // Retry the request once
                            let (retryData, retryResponse) = try await session.data(for: authorizedRequest)
                            
                            if let retryHttpResponse = retryResponse as? HTTPURLResponse,
                               retryHttpResponse.statusCode >= 200 && retryHttpResponse.statusCode < 300 {
                                print("✅ APIClient: Retry succeeded after token refresh")
                                
                                if retryData.isEmpty, let empty = EmptyResponse() as? T {
                                    return empty
                                }
                                return try decoder.decode(T.self, from: retryData)
                            }
                        }
                    } catch {
                        print("❌ APIClient: Firebase token refresh failed: \(error)")
                    }
                }
            }
            
            throw APIError.unauthorized
            
        default:
            let serverMessage = try? decoder.decode(MessageResponseDTO.self, from: data).message
            print("❌ APIClient: Server error \(httpResponse.statusCode): \(serverMessage ?? "No message")")
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: serverMessage)
        }
    } catch let error as APIError {
        throw error
    } catch let error as URLError {
        throw APIError.networkError(error)
    } catch {
        throw APIError.unknown(error)
    }
}
```

### 4. Add Token Expiration Check in AuthService

Update `AuthService.swift` to check token expiration:

```swift
// In AuthService.swift, update getCurrentUserToken() around line 141

func getCurrentUserToken() async throws -> String {
    print("🔍 AUTH: getCurrentUserToken() called")
    
    guard let user = Auth.auth().currentUser else {
        print("❌ AUTH: No current user found!")
        throw APIError.unauthorized
    }
    
    print("✅ AUTH: Current user exists - UID: \(user.uid)")
    
    // Get token result to check expiration
    do {
        // First try without forcing refresh to check expiration
        let tokenResult = try await user.getIDTokenResult(forcingRefresh: false)
        
        // Check if token is expired or will expire soon (within 5 minutes)
        let expirationDate = tokenResult.expirationDate
        let timeUntilExpiration = expirationDate.timeIntervalSinceNow
        
        print("🕐 AUTH: Token expires in \(timeUntilExpiration) seconds")
        
        if timeUntilExpiration < 300 { // Less than 5 minutes
            print("⚠️ AUTH: Token expiring soon, forcing refresh...")
            let refreshedResult = try await user.getIDTokenResult(forcingRefresh: true)
            print("✅ AUTH: Token refreshed successfully")
            return refreshedResult.token
        } else {
            print("✅ AUTH: Token still valid")
            return tokenResult.token
        }
    } catch {
        print("❌ AUTH: Failed to get ID token: \(error)")
        throw error
    }
}
```

### 5. Test the Implementation

Create a test file to verify token refresh works:

```swift
// TokenRefreshTests.swift
import XCTest
import FirebaseAuth
@testable import clarity_loop_frontend

class TokenRefreshTests: XCTestCase {
    
    func testTokenRefreshOnExpiration() async throws {
        // This test requires being signed in
        // Run it manually after signing in to the app
        
        let authService = AuthService(apiClient: MockAPIClient())
        
        // Get token multiple times to ensure refresh works
        for i in 1...3 {
            print("Test iteration \(i)")
            let token = try await authService.getCurrentUserToken()
            XCTAssertFalse(token.isEmpty)
            print("Token length: \(token.count)")
            
            // Wait a bit between attempts
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }
    }
}
```

### 6. Debug Helper

Add this debug view to test token refresh manually:

```swift
// Add to TokenDebugView.swift

Button("Test Token Refresh") {
    Task {
        do {
            print("🔄 Testing token refresh...")
            
            // Force sign out and sign in to get fresh auth state
            if let user = Auth.auth().currentUser {
                let token1 = try await user.getIDToken(forcingRefresh: false)
                print("Token 1 (no refresh): \(token1.prefix(20))...")
                
                let token2 = try await user.getIDToken(forcingRefresh: true)
                print("Token 2 (forced refresh): \(token2.prefix(20))...")
                
                print("Tokens are \(token1 == token2 ? "same" : "different")")
            }
        } catch {
            print("❌ Token refresh test failed: \(error)")
        }
    }
}
.buttonStyle(.bordered)
```

## Verification Steps

1. **Build and run the app**
2. **Sign in with valid credentials**
3. **Navigate to Debug tab**
4. **Test "Generate Insight (Auth Required)"**
   - Should work immediately after sign in
   - Should continue working even after 1+ hours
5. **Monitor console logs for**:
   - "🕐 AUTH: Token expires in X seconds"
   - "⚠️ AUTH: Token expiring soon, forcing refresh..."
   - "✅ AUTH: Token refreshed successfully"

## Expected Behavior

- Tokens should automatically refresh when they have less than 5 minutes remaining
- API calls should succeed even after the app has been running for hours
- Failed requests due to token expiration should automatically retry once with a fresh token

## Common Issues

1. **Token still expired after refresh**
   - Check device time is correct
   - Ensure Firebase project is properly configured
   - Verify network connectivity

2. **Refresh fails**
   - User might have been deleted or disabled
   - Firebase project might have issues
   - Check Firebase console for any alerts

3. **Still getting 401 after implementation**
   - Check backend logs to see what error Firebase is reporting
   - Verify the token in jwt.io to check expiration time
   - Ensure the Firebase project ID matches between frontend and backend