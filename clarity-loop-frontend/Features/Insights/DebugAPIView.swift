//
//  DebugAPIView.swift
//  clarity-loop-frontend
//
//  Debug view to test API connectivity
//

import SwiftUI
import FirebaseAuth
#if canImport(UIKit) && DEBUG
import UIKit
#endif

struct DebugAPIView: View {
    @State private var statusMessage = "Tap buttons to test API"
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("API Debug Test")
                .font(.title)
            
            Text(statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            if isLoading {
                ProgressView()
            }
            
            Button("Test Health Endpoint (No Auth)") {
                testHealthEndpoint()
            }
            .buttonStyle(.bordered)
            
            Button("Test Insights Status (No Auth)") {
                testInsightsStatus()
            }
            .buttonStyle(.bordered)
            
            Button("Test Generate Insight (Auth Required)") {
                testGenerateInsight()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Show Current Token") {
                showCurrentToken()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private func testHealthEndpoint() {
        isLoading = true
        statusMessage = "Testing health endpoint..."
        
        Task {
            do {
                let url = URL(string: "\(AppConfig.apiBaseURL)/api/v1/health-data/health")!
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    let json = try? JSONSerialization.jsonObject(with: data)
                    statusMessage = "Health endpoint: \(httpResponse.statusCode)\n\(String(describing: json))"
                }
            } catch {
                statusMessage = "Health endpoint error: \(error)"
            }
            isLoading = false
        }
    }
    
    private func testInsightsStatus() {
        isLoading = true
        statusMessage = "Testing insights status..."
        
        Task {
            do {
                let url = URL(string: "\(AppConfig.apiBaseURL)/api/v1/insights/status")!
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    let json = try? JSONSerialization.jsonObject(with: data)
                    statusMessage = "Insights status: \(httpResponse.statusCode)\n\(String(describing: json))"
                }
            } catch {
                statusMessage = "Insights status error: \(error)"
            }
            isLoading = false
        }
    }
    
    private func testGenerateInsight() {
        isLoading = true
        statusMessage = "Testing generate insight with auth..."
        
        Task {
            do {
                // Get Firebase token
                guard let token = try? await Auth.auth().currentUser?.getIDToken() else {
                    statusMessage = "No auth token available"
                    isLoading = false
                    return
                }
                
                #if DEBUG
                // 1️⃣  Print the full JWT so we can copy from the console
                print("FULL_ID_TOKEN → \(token)")

                // 2️⃣  Copy to clipboard for CLI use
                #if canImport(UIKit)
                UIPasteboard.general.string = token
                #endif

                print("✅ ID-token copied to clipboard (length: \(token.count))")
                #endif
                
                let url = URL(string: "\(AppConfig.apiBaseURL)/api/v1/insights/generate")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // Test payload
                let payload: [String: Any] = [
                    "analysis_results": ["test": "data"],
                    "context": "Test from iOS debug view",
                    "insight_type": "chat_response",
                    "include_recommendations": false,
                    "language": "en"
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    let responseStr = String(data: data, encoding: .utf8) ?? "No response body"
                    statusMessage = "Generate insight: \(httpResponse.statusCode)\n\(responseStr)"
                }
            } catch {
                statusMessage = "Generate insight error: \(error)"
            }
            isLoading = false
        }
    }
    
    private func showCurrentToken() {
        isLoading = true
        statusMessage = "Getting current token..."
        
        Task {
            if let token = try? await Auth.auth().currentUser?.getIDToken() {
                // Show first and last 10 chars for security
                let start = token.prefix(10)
                let end = token.suffix(10)
                statusMessage = "Token: \(start)...\(end)\nLength: \(token.count)"
                
                #if DEBUG
                // 1️⃣  Print the full JWT so we can copy from the console
                print("FULL_ID_TOKEN → \(token)")

                // 2️⃣  Copy to clipboard for CLI use
                #if canImport(UIKit)
                UIPasteboard.general.string = token
                #endif

                print("✅ ID-token copied to clipboard (length: \(token.count))")
                #endif
            } else {
                statusMessage = "No token available - user not logged in?"
            }
            isLoading = false
        }
    }
}

#Preview {
    DebugAPIView()
}