//
//  EnvironmentKeys.swift
//  clarity-loop-frontend
//
//  Created by Claude on 5/10/2025.
//

import Foundation
import SwiftUI

// MARK: - TypeAlias for Token Provider
typealias TokenProvider = () async -> String?

// MARK: - Modern Swift 6 Environment Pattern with @Entry

extension EnvironmentValues {
    /// AuthService using modern @Entry pattern - handles MainActor isolation automatically
    @Entry var authService: AuthServiceProtocol = {
        // Create default APIClient with token provider
        let tokenProvider: TokenProvider = {
            do {
                return try await TokenManagementService.shared.getValidToken()
            } catch {
                print("⚠️ Default environment failed to get token: \(error)")
                return nil
            }
        }
        
        guard let defaultAPIClient = APIClient(
            baseURLString: AppConfig.apiBaseURL,
            tokenProvider: tokenProvider
        ) else {
            fatalError("Failed to create default APIClient with baseURL: \(AppConfig.apiBaseURL)")
        }
        
        return AuthService(apiClient: defaultAPIClient)
    }()
    
    /// APIClient using modern @Entry pattern
    @Entry var apiClient: APIClientProtocol = {
        let tokenProvider: TokenProvider = {
            do {
                return try await TokenManagementService.shared.getValidToken()
            } catch {
                print("⚠️ Default APIClient failed to get token: \(error)")
                return nil
            }
        }
        
        guard let client = APIClient(
            baseURLString: AppConfig.apiBaseURL,
            tokenProvider: tokenProvider
        ) else {
            fatalError("Failed to create default APIClient")
        }
        return client
    }()
    
    /// HealthKitService using modern @Entry pattern
    @Entry var healthKitService: HealthKitServiceProtocol = HealthKitService()
    
    /// BiometricAuthService using modern @Entry pattern (no protocol - use concrete type)
    @Entry var biometricAuthService: BiometricAuthService = BiometricAuthService()
    
    /// TokenManagementService using modern @Entry pattern (no protocol - use concrete type)
    @Entry var tokenManagementService: TokenManagementService = TokenManagementService.shared
}

// MARK: - Legacy Support (if needed for migration)

/// Default token provider function - nonisolated for thread safety
private let defaultTokenProvider: TokenProvider = {
    TokenManagementService.shared.currentToken
}

// MARK: - AuthService

/// The key for accessing the `AuthServiceProtocol` in the SwiftUI Environment.
struct AuthServiceKey: EnvironmentKey {
    typealias Value = AuthServiceProtocol
    static var defaultValue: AuthServiceProtocol {
        // Create a default APIClient for the default AuthService
        let defaultAPIClient: APIClientProtocol = {
            guard let client = APIClient(
                baseURLString: AppConfig.apiBaseURL,
                tokenProvider: defaultTokenProvider
            ) else {
                fatalError("Failed to create default APIClient")
            }
            return client
        }()
        
        // Use a lazy initialization pattern that will be MainActor-isolated when accessed
        return AuthServiceWrapper(apiClient: defaultAPIClient)
    }
}

/// Wrapper to handle MainActor isolation for AuthService
private class AuthServiceWrapper: AuthServiceProtocol {
    private let apiClient: APIClientProtocol
    private lazy var _authService: AuthService = {
        Task { @MainActor in
            let service = AuthService(apiClient: apiClient)
            TokenManagementService.shared.configure(with: service)
            return service
        }
        // For now, create a basic auth service
        // This is a temporary workaround for the MainActor isolation issue
        return AuthService(apiClient: apiClient)
    }()
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    var authState: AsyncStream<AuthUser?> { _authService.authState }
    var currentUser: AuthUser? { 
        get async { await _authService.currentUser }
    }
    
    func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO {
        try await _authService.signIn(withEmail: email, password: password)
    }
    
    func register(withEmail email: String, password: String, details: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        try await _authService.register(withEmail: email, password: password, details: details)
    }
    
    func signOut() async throws {
        try await _authService.signOut()
    }
    
    func sendPasswordReset(to email: String) async throws {
        try await _authService.sendPasswordReset(to: email)
    }
    
    func getCurrentUserToken() async throws -> String {
        try await _authService.getCurrentUserToken()
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
        guard let client = APIClient(
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
        guard let client = APIClient(
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
        guard let client = APIClient(
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
        guard let client = APIClient(
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
            guard let client = APIClient(
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