//
//  EnvironmentKeys.swift
//  clarity-loop-frontend
//
//  Created by Claude on 5/10/2025.
//

import Foundation
import SwiftUI

// MARK: - Shared Token Provider

/// Shared token provider for default environment values
/// This ensures that even default/fallback environment values can authenticate
private let defaultTokenProvider: () async -> String? = {
    // Use TokenManager directly instead of TokenManagementService to avoid circular dependency
    let token = await TokenManager.shared.getAccessToken()
    if token != nil {
        print("✅ Default environment: Token obtained from TokenManager")
    } else {
        print("⚠️ Default environment: No token available")
    }
    return token
}

// MARK: - AuthService

/// The key for accessing the `AuthServiceProtocol` in the SwiftUI Environment.
struct AuthServiceKey: EnvironmentKey {
    typealias Value = AuthServiceProtocol
    static var defaultValue: AuthServiceProtocol {
        // AuthService is @MainActor isolated and must be created on the main actor.
        // It should be explicitly injected at the app's entry point.
        // This fatal error helps catch configuration issues during development.
        fatalError("AuthService must be explicitly injected into the environment as it is @MainActor-isolated. Inject it in your App struct using .environment(\\.authService, authServiceInstance)")
    }
}

/// The key for accessing the `AuthViewModel` in the SwiftUI Environment.
/// Note: This is kept for backwards compatibility, but the app uses the new iOS 17+ @Environment(Type.self) pattern
struct AuthViewModelKey: EnvironmentKey {
    typealias Value = AuthViewModel?
    static var defaultValue: AuthViewModel?
}

private struct APIClientKey: EnvironmentKey {
    typealias Value = APIClientProtocol
    static let defaultValue: APIClientProtocol = {
        guard let client = BackendAPIClient(
            baseURLString: AppConfig.apiBaseURL,
            tokenProvider: defaultTokenProvider
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
    static let defaultValue: HealthDataRepositoryProtocol = {
        guard let client = BackendAPIClient(
            baseURLString: AppConfig.apiBaseURL,
            tokenProvider: defaultTokenProvider
        ) else {
            fatalError("Failed to create default APIClient for HealthDataRepository")
        }
        return RemoteHealthDataRepository(apiClient: client)
    }()
}

private struct InsightsRepositoryKey: EnvironmentKey {
    typealias Value = InsightsRepositoryProtocol
    static let defaultValue: InsightsRepositoryProtocol = {
        guard let client = BackendAPIClient(
            baseURLString: AppConfig.apiBaseURL,
            tokenProvider: defaultTokenProvider
        ) else {
            fatalError("Failed to create default APIClient for InsightsRepository")
        }
        return RemoteInsightsRepository(apiClient: client)
    }()
}

private struct UserRepositoryKey: EnvironmentKey {
    typealias Value = UserRepositoryProtocol
    static let defaultValue: UserRepositoryProtocol = {
        guard let client = BackendAPIClient(
            baseURLString: AppConfig.apiBaseURL,
            tokenProvider: defaultTokenProvider
        ) else {
            fatalError("Failed to create default APIClient for UserRepository")
        }
        return RemoteUserRepository(apiClient: client)
    }()
}

private struct HealthKitServiceKey: EnvironmentKey {
    typealias Value = HealthKitServiceProtocol
    static let defaultValue: HealthKitServiceProtocol = {
        let defaultAPIClient: APIClientProtocol = {
            guard let client = BackendAPIClient(
                baseURLString: AppConfig.apiBaseURL,
                tokenProvider: defaultTokenProvider
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