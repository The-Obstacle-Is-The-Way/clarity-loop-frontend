import SwiftUI

// MARK: - AuthService

/// The key for accessing the `AuthServiceProtocol` in the SwiftUI Environment.
struct AuthServiceKey: EnvironmentKey {
    typealias Value = AuthServiceProtocol
    static var defaultValue: AuthServiceProtocol {
        // Create a default APIClient for the default AuthService
        let defaultAPIClient: APIClientProtocol = {
            guard let client = APIClient(
                baseURLString: "https://crave-trinity--clarity-backend-fastapi-app.modal.run",
                tokenProvider: { nil }
            ) else {
                fatalError("Failed to create default APIClient")
            }
            return client
        }()
        
        return AuthService(apiClient: defaultAPIClient)
    }
}

/// The key for accessing the `AuthViewModel` in the SwiftUI Environment.
/// Note: This is kept for backwards compatibility, but the app uses the new iOS 17+ @Environment(Type.self) pattern
struct AuthViewModelKey: EnvironmentKey {
    typealias Value = AuthViewModel?
    static var defaultValue: AuthViewModel? = nil
}

private struct APIClientKey: EnvironmentKey {
    typealias Value = APIClientProtocol
    static let defaultValue: APIClientProtocol = {
        guard let client = APIClient(
            baseURLString: "https://crave-trinity--clarity-backend-fastapi-app.modal.run",
            tokenProvider: { nil }
        ) else {
            fatalError("Failed to create default APIClient")
        }
        return client
    }()
}

// MARK: - Repository Protocols

private struct HealthDataRepositoryKey: EnvironmentKey {
    typealias Value = HealthDataRepositoryProtocol
    // Use real implementation since mocks are maintained in test target only
    static let defaultValue: HealthDataRepositoryProtocol = RemoteHealthDataRepository(
        apiClient: APIClient(baseURLString: "https://crave-trinity--clarity-backend-fastapi-app.modal.run", tokenProvider: { nil })!
    )
}

private struct InsightsRepositoryKey: EnvironmentKey {
    typealias Value = InsightsRepositoryProtocol
    static let defaultValue: InsightsRepositoryProtocol = RemoteInsightsRepository(
        apiClient: APIClient(baseURLString: "https://crave-trinity--clarity-backend-fastapi-app.modal.run", tokenProvider: { nil })!
    )
}

private struct UserRepositoryKey: EnvironmentKey {
    typealias Value = UserRepositoryProtocol
    static let defaultValue: UserRepositoryProtocol = RemoteUserRepository(
        apiClient: APIClient(baseURLString: "https://crave-trinity--clarity-backend-fastapi-app.modal.run", tokenProvider: { nil })!
    )
}

private struct HealthKitServiceKey: EnvironmentKey {
    typealias Value = HealthKitServiceProtocol
    static let defaultValue: HealthKitServiceProtocol = {
        let defaultAPIClient: APIClientProtocol = {
            guard let client = APIClient(
                baseURLString: "https://crave-trinity--clarity-backend-fastapi-app.modal.run",
                tokenProvider: { nil }
            ) else {
                fatalError("Failed to create default APIClient for HealthKitService")
            }
            return client
        }()
        
        return HealthKitService(apiClient: defaultAPIClient)
    }()
}

// Security services will be added later when protocols are defined

extension EnvironmentValues {
    /// Provides access to the `AuthService` throughout the SwiftUI environment.
    var authService: AuthServiceProtocol {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
    
    /// Provides access to the `AuthViewModel` throughout the SwiftUI environment.
    var authViewModel: AuthViewModel? {
        get { self[AuthViewModelKey.self] }
        set { self[AuthViewModelKey.self] = newValue }
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

// Default values are provided above for each environment key
// These will be used in previews and when services aren't explicitly injected

// NOTE: Add other service keys here as needed (e.g., for HealthKit, Networking, etc.) 
