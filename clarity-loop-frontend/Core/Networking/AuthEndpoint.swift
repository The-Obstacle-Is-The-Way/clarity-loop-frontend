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
            return "/auth/register"
        case .login:
            return "/auth/login"
        case .refreshToken:
            return "/auth/refresh"
        case .logout:
            return "/auth/logout"
        case .getCurrentUser:
            return "/auth/me"
        case .verifyEmail:
            return "/auth/verify-email"
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

    var body: Data? {
        switch self {
        case .register(let dto):
            return try? encoder.encode(dto)
        case .login(let dto):
            return try? encoder.encode(dto)
        default:
            return nil
        }
    }
}
