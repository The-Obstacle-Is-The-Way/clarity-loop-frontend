import XCTest
@testable import clarity_loop_frontend

final class AuthServiceTests: XCTestCase {
    
    var authService: MockAuthService!
    
    override func setUpWithError() throws {
        authService = MockAuthService()
    }
    
    override func tearDownWithError() throws {
        authService = nil
    }
    
    func testSignInSuccess() async throws {
        // Given
        authService.shouldSucceed = true
        let email = "test@example.com"
        let password = "password123"
        
        // When
        let userSession = try await authService.signIn(withEmail: email, password: password)
        
        // Then
        XCTAssertEqual(userSession.email, email)
        XCTAssertEqual(userSession.firstName, "Test")
        XCTAssertEqual(userSession.lastName, "User")
        XCTAssertTrue(userSession.emailVerified)
        
        // Verify auth state updated
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.email, email)
        XCTAssertEqual(authService.currentUser?.uid, "signed-in-uid")
    }
    
    func testSignInFailure() async throws {
        // Given
        authService.shouldSucceed = false
        let email = "test@example.com"
        let password = "wrongpassword"
        
        // When/Then
        do {
            _ = try await authService.signIn(withEmail: email, password: password)
            XCTFail("Expected sign in to fail")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    func testRegisterSuccess() async throws {
        // Given
        authService.shouldSucceed = true
        let email = "newuser@example.com"
        let password = "password123"
        let details = UserRegistrationRequestDTO(
            email: email,
            password: password,
            firstName: "New",
            lastName: "User",
            phoneNumber: nil,
            termsAccepted: true,
            privacyPolicyAccepted: true
        )
        
        // When
        let response = try await authService.register(withEmail: email, password: password, details: details)
        
        // Then
        XCTAssertEqual(response.email, email)
        XCTAssertEqual(response.status, "pending_verification")
        XCTAssertTrue(response.verificationEmailSent)
    }
    
    func testSignOut() throws {
        // Given - user is signed in
        authService.mockCurrentUser = AuthUser(uid: "test-uid", email: "test@example.com")
        XCTAssertNotNil(authService.currentUser)
        
        // When
        try authService.signOut()
        
        // Then
        XCTAssertNil(authService.currentUser)
    }
    
    func testGetCurrentUserToken() async throws {
        // Given
        authService.shouldSucceed = true
        
        // When
        let token = try await authService.getCurrentUserToken()
        
        // Then
        XCTAssertEqual(token, "mock-jwt-token")
    }
    
    func testGetCurrentUserTokenFailure() async throws {
        // Given
        authService.shouldSucceed = false
        
        // When/Then
        do {
            _ = try await authService.getCurrentUserToken()
            XCTFail("Expected token retrieval to fail")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    func testAuthStateStream() async throws {
        // Given
        let expectedUser = AuthUser(uid: "test-uid", email: "test@example.com", isEmailVerified: true)
        authService.mockCurrentUser = expectedUser
        
        // When
        var receivedUser: AuthUser?
        for await user in authService.authState {
            receivedUser = user
            break // Just get the first emission
        }
        
        // Then
        XCTAssertEqual(receivedUser, expectedUser)
    }
} 