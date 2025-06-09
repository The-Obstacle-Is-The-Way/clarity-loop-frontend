//
//  TokenManagementService.swift
//  clarity-loop-frontend
//
//  CRITICAL: This service ensures tokens are ALWAYS fresh
//

import Foundation
import FirebaseAuth

/// Central token management service that ensures tokens are always fresh
@MainActor
final class TokenManagementService: ObservableObject {
    static let shared = TokenManagementService()
    
    private var cachedToken: String?
    private var tokenExpirationDate: Date?
    private var tokenIssuedDate: Date?
    
    private init() {}
    
    /// Maximum token age before forcing refresh (30 minutes)
    private let maxTokenAge: TimeInterval = 1800 // 30 minutes
    
    /// Minimum time before expiration to refresh (5 minutes)
    private let minTimeBeforeExpiration: TimeInterval = 300 // 5 minutes
    
    /// Get a valid token, forcing refresh if needed
    func getValidToken() async throws -> String {
        print("🔐 TokenManagement: Checking token validity...")
        
        // Check if we need a new token
        if shouldRefreshToken() {
            print("⚠️ TokenManagement: Token needs refresh")
            return try await forceRefreshToken()
        }
        
        // Return cached token if still valid
        if let cachedToken = cachedToken {
            print("✅ TokenManagement: Using cached token (still fresh)")
            return cachedToken
        }
        
        // No cached token, get a new one
        print("🔄 TokenManagement: No cached token, fetching new one")
        return try await forceRefreshToken()
    }
    
    /// Check if token should be refreshed
    private func shouldRefreshToken() -> Bool {
        guard let expirationDate = tokenExpirationDate,
              let issuedDate = tokenIssuedDate else {
            return true // No token info, need refresh
        }
        
        let now = Date()
        let timeUntilExpiration = expirationDate.timeIntervalSince(now)
        let tokenAge = now.timeIntervalSince(issuedDate)
        
        print("⏱️ TokenManagement: Token age check:")
        print("   - Issued at: \(issuedDate)")
        print("   - Expires at: \(expirationDate)")
        print("   - Token age: \(tokenAge/60) minutes")
        print("   - Time until expiration: \(timeUntilExpiration/60) minutes")
        
        // Refresh if:
        // 1. Token is expired
        // 2. Token expires soon (< 5 minutes)
        // 3. Token is old (> 30 minutes)
        if timeUntilExpiration <= 0 {
            print("❌ TokenManagement: Token is EXPIRED")
            return true
        }
        
        if timeUntilExpiration < minTimeBeforeExpiration {
            print("⚠️ TokenManagement: Token expires in < 5 minutes")
            return true
        }
        
        if tokenAge > maxTokenAge {
            print("⚠️ TokenManagement: Token is > 30 minutes old")
            return true
        }
        
        return false
    }
    
    /// Force refresh the token
    private func forceRefreshToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            print("❌ TokenManagement: No authenticated user")
            throw APIError.notAuthenticated
        }
        
        print("🔄 TokenManagement: Forcing token refresh...")
        
        let tokenResult = try await user.getIDTokenResult(forcingRefresh: true)
        
        // Cache the new token
        cachedToken = tokenResult.token
        tokenExpirationDate = tokenResult.expirationDate
        tokenIssuedDate = tokenResult.issuedAtDate
        
        print("✅ TokenManagement: Token refreshed successfully")
        print("   - New expiration: \(tokenResult.expirationDate)")
        print("   - Token will be valid for: \(tokenResult.expirationDate.timeIntervalSinceNow/60) minutes")
        
        return tokenResult.token
    }
    
    /// Clear cached token (for logout)
    func clearCache() {
        cachedToken = nil
        tokenExpirationDate = nil
        tokenIssuedDate = nil
        print("🧹 TokenManagement: Token cache cleared")
    }
}

// MARK: - APIError Extension
extension APIError {
    static let notAuthenticated = APIError.unauthorized
}