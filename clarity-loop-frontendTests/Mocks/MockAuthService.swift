import Foundation
import Combine
@testable import clarity_loop_frontend

@MainActor
class MockAuthService: AuthServiceProtocol {
    var shouldSucceed = true
    var mockUserSession = UserSessionResponseDTO(
        userId: UUID(),
        firstName: "Test",
        lastName: "User",
        email: "test@example.com",
        role: "user",
        permissions: [],
        status: "active",
        mfaEnabled: false,
        emailVerified: true,
        createdAt: Date(),
        lastLogin: Date()
    )
    
    // Mock user state
    var mockCurrentUser: AuthUser? = AuthUser(uid: "test-uid", email: "test@example.com", isEmailVerified: true)
    
    // MARK: - AuthServiceProtocol Implementation
    
    var authState: AsyncStream<AuthUser?> {
        AsyncStream { continuation in
            continuation.yield(mockCurrentUser)
            continuation.finish()
        }
    }
    
    var currentUser: AuthUser? {
        mockCurrentUser
    }
    
    func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO {
        if shouldSucceed {
            mockCurrentUser = AuthUser(uid: "signed-in-uid", email: email, isEmailVerified: true)
            return mockUserSession
        } else {
            throw APIError.unauthorized
        }
    }
    
    func register(withEmail email: String, password: String, details: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        if shouldSucceed {
            return RegistrationResponseDTO(
                userId: UUID(),
                email: email,
                status: "pending_verification",
                verificationEmailSent: true,
                createdAt: Date()
            )
        } else {
            throw APIError.serverError(statusCode: 400, message: "Registration failed")
        }
    }
    
    func signOut() async throws {
        mockCurrentUser = nil
    }
    
    func sendPasswordReset(to email: String) async throws {
        if !shouldSucceed {
            throw APIError.serverError(statusCode: 400, message: "Password reset failed")
        }
    }
    
    func getCurrentUserToken() async throws -> String {
        if shouldSucceed {
            return "mock-jwt-token"
        } else {
            throw APIError.unauthorized
        }
    }
    
    func refreshToken(requestDTO: RefreshTokenRequestDTO) async throws -> TokenResponseDTO {
        if shouldSucceed {
            return TokenResponseDTO(
                accessToken: "mock-refreshed-access-token",
                refreshToken: "mock-refreshed-refresh-token",
                tokenType: "Bearer",
                expiresIn: 3600
            )
        } else {
            throw APIError.unauthorized
        }
    }
} 