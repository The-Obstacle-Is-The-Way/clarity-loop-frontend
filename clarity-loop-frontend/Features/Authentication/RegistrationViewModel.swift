import Foundation
import SwiftUI

/// A view model that manages the state and logic for the user registration screen.
@MainActor
@Observable
final class RegistrationViewModel {
    // MARK: - Published Properties
    var email = ""
    var password = ""
    var confirmPassword = ""
    var firstName = ""
    var lastName = ""
    
    var termsAccepted = false
    var privacyPolicyAccepted = false
    
    var isLoading = false
    var errorMessage: String?
    var registrationComplete = false

    // MARK: - Private Properties
    private let authService: AuthServiceProtocol
    
    // MARK: - Initializer
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    // MARK: - Public Methods
    
    /// Attempts to register a new user with the provided details.
    @MainActor
    func register() async {
        isLoading = true
        errorMessage = nil
        
        // Validate inputs first
        guard validateInputs() else {
            isLoading = false
            return
        }
        
        let details = UserRegistrationRequestDTO(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: nil,
            termsAccepted: termsAccepted,
            privacyPolicyAccepted: privacyPolicyAccepted
        )
        
        do {
            _ = try await authService.register(withEmail: email, password: password, details: details)
            registrationComplete = true
            errorMessage = "Registration successful! Please check your email for verification."
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Private Validation
    
    private func validateInputs() -> Bool {
        guard !email.isEmpty, !password.isEmpty, !firstName.isEmpty, !lastName.isEmpty else {
            errorMessage = "All fields are required."
            return false
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return false
        }
        
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return false
        }
        
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters long."
            return false
        }
        
        guard termsAccepted && privacyPolicyAccepted else {
            errorMessage = "You must accept the Terms of Service and Privacy Policy."
            return false
        }
        
        // Add more robust email/password validation as needed
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
} 
