import XCTest
import FirebaseAuth
@testable import clarity_loop_frontend



@MainActor
final class LoginViewModelTests: XCTestCase {

    var viewModel: LoginViewModel!
    var mockAuthService: MockAuthService!

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

    func testLogin_Success() async {
        // Given
        viewModel.email = "test@example.com"
        viewModel.password = "password"
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockAuthService.signInCallCount, 1)
    }
    
    func testLogin_Failure_EmptyFields() async {
        // Given
        // email and password are empty by default
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(mockAuthService.signInCallCount, 0)
    }
    
    func testLogin_Failure_ApiError() async {
        // Given
        viewModel.email = "fail@example.com"
        viewModel.password = "password"
        mockAuthService.shouldThrowError = true
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(mockAuthService.signInCallCount, 1)
    }

    func testLogin_WithEmptyCredentials_ShowsErrorMessage() async {
        // Given
        viewModel.email = ""
        viewModel.password = ""
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testLogin_Successful() async {
        // Given
        mockAuthService.signInShouldSucceed = true
        viewModel.email = "test@example.com"
        viewModel.password = "password"
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLogin_Failure_ShowsErrorMessage() async {
        // Given
        mockAuthService.signInShouldSucceed = false
        viewModel.email = "test@example.com"
        viewModel.password = "wrongpassword"
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testRequestPasswordReset_WithEmptyEmail_ShowsErrorMessage() async {
        // Given
        viewModel.email = ""
        
        // When
        await viewModel.requestPasswordReset()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testRequestPasswordReset_Successful() async {
        // Given
        mockAuthService.sendPasswordResetShouldSucceed = true
        viewModel.email = "test@example.com"
        
        // When
        await viewModel.requestPasswordReset()

        // Then
        XCTAssertNil(viewModel.errorMessage)
    }
} 