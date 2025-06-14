import Foundation

// MARK: - User Login

/// DTO for the user login request body.
struct UserLoginRequestDTO: Codable {
    let email: String
    let password: String
    let rememberMe: Bool
    let deviceInfo: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
        case rememberMe = "remember_me"
        case deviceInfo = "device_info"
    }
}

/// DTO for the complete user login response body.
/// This is a composite DTO containing the user session and authentication tokens.
struct LoginResponseDTO: Codable {
    let user: UserSessionResponseDTO
    let tokens: TokenResponseDTO
}

/// DTO representing the user's session information.
struct UserSessionResponseDTO: Codable {
    let userId: UUID
    let firstName: String
    let lastName: String
    let email: String
    let role: String
    let permissions: [String]
    let status: String
    let mfaEnabled: Bool
    let emailVerified: Bool
    let createdAt: Date
    let lastLogin: Date?
}

/// DTO representing the authentication tokens.
struct TokenResponseDTO: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
} 
