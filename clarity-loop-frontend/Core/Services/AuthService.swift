import FirebaseAuth
import Foundation
#if canImport(UIKit) && DEBUG
import UIKit
#endif

/// Defines the contract for a service that manages user authentication.
/// This protocol allows for dependency injection and mocking for testing purposes.
protocol AuthServiceProtocol {
    /// An async stream that emits the current user whenever the auth state changes.
    var authState: AsyncStream<AuthUser?> { get }
    
    /// The currently authenticated user, if one exists.
    var currentUser: AuthUser? { get }

    /// Signs in a user with the given email and password.
    func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO
    
    /// Registers a new user.
    func register(withEmail email: String, password: String, details: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO
    
    /// Signs out the current user.
    func signOut() throws
    
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

/// The concrete implementation of the authentication service, using Firebase.
final class AuthService: AuthServiceProtocol {
    
    // MARK: - Properties
    
    private let apiClient: APIClientProtocol
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    /// A continuation to drive the `authState` async stream.
    private var authStateContinuation: AsyncStream<AuthUser?>.Continuation?

    /// An async stream that emits the current user whenever the auth state changes.
    lazy var authState: AsyncStream<AuthUser?> = {
        AsyncStream { continuation in
            self.authStateContinuation = continuation
            continuation.yield(Auth.auth().currentUser.map(AuthUser.init))
            
            // Store the handle to keep the listener active.
            self.authStateHandle = Auth.auth().addStateDidChangeListener { _, user in
                continuation.yield(user.map(AuthUser.init))
            }
        }
    }()
    
    var currentUser: AuthUser? {
        Auth.auth().currentUser.map(AuthUser.init)
    }

    // MARK: - Initializer
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    // MARK: - Public Methods

    func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            
            let loginDTO = UserLoginRequestDTO(email: email, password: password, rememberMe: true, deviceInfo: nil)
            let response = try await apiClient.login(requestDTO: loginDTO)
            
            return response.user
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    func register(withEmail email: String, password: String, details: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        do {
            // Step 1: Create Firebase user
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Step 2: Send email verification
            try await authResult.user.sendEmailVerification()
            
            // Step 3: Register with our backend
            let response = try await apiClient.register(requestDTO: details)
            return response
        } catch {
            // If Firebase registration failed, provide specific error
            throw mapFirebaseError(error)
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        // Here you would also clear any local user data / cache.
    }
    
    func sendPasswordReset(to email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw mapFirebaseError(error)
        }
    }
    
    func getCurrentUserToken() async throws -> String {
        print("🔍 AUTH: getCurrentUserToken() called")
        
        guard let user = Auth.auth().currentUser else {
            print("❌ AUTH: No current user found!")
            throw APIError.unauthorized
        }
        
        print("✅ AUTH: Current user exists - UID: \(user.uid)")
        print("📧 AUTH: User email: \(user.email ?? "no email")")
        print("✉️ AUTH: Email verified: \(user.isEmailVerified)")
        
        // Get token result for more debugging info
        do {
            // First check if current token is still valid
            let tokenResult = try await user.getIDTokenResult(forcingRefresh: false)
            
            // Check expiration
            let expirationDate = tokenResult.expirationDate
            let timeUntilExpiration = expirationDate.timeIntervalSinceNow
            
            print("🕐 AUTH: Token expiration check:")
            print("   - Expires at: \(expirationDate)")
            print("   - Time until expiration: \(timeUntilExpiration) seconds (\(timeUntilExpiration/60) minutes)")
            
            // CRITICAL FIX: More aggressive token refresh
            // Force refresh if:
            // 1. Token expires in less than 5 minutes OR
            // 2. Token is older than 30 minutes (half of Firebase's 1 hour)
            let tokenAge = Date().timeIntervalSince(tokenResult.issuedAtDate)
            let needsRefresh = timeUntilExpiration < 300 || tokenAge > 1800 // 5 mins or 30 mins old
            
            let finalTokenResult: AuthTokenResult
            if needsRefresh {
                print("⚠️ AUTH: Token expiring soon (or expired), forcing refresh...")
                finalTokenResult = try await user.getIDTokenResult(forcingRefresh: true)
                print("✅ AUTH: Token refreshed successfully")
            } else {
                print("✅ AUTH: Token still valid, using existing token")
                finalTokenResult = tokenResult
            }
            
            print("🔍 AUTH: Token claims:")
            print("   - aud: \(finalTokenResult.claims["aud"] ?? "missing")")
            print("   - iss: \(finalTokenResult.claims["iss"] ?? "missing")")
            print("   - exp: \(finalTokenResult.claims["exp"] ?? "missing")")
            print("   - auth_time: \(finalTokenResult.claims["auth_time"] ?? "missing")")
            
            let token = finalTokenResult.token
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
        } catch {
            print("❌ AUTH: Failed to get ID token: \(error)")
            throw error
        }
    }
    
    // MARK: - Private Error Mapping
    
    private func mapFirebaseError(_ error: Error) -> Error {
        guard let authError = error as? AuthErrorCode else {
            // Handle non-Firebase errors
            if error is URLError {
                return AuthenticationError.networkError
            }
            return AuthenticationError.unknown(error.localizedDescription)
        }
        
        switch authError.code {
        case .emailAlreadyInUse:
            return AuthenticationError.emailAlreadyInUse
        case .weakPassword:
            return AuthenticationError.weakPassword
        case .invalidEmail:
            return AuthenticationError.invalidEmail
        case .userDisabled:
            return AuthenticationError.userDisabled
        case .networkError:
            return AuthenticationError.networkError
        case .tooManyRequests:
            return AuthenticationError.unknown("Too many attempts. Please try again later.")
        case .userTokenExpired:
            return AuthenticationError.unknown("Session expired. Please sign in again.")
        case .invalidAPIKey:
            return AuthenticationError.configurationError
        case .appNotAuthorized:
            return AuthenticationError.configurationError
        default:
            return AuthenticationError.unknown("Authentication failed: \(authError.localizedDescription)")
        }
    }
} 
 
