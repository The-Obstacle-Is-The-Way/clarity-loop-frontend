import FirebaseAuth
import Foundation

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
        guard let user = Auth.auth().currentUser else {
            throw APIError.unauthorized
        }
        return try await user.getIDToken(forcingRefresh: false)
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
 
