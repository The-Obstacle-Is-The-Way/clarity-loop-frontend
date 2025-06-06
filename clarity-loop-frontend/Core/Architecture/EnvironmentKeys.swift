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

// MARK: - Repository Protocols

private struct HealthDataRepositoryKey: EnvironmentKey {
    // For previews and testing, a default mock can be useful.
    // For production, a real implementation will be injected.
    static let defaultValue: HealthDataRepositoryProtocol = MockHealthDataRepository()
}

private struct InsightsRepositoryKey: EnvironmentKey {
    static let defaultValue: InsightsRepositoryProtocol = MockInsightsRepository()
}

private struct UserRepositoryKey: EnvironmentKey {
    static let defaultValue: UserRepositoryProtocol = MockUserRepository()
}

extension EnvironmentValues {
    var healthDataRepository: HealthDataRepositoryProtocol {
        get { self[HealthDataRepositoryKey.self] }
        set { self[HealthDataRepositoryKey.self] = newValue }
    }
    
    var insightsRepository: InsightsRepositoryProtocol {
        get { self[InsightsRepositoryKey.self] }
        set { self[InsightsRepositoryKey.self] = newValue }
    }
    
    var userRepository: UserRepositoryProtocol {
        get { self[UserRepositoryKey.self] }
        set { self[UserRepositoryKey.self] = newValue }
    }
}

#if DEBUG
// MARK: - Mock Implementations for Previews

class MockHealthDataRepository: HealthDataRepositoryProtocol {}
class MockInsightsRepository: InsightsRepositoryProtocol {}
class MockUserRepository: UserRepositoryProtocol {}
#endif

// NOTE: Add other service keys here as needed (e.g., for HealthKit, Networking, etc.) 
