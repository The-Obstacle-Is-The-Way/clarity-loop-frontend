import XCTest
import FirebaseAuth
@testable import clarity_loop_frontend

// A mock implementation of AuthServiceProtocol for testing purposes.
fileprivate class MockAuthService: AuthServiceProtocol {
    var authState: AsyncStream<FirebaseAuth.User?> { AsyncStream { $0.yield(nil) } }
    var currentUser: FirebaseAuth.User? { nil }

    var signInShouldSucceed = true
    var sendPasswordResetShouldSucceed = true

    func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO {
        if signInShouldSucceed {
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
    
    // Unused methods for this test case
    func register(withEmail email: String, password: String, details: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO { fatalError("Not implemented") }
    func signOut() throws { fatalError("Not implemented") }
    func getCurrentUserToken() async throws -> String { fatalError("Not implemented") }
}

@MainActor
final class LoginViewModelTests: XCTestCase {

    private var viewModel: LoginViewModel!
    private var mockAuthService: MockAuthService!

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        viewModel = LoginViewModel(authService: mockAuthService)
    }

    override func tearDown() {
        viewModel = nil
        mockAuthService = nil
        super.tearDown()
    }

    func testSignIn_WithEmptyCredentials_ShowsErrorMessage() {
        // Given
        viewModel.email = ""
        viewModel.password = ""
        
        // When
        viewModel.signIn()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Please enter both email and password.")
    }
    
    func testSignIn_Successful() async {
        // Given
        mockAuthService.signInShouldSucceed = true
        viewModel.email = "test@example.com"
        viewModel.password = "password"
        
        // When
        viewModel.signIn()
        
        // Then
        XCTAssertTrue(viewModel.isLoading)
        
        // Allow the async task to run
        await Task.yield()
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSignIn_Failure_ShowsErrorMessage() async {
        // Given
        mockAuthService.signInShouldSucceed = false
        viewModel.email = "test@example.com"
        viewModel.password = "wrongpassword"
        
        // When
        viewModel.signIn()
        
        // Then
        XCTAssertTrue(viewModel.isLoading)
        
        await Task.yield()
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, APIError.unauthorized.localizedDescription)
    }
    
    func testSendPasswordReset_WithEmptyEmail_ShowsErrorMessage() {
        // Given
        viewModel.email = ""
        
        // When
        viewModel.sendPasswordReset()
        
        // Then
        XCTAssertEqual(viewModel.errorMessage, "Please enter your email address to reset your password.")
    }
    
    func testSendPasswordReset_Successful() async {
        // Given
        mockAuthService.sendPasswordResetShouldSucceed = true
        viewModel.email = "test@example.com"
        
        // When
        viewModel.sendPasswordReset()
        
        await Task.yield()

        // Then
        XCTAssertEqual(viewModel.errorMessage, "Password reset email sent. Please check your inbox.")
    }
} 