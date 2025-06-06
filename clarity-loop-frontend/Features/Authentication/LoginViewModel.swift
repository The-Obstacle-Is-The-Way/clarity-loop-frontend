import SwiftUI

/// A view model that manages the state and logic for the login screen.
@MainActor
@Observable
final class LoginViewModel {
    // MARK: - Published Properties
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Private Properties
    private let authService: AuthServiceProtocol
    
    // MARK: - Initializer
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    // MARK: - Public Methods
    
    /// Attempts to sign in the user with the provided credentials.
    func signIn() {
        // Basic validation
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await authService.signIn(withEmail: email, password: password)
                // On success, the global AuthViewModel will automatically trigger navigation.
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    /// Sends a password reset email to the entered email address.
    func sendPasswordReset() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address to reset your password."
            return
        }
        
        Task {
            do {
                try await authService.sendPasswordReset(to: email)
                self.errorMessage = "Password reset email sent. Please check your inbox." // Use this for user feedback
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
} 
