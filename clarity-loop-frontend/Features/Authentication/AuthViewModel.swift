import Combine
import Foundation
import Observation
import SwiftUI

/// Manages the global authentication state for the entire application.
///
/// This class acts as a single source of truth for whether a user is logged in.
/// It observes the `AuthService` and publishes the authentication status, allowing
/// the UI to reactively switch between login/main content views.
@MainActor
@Observable
final class AuthViewModel {
    
    // MARK: - Properties
    
    /// A boolean flag indicating if a user is currently authenticated.
    private(set) var isLoggedIn: Bool = false
    
    // MARK: - Private Properties
    
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
        setupSubscribers()
        
        // Initial check
        self.isLoggedIn = authService.currentUser != nil
    }
    
    // MARK: - Private Methods
    
    /// Sets up a subscriber to the `authState` stream from the `AuthService`.
    /// This ensures the `isLoggedIn` property is always in sync with the actual auth state.
    private func setupSubscribers() {
        Task { [weak self] in
            guard let self = self else { return }
            for await user in self.authService.authState {
                self.isLoggedIn = user != nil
            }
        }
    }
    
    /// A convenience method to sign out the user.
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            // Handle sign-out error, e.g., by logging it.
            print("Error signing out: \(error.localizedDescription)")
        }
    }
} 
