import FirebaseAuth
import Foundation

/// Defines the contract for a service that manages user authentication.
/// This protocol allows for dependency injection and mocking for testing purposes.
protocol AuthServiceProtocol {
    /// An async stream that emits the current Firebase user whenever the auth state changes.
    var authState: AsyncStream<FirebaseAuth.User?> { get }
    
    /// The currently authenticated Firebase user, if one exists.
    var currentUser: FirebaseAuth.User? { get }

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


/// The concrete implementation of the authentication service, using Firebase.
final class AuthService: AuthServiceProtocol {
    
    // MARK: - Properties
    
    private let apiClient: APIClientProtocol
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    /// A continuation to drive the `authState` async stream.
    private var authStateContinuation: AsyncStream<FirebaseAuth.User?>.Continuation?

    /// An async stream that emits the current Firebase user whenever the auth state changes.
    lazy var authState: AsyncStream<FirebaseAuth.User?> = {
        AsyncStream { continuation in
            self.authStateContinuation = continuation
            continuation.yield(Auth.auth().currentUser)
            
            // Store the handle to keep the listener active.
            self.authStateHandle = Auth.auth().addStateDidChangeListener { _, user in
                continuation.yield(user)
            }
        }
    }()
    
    var currentUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }

    // MARK: - Initializer
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    // MARK: - Public Methods

    func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO {
        try await Auth.auth().signIn(withEmail: email, password: password)
        
        let loginDTO = UserLoginRequestDTO(email: email, password: password, rememberMe: true, deviceInfo: nil)
        let response = try await apiClient.login(requestDTO: loginDTO)
        
        // Here you would typically save the user profile to SwiftData
        // let user = User(from: response.user)
        // try persistence.save(user)
        
        return response.user
    }
    
    func register(withEmail email: String, password: String, details: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        try await authResult.user.sendEmailVerification()
        
        // After creating the user in Firebase, register them in our backend.
        let response = try await apiClient.register(requestDTO: details)
        return response
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        // Here you would also clear any local user data / cache.
    }
    
    func sendPasswordReset(to email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    func getCurrentUserToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw APIError.unauthorized
        }
        return try await user.getIDToken(forcingRefresh: false)
    }
} 
 