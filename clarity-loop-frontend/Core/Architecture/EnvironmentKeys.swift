import SwiftUI

// MARK: - AuthService

/// The key for accessing the `AuthServiceProtocol` in the SwiftUI Environment.
struct AuthServiceKey: EnvironmentKey {
    static var defaultValue: AuthServiceProtocol {
        // Provide a safe mock for previews and testing
        #if DEBUG
        return MockAuthService()
        #else
        fatalError("AuthService not found. Did you forget to inject it?")
        #endif
    }
}

private struct APIClientKey: EnvironmentKey {
    static let defaultValue: APIClientProtocol = {
        guard let client = APIClient(tokenProvider: { nil }) else {
            fatalError("Failed to create default APIClient")
        }
        return client
    }()
}

// MARK: - Repository Protocols

private struct HealthDataRepositoryKey: EnvironmentKey {
    // Use real implementation since mocks are maintained in test target only
    static let defaultValue: HealthDataRepositoryProtocol = RemoteHealthDataRepository(
        apiClient: APIClient(baseURLString: "https://api.example.com", tokenProvider: { nil })!
    )
}

private struct InsightsRepositoryKey: EnvironmentKey {
    static let defaultValue: InsightsRepositoryProtocol = RemoteInsightsRepository(
        apiClient: APIClient(baseURLString: "https://api.example.com", tokenProvider: { nil })!
    )
}

private struct UserRepositoryKey: EnvironmentKey {
    static let defaultValue: UserRepositoryProtocol = RemoteUserRepository(
        apiClient: APIClient(baseURLString: "https://api.example.com", tokenProvider: { nil })!
    )
}

private struct HealthKitServiceKey: EnvironmentKey {
    static let defaultValue: HealthKitServiceProtocol = HealthKitService()
}

// Security services will be added later when protocols are defined

extension EnvironmentValues {
    /// Provides access to the `AuthService` throughout the SwiftUI environment.
    var authService: AuthServiceProtocol {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
    
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
    
    var healthKitService: HealthKitServiceProtocol {
        get { self[HealthKitServiceKey.self] }
        set { self[HealthKitServiceKey.self] = newValue }
    }
    
    var apiClient: APIClientProtocol {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}

#if DEBUG
// MARK: - Mock Implementations for Previews

// For debug builds, use real implementations for previews to avoid maintaining dual mock sets
private extension PreviewAPIClientKey {
    static let previewValue = APIClient()
}

private extension PreviewHealthKitServiceKey {
    static let previewValue = HealthKitService()
}

private extension PreviewAuthServiceKey {
    static let previewValue = AuthService(apiClient: APIClient())
}

// Mock implementations removed from main target to avoid maintenance burden
// Use real implementations for previews in debug builds
// Test-specific mocks are maintained in the test target
#endif

// NOTE: Add other service keys here as needed (e.g., for HealthKit, Networking, etc.) 
