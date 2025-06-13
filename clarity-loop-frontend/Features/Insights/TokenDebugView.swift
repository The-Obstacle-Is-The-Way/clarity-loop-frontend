//
//  TokenDebugView.swift
//  clarity-loop-frontend
//
//  Debug view to test token extraction and validation
//

import SwiftUI

struct TokenDebugView: View {
    @Environment(\.authService) private var authService
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
            guard let user = await authService.currentUser else {
                tokenInfo = "❌ No user logged in"
                isLoading = false
                return
            }
            
            do {
                let token = try await authService.getCurrentUserToken()
                
                var info = "✅ Token Retrieved Successfully\n\n"
                info += "USER INFO:\n"
                info += "- UID: \(user.id)\n"
                info += "- Email: \(user.email)\n\n"
                
                info += "TOKEN INFO:\n"
                info += "- Length: \(token.count) characters\n\n"
                
                // Note: Token details like expiration and claims are not available
                // through AuthService. The token is a JWT that can be decoded
                // on the backend to extract this information.
                info += "Note: Token expiration and claims are embedded in the JWT\n"
                info += "and can be decoded on the backend.\n\n"
                
                info += "📋 FULL TOKEN (tap to copy):\n"
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
                // Get auth token
                guard let token = try? await authService.getCurrentUserToken() else {
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
                guard await authService.currentUser != nil else {
                    tokenInfo = "❌ No user logged in"
                    isLoading = false
                    return
                }
                
                var info = "🔄 TOKEN REFRESH TEST\n\n"
                
                // Get current token
                let token1 = try await authService.getCurrentUserToken()
                info += "CURRENT TOKEN:\n"
                info += "- First 20 chars: \(token1.prefix(20))...\n\n"
                
                // Wait a moment
                info += "Waiting 2 seconds...\n"
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
                // Get token again (may trigger refresh if needed)
                let token2 = try await authService.getCurrentUserToken()
                info += "NEW TOKEN:\n"
                info += "- First 20 chars: \(token2.prefix(20))...\n\n"
                
                // Compare
                if token1 == token2 {
                    info += "⚠️ TOKENS ARE IDENTICAL (Token still valid)\n"
                } else {
                    info += "✅ TOKENS ARE DIFFERENT (Refresh occurred)\n"
                }
                
                info += "\nNOTE: AuthService manages token refresh automatically.\n"
                info += "Tokens are refreshed when needed."
                
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
