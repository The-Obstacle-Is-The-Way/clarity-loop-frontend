import XCTest
@testable import clarity_loop_frontend

/// Comprehensive contract validation tests to ensure frontend-backend alignment
/// These tests validate that all DTOs, request/response formats, and API contracts
/// match the backend expectations exactly
@MainActor
final class BackendContractValidationTests: XCTestCase {
    
    private var adapter: BackendContractAdapter!
    private var encoder: JSONEncoder!
    private var decoder: JSONDecoder!
    
    override func setUp() {
        super.setUp()
        adapter = BackendContractAdapter()
        
        // Configure encoder to match backend expectations
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        
        // Configure decoder to match backend responses
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - Registration Contract Tests
    
    func testRegistrationRequestContract() throws {
        // Given - Frontend registration request
        let frontendRequest = UserRegistrationRequestDTO(
            email: "test@clarity.health",
            password: "SecurePass123!",
            firstName: "John",
            lastName: "Doe",
            phoneNumber: "+1234567890",
            termsAccepted: true,
            privacyPolicyAccepted: true
        )
        
        // When - Convert to backend format
        let backendRequest = adapter.adaptRegistrationRequest(frontendRequest)
        let jsonData = try encoder.encode(backendRequest)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        
        // Then - Verify exact backend contract
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["email"] as? String, "test@clarity.health")
        XCTAssertEqual(json?["password"] as? String, "SecurePass123!")
        XCTAssertEqual(json?["display_name"] as? String, "John Doe")
        
        // Verify only expected fields are present
        XCTAssertEqual(json?.keys.count, 3, "Backend expects exactly 3 fields")
        XCTAssertTrue(json?.keys.contains("email") ?? false)
        XCTAssertTrue(json?.keys.contains("password") ?? false)
        XCTAssertTrue(json?.keys.contains("display_name") ?? false)
    }
    
    func testRegistrationResponseContract() throws {
        // Given - Backend registration response
        let backendJSON = """
        {
            "user_id": "123e4567-e89b-12d3-a456-426614174000",
            "email": "test@clarity.health",
            "status": "registered",
            "verification_email_sent": true,
            "created_at": "2025-01-13T10:00:00Z"
        }
        """
        
        // When - Decode and adapt to frontend
        let backendResponse = try decoder.decode(BackendRegistrationResponse.self, from: backendJSON.data(using: .utf8)!)
        let frontendResponse = adapter.adaptRegistrationResponse(backendResponse)
        
        // Then - Verify frontend DTO populated correctly
        XCTAssertEqual(frontendResponse.userId.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174000")
        XCTAssertEqual(frontendResponse.email, "test@clarity.health")
        XCTAssertEqual(frontendResponse.status, "registered")
        XCTAssertTrue(frontendResponse.verificationEmailSent)
        XCTAssertNotNil(frontendResponse.createdAt)
    }
    
    // MARK: - Login Contract Tests
    
    func testLoginRequestContract() throws {
        // Given - Frontend login request
        let frontendRequest = UserLoginRequestDTO(
            email: "test@clarity.health",
            password: "SecurePass123!",
            rememberMe: true,
            deviceInfo: [
                "device_id": AnyCodable("iPhone-123"),
                "os_version": AnyCodable("iOS 18.0"),
                "app_version": AnyCodable("1.0.0")
            ]
        )
        
        // When - Convert to backend format
        let backendRequest = adapter.adaptLoginRequest(frontendRequest)
        let jsonData = try encoder.encode(backendRequest)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        
        // Then - Verify exact backend contract
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["email"] as? String, "test@clarity.health")
        XCTAssertEqual(json?["password"] as? String, "SecurePass123!")
        XCTAssertEqual(json?["remember_me"] as? Bool, true)
        
        // Verify device_info structure
        let deviceInfo = json?["device_info"] as? [String: Any]
        XCTAssertNotNil(deviceInfo)
        XCTAssertEqual(deviceInfo?["device_id"] as? String, "iPhone-123")
        XCTAssertEqual(deviceInfo?["os_version"] as? String, "iOS 18.0")
        XCTAssertEqual(deviceInfo?["app_version"] as? String, "1.0.0")
    }
    
