import Foundation
import FirebaseAuth
@testable import clarity_loop_frontend

/// Centralized mock auth service for all tests
/// Eliminates duplicate MockAuthService classes across test files
class MockAuthService: AuthServiceProtocol {
    
    // MARK: - Mock Control Properties
    var signInShouldSucceed = true
    var sendPasswordResetShouldSucceed = true
    var shouldThrowError = false
    var signInCallCount = 0
    
    // MARK: - AuthServiceProtocol Implementation
    var authState: AsyncStream<FirebaseAuth.User?> { 
        AsyncStream { $0.yield(nil) } 
    }
    
    var currentUser: FirebaseAuth.User? { 
        nil 
    }

    func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO {
        signInCallCount += 1
        
        if signInShouldSucceed && !shouldThrowError {
            return UserSessionResponseDTO(
                userId: UUID(),
                firstName: "Test",
                lastName: "User",
                email: email,
                role: "user",
                permissions: [],
                status: "active",
                mfaEnabled: false,
                emailVerified: true,
                createdAt: Date(),
                lastLogin: nil
            )
        } else {
            throw APIError.unauthorized
        }
    }

    func sendPasswordReset(to email: String) async throws {
        if !sendPasswordResetShouldSucceed {
            throw APIError.unknown(NSError(domain: "test", code: 0, userInfo: nil))
        }
    }
    
    // MARK: - Unused methods for basic tests
    func register(withEmail email: String, password: String, details: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO { 
        throw APIError.notImplemented
    }
    
    func signOut() throws { 
        throw APIError.notImplemented
    }
    
    func getCurrentUserToken() async throws -> String { 
        throw APIError.notImplemented
    }
} 