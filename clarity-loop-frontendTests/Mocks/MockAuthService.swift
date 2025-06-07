import Foundation
import Combine

// Simple mock without importing the main module first
class MockAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: String?
    @Published var authError: String?
    
    var shouldSucceed = true
    
    func signIn(email: String, password: String) async throws {
        if shouldSucceed {
            currentUser = "test@example.com"
            isAuthenticated = true
        } else {
            throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        if shouldSucceed {
            currentUser = email
            isAuthenticated = true
        } else {
            throw NSError(domain: "AuthError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Email already in use"])
        }
    }
    
    func signOut() async throws {
        currentUser = nil
        isAuthenticated = false
    }
} 