    func testLoginResponseContract() throws {
        // Given - Backend login response
        let backendJSON = """
        {
            "user": {
                "user_id": "123e4567-e89b-12d3-a456-426614174000",
                "display_name": "John Doe",
                "email": "test@clarity.health",
                "role": "patient",
                "permissions": ["read_own_data", "write_own_data"],
                "status": "active",
                "mfa_enabled": false,
                "email_verified": true,
                "created_at": "2025-01-01T10:00:00Z",
                "last_login": "2025-01-13T10:00:00Z"
            },
            "tokens": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "refresh_token": "refresh_token_value",
                "token_type": "Bearer",
                "expires_in": 3600
            }
        }
        """
        
        // When - Decode and adapt to frontend
        let backendResponse = try decoder.decode(BackendLoginResponse.self, from: backendJSON.data(using: .utf8)!)
        let frontendResponse = adapter.adaptLoginResponse(backendResponse)
        
        // Then - Verify frontend DTO populated correctly
        XCTAssertEqual(frontendResponse.user.email, "test@clarity.health")
        XCTAssertEqual(frontendResponse.user.firstName, "John")
        XCTAssertEqual(frontendResponse.user.lastName, "Doe")
        XCTAssertEqual(frontendResponse.user.role, "patient")
        XCTAssertEqual(frontendResponse.user.permissions, ["read_own_data", "write_own_data"])
        XCTAssertTrue(frontendResponse.user.emailVerified)
        
        XCTAssertEqual(frontendResponse.tokens.accessToken, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
        XCTAssertEqual(frontendResponse.tokens.tokenType, "Bearer")
        XCTAssertEqual(frontendResponse.tokens.expiresIn, 3600)
    }
    
    // MARK: - Error Response Contract Tests
    
    func testErrorResponseContract() throws {
        // Given - Backend error responses
        let validationErrorJSON = """
        {
            "error": "Validation Error",
            "details": {
                "email": ["Invalid email format"],
                "password": ["Password must be at least 8 characters"]
            },
            "status_code": 422
        }
        """
        
        let authErrorJSON = """
        {
            "error": "Authentication failed",
            "message": "Invalid credentials",
            "status_code": 401
        }
        """
        
        // When - Decode error responses
        let validationError = try decoder.decode(BackendErrorResponse.self, from: validationErrorJSON.data(using: .utf8)!)
        let authError = try decoder.decode(BackendErrorResponse.self, from: authErrorJSON.data(using: .utf8)!)
        
        // Then - Verify error structure
        XCTAssertEqual(validationError.error, "Validation Error")
        XCTAssertEqual(validationError.statusCode, 422)
        XCTAssertNotNil(validationError.details)
        
        XCTAssertEqual(authError.error, "Authentication failed")
        XCTAssertEqual(authError.message, "Invalid credentials")
        XCTAssertEqual(authError.statusCode, 401)
    }
    
    // MARK: - Snake Case Conversion Tests
    
    func testSnakeCaseEncoding() throws {
        // Test that all DTOs properly convert to snake_case
        struct TestDTO: Codable {
            let firstName: String
            let lastName: String
            let emailVerified: Bool
            let createdAt: Date
            let mfaEnabled: Bool
        }
        
        let dto = TestDTO(
            firstName: "John",
            lastName: "Doe",
            emailVerified: true,
            createdAt: Date(),
            mfaEnabled: false
        )
        
        let jsonData = try encoder.encode(dto)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        
        // Verify all keys are snake_case
        XCTAssertNotNil(json?["first_name"])
        XCTAssertNotNil(json?["last_name"])
        XCTAssertNotNil(json?["email_verified"])
        XCTAssertNotNil(json?["created_at"])
        XCTAssertNotNil(json?["mfa_enabled"])
        
        // Verify camelCase keys don't exist
        XCTAssertNil(json?["firstName"])
        XCTAssertNil(json?["emailVerified"])
        XCTAssertNil(json?["mfaEnabled"])
    }
    
    // MARK: - Date Format Tests
    
    func testISO8601DateFormatting() throws {
        // Given
        let dateString = "2025-01-13T10:30:45Z"
        let date = ISO8601DateFormatter().date(from: dateString)!
        
        struct DateTestDTO: Codable {
            let createdAt: Date
        }
        
        let dto = DateTestDTO(createdAt: date)
        
        // When
        let jsonData = try encoder.encode(dto)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Then - Verify ISO8601 format with 'Z' suffix
        XCTAssertTrue(jsonString.contains("2025-01-13T10:30:45Z"))
        XCTAssertTrue(jsonString.contains("created_at")) // Also verify snake_case
    }
    
    // MARK: - Content Type Tests
    
    func testContentTypeHeaders() {
        // Verify all endpoints use correct content types
        let endpoints: [any Endpoint] = [
            AuthEndpoint.register(UserRegistrationRequestDTO(
                email: "test@test.com",
                password: "pass",
                firstName: "Test",
                lastName: "User",
                phoneNumber: nil,
                termsAccepted: true,
                privacyPolicyAccepted: true
            )),
            AuthEndpoint.login(UserLoginRequestDTO(
                email: "test@test.com",
                password: "pass",
                rememberMe: true,
                deviceInfo: nil
            ))
        ]
        
        for endpoint in endpoints {
            let headers = endpoint.headers
            XCTAssertEqual(headers["Content-Type"], "application/json", "All endpoints must use application/json")
        }
    }
    
    // MARK: - Null vs Undefined Tests
    
    func testNullVsUndefinedHandling() throws {
        // Test that optional fields are properly handled
        let request = UserLoginRequestDTO(
            email: "test@test.com",
            password: "password",
            rememberMe: false,
            deviceInfo: nil // This should be omitted, not sent as null
        )
        
        let backendRequest = adapter.adaptLoginRequest(request)
        let jsonData = try encoder.encode(backendRequest)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Verify deviceInfo is omitted when nil, not sent as null
        XCTAssertFalse(jsonString.contains("\"device_info\" : null"))
        XCTAssertFalse(jsonString.contains("\"device_info\":null"))
    }
}

// MARK: - Backend Response DTOs for Testing

private struct BackendRegistrationResponse: Codable {
    let userId: String
    let email: String
    let status: String
    let verificationEmailSent: Bool
    let createdAt: String
}

private struct BackendLoginResponse: Codable {
    let user: BackendUserSession
    let tokens: BackendTokens
}

private struct BackendUserSession: Codable {
    let userId: String
    let displayName: String
    let email: String
    let role: String
    let permissions: [String]
    let status: String
    let mfaEnabled: Bool
    let emailVerified: Bool
    let createdAt: String
    let lastLogin: String
}

private struct BackendTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
}

private struct BackendErrorResponse: Codable {
    let error: String
    let message: String?
    let details: [String: [String]]?
    let statusCode: Int
}