//
//  TokenDebugView.swift
//  clarity-loop-frontend
//
//  Debug view to test token extraction and validation
//

import FirebaseAuth
import SwiftUI

struct TokenDebugView: View {
    @State private var tokenInfo = "Tap button to get token info"
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Token Debug Info")
                .font(.title)
            
            ScrollView {
                Text(tokenInfo)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(maxHeight: 400)
            
            if isLoading {
                ProgressView()
            }
            
            Button("Get Current Token Info") {
                getTokenInfo()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Test Backend Auth Check") {
                testBackendAuthCheck()
            }
            .buttonStyle(.bordered)
            
            Button("Test Token Refresh") {
                testTokenRefresh()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private func getTokenInfo() {
        isLoading = true
        tokenInfo = "Getting token info..."
        
        Task {
            guard let user = Auth.auth().currentUser else {
                tokenInfo = "❌ No user logged in"
                isLoading = false
                return
            }
            
            do {
                let tokenResult = try await user.getIDTokenResult(forcingRefresh: true)
                let token = tokenResult.token
                
                var info = "✅ Token Retrieved Successfully\n\n"
                info += "USER INFO:\n"
                info += "- UID: \(user.uid)\n"
                info += "- Email: \(user.email ?? "none")\n"
                info += "- Email Verified: \(user.isEmailVerified)\n\n"
                
                info += "TOKEN INFO:\n"
                info += "- Length: \(token.count) characters\n"
                info += "- Expiration: \(tokenResult.expirationDate)\n"
                info += "- Auth Time: \(tokenResult.authDate)\n\n"
                
                info += "TOKEN CLAIMS:\n"
                for (key, value) in tokenResult.claims {
                    info += "- \(key): \(value)\n"
                }
                
                info += "\n🔍 CRITICAL FOR BACKEND:\n"
                info += "- aud (audience): \(tokenResult.claims["aud"] ?? "MISSING")\n"
                info += "- iss (issuer): \(tokenResult.claims["iss"] ?? "MISSING")\n"
                
                info += "\n📋 FULL TOKEN (tap to copy):\n"
                info += token
                
                tokenInfo = info
                
                // Copy to clipboard
                #if canImport(UIKit)
                UIPasteboard.general.string = token
                #endif
            } catch {
                tokenInfo = "❌ Error getting token: \(error)"
            }
            
            isLoading = false
        }
    }
    
    func testBackendAuthCheck() {
        isLoading = true
        tokenInfo = "Testing backend auth check endpoint..."
        
        Task {
            do {
                // Get Firebase token
                guard let token = try? await Auth.auth().currentUser?.getIDToken(forcingRefresh: true) else {
                    tokenInfo = "❌ No auth token available"
                    isLoading = false
                    return
                }
                
                // Test against debug endpoint
                guard let url = URL(string: "\(AppConfig.apiBaseURL)/api/v1/debug/auth-check") else {
                    tokenInfo = "❌ Invalid URL configuration"
                    isLoading = false
                    return
                }
                var request = URLRequest(url: url)
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    let responseStr = String(data: data, encoding: .utf8) ?? "No response body"
                    
                    var info = "BACKEND AUTH CHECK RESULT:\n\n"
                    info += "Status Code: \(httpResponse.statusCode)\n"
                    info += "Response: \(responseStr)\n\n"
                    
                    if httpResponse.statusCode == 200 {
                        info += "✅ Authentication successful!\n"
                        info += "The backend accepted your token.\n"
                    } else if httpResponse.statusCode == 401 {
                        info += "❌ Authentication failed!\n"
                        info += "The backend rejected your token.\n"
                        info += "Check that the Firebase project IDs match.\n"
                    }
                    
                    tokenInfo = info
                }
            } catch {
                tokenInfo = "❌ Backend test error: \(error)"
            }
            isLoading = false
        }
    }
    
    private func testTokenRefresh() {
        isLoading = true
        tokenInfo = "Testing token refresh..."
        
        Task {
            do {
                guard let user = Auth.auth().currentUser else {
                    tokenInfo = "❌ No user logged in"
                    isLoading = false
                    return
                }
                
                var info = "🔄 TOKEN REFRESH TEST\n\n"
                
                // Get current token without forcing refresh
                let tokenResult1 = try await user.getIDTokenResult(forcingRefresh: false)
                info += "CURRENT TOKEN:\n"
                info += "- Expires: \(tokenResult1.expirationDate)\n"
                info += "- Time until expiration: \(tokenResult1.expirationDate.timeIntervalSinceNow) seconds\n"
                info += "- First 20 chars: \(tokenResult1.token.prefix(20))...\n\n"
                
                // Force refresh
                info += "FORCING REFRESH...\n"
                let tokenResult2 = try await user.getIDTokenResult(forcingRefresh: true)
                info += "NEW TOKEN:\n"
                info += "- Expires: \(tokenResult2.expirationDate)\n"
                info += "- Time until expiration: \(tokenResult2.expirationDate.timeIntervalSinceNow) seconds\n"
                info += "- First 20 chars: \(tokenResult2.token.prefix(20))...\n\n"
                
                // Compare
                if tokenResult1.token == tokenResult2.token {
                    info += "⚠️ TOKENS ARE IDENTICAL (Firebase returned cached token)\n"
                } else {
                    info += "✅ TOKENS ARE DIFFERENT (Refresh successful)\n"
                }
                
                info += "\nNOTE: Firebase may return the same token if it's still valid.\n"
                info += "Tokens expire after 1 hour from creation."
                
                tokenInfo = info
                
            } catch {
                tokenInfo = "❌ Error testing token refresh: \(error)"
            }
            
            isLoading = false
        }
    }
}

#Preview {
    TokenDebugView()
}
