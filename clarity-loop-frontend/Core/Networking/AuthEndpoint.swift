import Foundation

/// Defines the endpoints for the authentication-related API calls.
enum AuthEndpoint: Endpoint {
    case register(dto: UserRegistrationRequestDTO)
    case login(dto: UserLoginRequestDTO)
    case refreshToken(dto: RefreshTokenRequestDTO)
    case logout
    case getCurrentUser
    case verifyEmail(code: String)

    var path: String {
        switch self {
        case .register:
            return "/api/v1/auth/register"
        case .login:
            return "/api/v1/auth/login"
        case .refreshToken:
            return "/api/v1/auth/refresh"
        case .logout:
            return "/api/v1/auth/logout"
        case .getCurrentUser:
            return "/api/v1/auth/me"
        case .verifyEmail:
            return "/api/v1/auth/verify-email"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .register, .login, .refreshToken, .logout:
            return .post
        case .getCurrentUser, .verifyEmail:
            return .get
        }
    }

    func body(encoder: JSONEncoder) throws -> Data? {
        switch self {
        case .register(let dto):
            return try encoder.encode(dto)
        case .login(let dto):
            return try encoder.encode(dto)
        case .refreshToken(let dto):
            return try encoder.encode(dto)
        default:
            return nil
        }
    }
}
