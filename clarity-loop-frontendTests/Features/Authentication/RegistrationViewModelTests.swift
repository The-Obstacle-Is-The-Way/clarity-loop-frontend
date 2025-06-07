import XCTest
import FirebaseAuth
@testable import clarity_loop_frontend

// A mock implementation of AuthServiceProtocol for testing RegistrationViewModel.
fileprivate class MockAuthService: AuthServiceProtocol {
    
    var registrationShouldSucceed = true
    var registrationError: APIError?
    
    // Unused properties for this test case
    var authState: AsyncStream<FirebaseAuth.User?> { AsyncStream { $0.yield(nil) } }
    var currentUser: FirebaseAuth.User? { nil }
    
    func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO {
        fatalError("Not implemented for these tests")
    }

    func register(withEmail email: String, password: String, details: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        if registrationShouldSucceed {
            return RegistrationResponseDTO(
                userId: UUID(),
                email: email,
                status: "pending_verification",
                verificationEmailSent: true,
                createdAt: Date()
            )
        } else {
            throw registrationError ?? APIError.unknown(NSError(domain: "test", code: 0, userInfo: nil))
        }
    }

    func signOut() throws {}
    func sendPasswordReset(to email: String) async throws {}
    func getCurrentUserToken() async throws -> String { "" }
}

@MainActor
final class RegistrationViewModelTests: XCTestCase {
    
    private var viewModel: RegistrationViewModel!
    private var mockAuthService: MockAuthService!

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        viewModel = RegistrationViewModel(authService: mockAuthService)
    }

    override func tearDown() {
        viewModel = nil
        mockAuthService = nil
        super.tearDown()
    }
    
    func testRegister_WithMismatchedPasswords_ShowsError() {
        // Given
        viewModel.password = "password123"
        viewModel.confirmPassword = "password456"
        
        // When
        viewModel.register()
        
        // Then
        XCTAssertEqual(viewModel.errorMessage, "Passwords do not match.")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testRegister_WithEmptyFields_ShowsError() {
        // Given
        viewModel.email = ""
        
        // When
        viewModel.register()
        
        // Then
        XCTAssertEqual(viewModel.errorMessage, "Please fill out all fields.")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testRegister_Successful() async {
        // Given
        mockAuthService.registrationShouldSucceed = true
        viewModel.firstName = "Test"
        viewModel.lastName = "User"
        viewModel.email = "test@example.com"
        viewModel.password = "password"
        viewModel.confirmPassword = "password"
        viewModel.termsAccepted = true
        viewModel.privacyPolicyAccepted = true
        
        // When
        viewModel.register()
        
        // Then
        XCTAssertTrue(viewModel.isLoading)
        await Task.yield() // Allow async operation to complete
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.registrationComplete)
    }
    
    func testRegister_Failure_ShowsErrorMessage() async {
        // Given
        mockAuthService.registrationShouldSucceed = false
        mockAuthService.registrationError = APIError.serverError(statusCode: 400, message: "Email already in use.")
        viewModel.firstName = "Test"
        viewModel.lastName = "User"
        viewModel.email = "test@example.com"
        viewModel.password = "password"
        viewModel.confirmPassword = "password"
        viewModel.termsAccepted = true
        viewModel.privacyPolicyAccepted = true
        
        // When
        viewModel.register()
        
        // Then
        XCTAssertTrue(viewModel.isLoading)
        await Task.yield()
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.registrationComplete)
        XCTAssertEqual(viewModel.errorMessage, "Server error 400: Email already in use.")
    }
    
    func testRegister_WithUnacceptedTerms_ShowsError() {
        // Given
        viewModel.firstName = "Test"
        viewModel.lastName = "User"
        viewModel.email = "test@example.com"
        viewModel.password = "password"
        viewModel.confirmPassword = "password"
        viewModel.termsAccepted = false
        
        // When
        viewModel.register()
        
        // Then
        XCTAssertEqual(viewModel.errorMessage, "You must accept the Terms of Service and Privacy Policy.")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testRegister_Success() async {
        // Given
        viewModel.email = "test@example.com"
        viewModel.password = "password"
        viewModel.firstName = "Test"
        viewModel.lastName = "User"
        
        // When
        await viewModel.register()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockAuthService.registerCallCount, 1)
    }
} 