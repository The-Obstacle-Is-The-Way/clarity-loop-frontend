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
    func register() {
        guard validateInputs() else { return }
        
        isLoading = true
        errorMessage = nil
        
        let registrationDTO = UserRegistrationRequestDTO(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: nil, // Add to form if needed
            termsAccepted: termsAccepted,
            privacyPolicyAccepted: privacyPolicyAccepted
        )
        
        Task {
            do {
                _ = try await authService.register(
                    withEmail: email,
                    password: password,
                    details: registrationDTO
                )
                self.isLoading = false
                self.registrationComplete = true
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
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
} 