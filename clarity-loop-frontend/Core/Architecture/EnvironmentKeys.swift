import SwiftUI

// MARK: - AuthService Environment Key

/// The key for accessing the `AuthServiceProtocol` in the SwiftUI Environment.
private struct AuthServiceKey: EnvironmentKey {
    /// The default value for the key. In a real app, this might be a mock service
    /// or a placeholder, but for simplicity, we can use the real implementation.
    /// The value will be replaced at the app's root.
    static let defaultValue: AuthServiceProtocol = AuthService(
        apiClient: APIClient(tokenProvider: {
            // This default token provider will not work for real calls,
            // but is sufficient for the DI setup. The real one is injected.
            return nil
        })
    )
}

extension EnvironmentValues {
    /// Provides access to the `AuthService` throughout the SwiftUI environment.
    var authService: AuthServiceProtocol {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}

// NOTE: Add other service keys here as needed (e.g., for HealthKit, Networking, etc.) 
