import XCTest
import Combine
@testable import clarity_loop_frontend
import FirebaseAuth

// A mock implementation of AuthServiceProtocol for testing AuthViewModel.
fileprivate class MockAuthService: AuthServiceProtocol {
    
    var authStateContinuation: AsyncStream<User?>.Continuation!
    lazy var authState: AsyncStream<User?> = {
        AsyncStream { continuation in
            self.authStateContinuation = continuation
        }
    }()
    
    @Published var mockCurrentUser: User?
    
    var currentUser: User? {
        mockCurrentUser
    }
    
    var signOutShouldThrow = false

    func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO {
        fatalError("Not used for these tests")
    }
    
    func register(withEmail email: String, password: String, details: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        fatalError("Not used for these tests")
    }
    
    func signOut() throws {
        if signOutShouldThrow {
            throw APIError.unknown(NSError(domain: "test", code: -1, userInfo: nil))
        }
        mockCurrentUser = nil
        authStateContinuation.yield(nil)
    }
    
    func sendPasswordReset(to email: String) async throws {
        fatalError("Not used for these tests")
    }
    
    func getCurrentUserToken() async throws -> String {
        fatalError("Not used for these tests")
    }
    
    // A mock user class to satisfy the type constraint.
    class MockUser: User {
        let _uid: String
        
        init(uid: String) {
            self._uid = uid
            // This is a simplified init. In a real scenario, more properties might be needed.
            // We call super.init() which is required, though it might not be the designated initializer.
            // This approach is fragile and depends on Firebase's implementation details.
            super.init()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var uid: String {
            return _uid
        }
    }
}

@MainActor
final class AuthViewModelTests: XCTestCase {

    private var viewModel: AuthViewModel!
    private var mockAuthService: MockAuthService!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        viewModel = AuthViewModel(authService: mockAuthService)
        cancellables = []
    }

    override func tearDown() {
        viewModel = nil
        mockAuthService = nil
        cancellables = nil
        super.tearDown()
    }

    func testInitialState_WithNoUser_IsLoggedOut() {
        // Given
        mockAuthService.mockCurrentUser = nil
        
        // When
        let newViewModel = AuthViewModel(authService: mockAuthService)
        
        // Then
        XCTAssertFalse(newViewModel.isLoggedIn, "ViewModel should not be logged in when there is no current user.")
    }

    func testInitialState_WithCurrentUser_IsLoggedIn() {
        // Given
        mockAuthService.mockCurrentUser = MockAuthService.MockUser(uid: "test-user")
        
        // When
        let newViewModel = AuthViewModel(authService: mockAuthService)

        // Then
        XCTAssertTrue(newViewModel.isLoggedIn, "ViewModel should be logged in when a current user exists.")
    }

    func testAuthStateChanges_UserLogsIn() {
        // Given
        let expectation = XCTestExpectation(description: "isLoggedIn becomes true")
        viewModel.$isLoggedIn
            .dropFirst() // Ignore the initial value
            .sink { isLoggedIn in
                if isLoggedIn {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        mockAuthService.authStateContinuation.yield(MockAuthService.MockUser(uid: "new-user"))

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.isLoggedIn)
    }

    func testAuthStateChanges_UserLogsOut() {
        // Given
        mockAuthService.mockCurrentUser = MockAuthService.MockUser(uid: "test-user")
        let loggedInViewModel = AuthViewModel(authService: mockAuthService)
        XCTAssertTrue(loggedInViewModel.isLoggedIn)
        
        let expectation = XCTestExpectation(description: "isLoggedIn becomes false")
        loggedInViewModel.$isLoggedIn
            .dropFirst()
            .sink { isLoggedIn in
                if !isLoggedIn {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        mockAuthService.authStateContinuation.yield(nil)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(loggedInViewModel.isLoggedIn)
    }
    
    func testSignOut_CallsAuthService() {
        // When
        viewModel.signOut()
        
        // Then
        // The result of signOut is tested via the authState stream,
        // but we can also confirm the mock's state changes.
        XCTAssertNil(mockAuthService.currentUser)
    }
    
    func testSignOut_HandlesError() {
        // Given
        mockAuthService.signOutShouldThrow = true
        mockAuthService.mockCurrentUser = MockAuthService.MockUser(uid: "test-user")
        
        // When
        viewModel.signOut()
        
        // Then
        // The user should remain logged in if signout fails.
        XCTAssertTrue(viewModel.isLoggedIn)
    }
} 