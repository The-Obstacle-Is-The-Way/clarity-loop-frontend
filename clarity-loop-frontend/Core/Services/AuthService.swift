import Foundation
import Combine
#if canImport(UIKit) && DEBUG
import UIKit
#endif

// Import required protocols and types
// Note: These imports may need to be adjusted based on your project structure

/// Defines the contract for a service that manages user authentication.
/// This protocol allows for dependency injection and mocking for testing purposes.
@MainActor
protocol AuthServiceProtocol {
    /// An async stream that emits the current user whenever the auth state changes.
    var authState: AsyncStream<AuthUser?> { get }
    
    /// The currently authenticated user, if one exists.
    var currentUser: AuthUser? { get async }

    /// Signs in a user with the given email and password.
    func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO
    
    /// Registers a new user.
    func register(withEmail email: String, password: String, details: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO
    
    /// Signs out the current user.
    func signOut() async throws
    
    /// Sends a password reset email to the given email address.
    func sendPasswordReset(to email: String) async throws
    
    /// Retrieves a fresh JWT for the current user.
    func getCurrentUserToken() async throws -> String
}

/// Specific errors for authentication operations
enum AuthenticationError: LocalizedError {
    case emailAlreadyInUse
    case weakPassword
    case invalidEmail
    case userDisabled
    case networkError
    case configurationError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .emailAlreadyInUse:
            return "This email address is already registered. Please try signing in instead."
        case .weakPassword:
            return "Please choose a stronger password with at least 8 characters, including uppercase, lowercase, and numbers."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .userDisabled:
            return "This account has been disabled. Please contact support."
        case .networkError:
            return "Unable to connect to the server. Please check your internet connection and try again."
        case .configurationError:
            return "App configuration error. Please restart the app or contact support."
        case .unknown(let message):
            return "Registration failed: \(message)"
        }
    }
}

/// The concrete implementation of the authentication service using AWS Cognito.
@MainActor
final class AuthService: AuthServiceProtocol {
    
    // MARK: - Properties
    
    nonisolated(unsafe) private let apiClient: APIClientProtocol
    // REMOVED: Direct Cognito integration
    // private let cognitoAuth = CognitoAuthService()
    private var authStateTask: Task<Void, Never>?

    /// A continuation to drive the `authState` async stream.
    private var authStateContinuation: AsyncStream<AuthUser?>.Continuation?

    /// An async stream that emits the current user whenever the auth state changes.
    lazy var authState: AsyncStream<AuthUser?> = {
        AsyncStream { continuation in
            self.authStateContinuation = continuation
            
            // FIXED: No more Cognito auth state
            self.authStateTask = Task { [weak self] in
                // Auth state will be managed through backend tokens
                continuation.yield(nil) // Start with no user
            }
        }
    }()
    
    private var _currentUser: AuthUser?
    
    var currentUser: AuthUser? {
        get async {
            // Return cached user from last login
            return _currentUser
        }
    }

    // MARK: - Initializer
    
    nonisolated init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    // MARK: - Public Methods

    func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO {
        do {
            // FIXED: NO MORE DIRECT COGNITO! Only use backend API
            // _ = try await cognitoAuth.signIn(email: email, password: password)
            
            // Create backend login request with device info
            let deviceInfo = DeviceInfoHelper.generateDeviceInfo()
            let loginDTO = UserLoginRequestDTO(email: email, password: password, rememberMe: true, deviceInfo: deviceInfo)
            let response = try await apiClient.login(requestDTO: loginDTO)
            
            // Store tokens in TokenManager
            await TokenManager.shared.store(
                accessToken: response.tokens.accessToken,
                refreshToken: response.tokens.refreshToken,
                expiresIn: response.tokens.expiresIn
            )
            
            // Update auth state with the logged in user
            let user = response.user.authUser
            self._currentUser = user
            authStateContinuation?.yield(user)
            
            return response.user
        } catch {
            throw mapCognitoError(error)
        }
    }
    
    func register(withEmail email: String, password: String, details: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        do {
            // FIXED: Register only through backend
            // let fullName = "\(details.firstName) \(details.lastName)"
            // _ = try await cognitoAuth.signUp(email: email, password: password, fullName: fullName)
            
            // Register with our backend
            let response = try await apiClient.register(requestDTO: details)
            return response
        } catch {
            throw mapCognitoError(error)
        }
    }
    
    func signOut() async throws {
        // FIXED: Clear local auth state
        // try await cognitoAuth.signOut()
        
        // Clear tokens
        await TokenManager.shared.clear()
        
        // Clear user state
        self._currentUser = nil
        authStateContinuation?.yield(nil)
    }
    
    func sendPasswordReset(to email: String) async throws {
        // Cognito password reset is handled through the hosted UI
        // For now, we'll throw an error indicating this
        throw AuthenticationError.unknown("Password reset is available through the Cognito hosted UI")
    }
    
    func getCurrentUserToken() async throws -> String {
        print("🔍 AUTH: getCurrentUserToken() called")
        
        // FIXED: Get token from TokenManager instead of Cognito
        guard let token = await TokenManager.shared.getAccessToken() else {
            throw AuthenticationError.unknown("No valid access token")
        }
        
        print("✅ AUTH: Token retrieved successfully")
        print("   - Length: \(token.count) characters")
        print("   - Preview: \(String(token.prefix(50)))...")
        
        #if DEBUG
        // 1️⃣  Print the full JWT so we can copy from the console
        print("🧪 FULL_ID_TOKEN → \(token)")

        // 2️⃣  Copy to clipboard for CLI use
        #if canImport(UIKit)
        UIPasteboard.general.string = token
        print("📋 Token copied to clipboard")
        #endif
        #endif
        
        return token
    }
    
    // MARK: - Private Error Mapping
    
    private func mapCognitoError(_ error: Error) -> Error {
        // Map Cognito-specific errors to our AuthenticationError enum
        if error is URLError {
            return AuthenticationError.networkError
        }
        
        // Check for specific Cognito error messages
        let errorMessage = error.localizedDescription.lowercased()
        
        if errorMessage.contains("email") && errorMessage.contains("exist") {
            return AuthenticationError.emailAlreadyInUse
        } else if errorMessage.contains("password") {
            return AuthenticationError.weakPassword
        } else if errorMessage.contains("invalid") && errorMessage.contains("email") {
            return AuthenticationError.invalidEmail
        } else if errorMessage.contains("disabled") {
            return AuthenticationError.userDisabled
        } else if errorMessage.contains("network") {
            return AuthenticationError.networkError
        } else if errorMessage.contains("configuration") {
            return AuthenticationError.configurationError
        }
        
        return AuthenticationError.unknown(error.localizedDescription)
    }
    
    deinit {
        authStateTask?.cancel()
    }
}