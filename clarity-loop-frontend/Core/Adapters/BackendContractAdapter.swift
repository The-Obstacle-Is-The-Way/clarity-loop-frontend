import Foundation

// MARK: - Backend Contract Adapter Protocol

/// Protocol defining the contract adaptation layer between frontend and backend
protocol BackendContractAdapterProtocol {
    func adaptRegistrationRequest(_ frontendRequest: UserRegistrationRequestDTO) -> BackendUserRegister
    func adaptRegistrationResponse(_ backendResponse: BackendTokenResponse) throws -> RegistrationResponseDTO
    
    func adaptLoginRequest(_ frontendRequest: UserLoginRequestDTO) -> BackendUserLogin
    func adaptLoginResponse(_ backendResponse: BackendTokenResponse) throws -> LoginResponseDTO
    
    func adaptUserInfoResponse(_ backendResponse: BackendUserInfoResponse) -> UserSessionResponseDTO
    func adaptTokenResponse(_ backendResponse: BackendTokenResponse) -> TokenResponseDTO
    
    func adaptRefreshTokenRequest(_ refreshToken: String) -> BackendRefreshTokenRequest
    func adaptLogoutResponse(_ backendResponse: BackendLogoutResponse) -> MessageResponseDTO
    
    func adaptErrorResponse(_ errorData: Data) -> Error?
}

// MARK: - Backend Contract Adapter Implementation

/// Concrete implementation of the backend contract adapter
/// This class handles all transformations between frontend DTOs and backend contract
final class BackendContractAdapter: BackendContractAdapterProtocol {
    
    // MARK: - Registration Adaptation
    
    func adaptRegistrationRequest(_ frontendRequest: UserRegistrationRequestDTO) -> BackendUserRegister {
        // Combine first and last name for display name
        let displayName = "\(frontendRequest.firstName) \(frontendRequest.lastName)".trimmingCharacters(in: .whitespaces)
        
        return BackendUserRegister(
            email: frontendRequest.email,
            password: frontendRequest.password,
            displayName: displayName.isEmpty ? nil : displayName
        )
    }
    
    func adaptRegistrationResponse(_ backendResponse: BackendTokenResponse) throws -> RegistrationResponseDTO {
        // Extract user ID from the token if possible
        // For now, we'll generate a UUID since the backend doesn't return user info on registration
        // In production, you'd decode the JWT token to get the user ID
        let userId = UUID()
        
        return RegistrationResponseDTO(
            userId: userId,
            email: "", // Backend doesn't return email in token response
            status: "registered",
            verificationEmailSent: true, // Cognito sends verification emails automatically
            createdAt: Date()
        )
    }
    
    // MARK: - Login Adaptation
    
    func adaptLoginRequest(_ frontendRequest: UserLoginRequestDTO) -> BackendUserLogin {
        return BackendUserLogin(
            email: frontendRequest.email,
            password: frontendRequest.password
        )
    }
    
    func adaptLoginResponse(_ backendResponse: BackendTokenResponse) throws -> LoginResponseDTO {
        // For a complete login response, we need user info
        // The frontend expects both user session and tokens
        // Since the backend only returns tokens, we'll need to make a separate call to /me
        // For now, create a minimal response
        
        // Decode JWT to get user info (in production)
        // For now, create placeholder user session
        let userSession = UserSessionResponseDTO(
            userId: UUID(), // Would come from decoded JWT
            firstName: "",
            lastName: "",
            email: "",
            role: "user",
            permissions: ["read", "write"],
            status: "active",
            mfaEnabled: false,
            emailVerified: true,
            createdAt: Date(),
            lastLogin: Date()
        )
        
        let tokens = adaptTokenResponse(backendResponse)
        
        return LoginResponseDTO(
            user: userSession,
            tokens: tokens
        )
    }
    
    // MARK: - User Info Adaptation
    
    func adaptUserInfoResponse(_ backendResponse: BackendUserInfoResponse) -> UserSessionResponseDTO {
        // Parse display name to extract first and last names
        let nameParts = (backendResponse.displayName ?? "").split(separator: " ", maxSplits: 1)
        let firstName = nameParts.first.map(String.init) ?? ""
        let lastName = nameParts.count > 1 ? String(nameParts[1]) : ""
        
        // Convert user ID string to UUID
        let userId = UUID(uuidString: backendResponse.userId) ?? UUID()
        
        return UserSessionResponseDTO(
            userId: userId,
            firstName: firstName,
            lastName: lastName,
            email: backendResponse.email ?? "",
            role: "user", // Backend doesn't provide role
            permissions: ["read", "write"], // Default permissions
            status: "active",
            mfaEnabled: false, // Backend doesn't provide MFA status
            emailVerified: backendResponse.emailVerified,
            createdAt: Date(), // Backend doesn't provide creation date
            lastLogin: Date()
        )
    }
    
    // MARK: - Token Adaptation
    
    func adaptTokenResponse(_ backendResponse: BackendTokenResponse) -> TokenResponseDTO {
        return TokenResponseDTO(
            accessToken: backendResponse.accessToken,
            refreshToken: backendResponse.refreshToken,
            tokenType: backendResponse.tokenType,
            expiresIn: backendResponse.expiresIn
        )
    }
    
    // MARK: - Refresh Token Adaptation
    
    func adaptRefreshTokenRequest(_ refreshToken: String) -> BackendRefreshTokenRequest {
        return BackendRefreshTokenRequest(refreshToken: refreshToken)
    }
    
    // MARK: - Logout Adaptation
    
    func adaptLogoutResponse(_ backendResponse: BackendLogoutResponse) -> MessageResponseDTO {
        return MessageResponseDTO(message: backendResponse.message)
    }
}

// MARK: - Error Adaptation Extension

extension BackendContractAdapter {
    
    /// Adapt backend error responses to frontend errors
    public func adaptErrorResponse(_ errorData: Data) -> Error? {
        let decoder = JSONDecoder()
        
        // Try to decode as ProblemDetail first
        if let problemDetail = try? decoder.decode(BackendProblemDetail.self, from: errorData) {
            return adaptProblemDetail(problemDetail)
        }
        
        // Try to decode as ValidationError
        if let validationError = try? decoder.decode(BackendValidationError.self, from: errorData) {
            return adaptValidationError(validationError)
        }
        
        return nil
    }
    
    private func adaptProblemDetail(_ problemDetail: BackendProblemDetail) -> AuthenticationError {
        switch problemDetail.type {
        case "invalid_credentials":
            return .invalidEmail
        case "email_not_verified":
            return .unknown("Please verify your email before logging in")
        case "registration_error":
            if problemDetail.detail.contains("already exists") {
                return .emailAlreadyInUse
            }
            return .unknown(problemDetail.detail)
        case "validation_error":
            return .unknown(problemDetail.detail)
        default:
            return .unknown(problemDetail.detail)
        }
    }
    
    private func adaptValidationError(_ validationError: BackendValidationError) -> AuthenticationError {
        let errorMessages = validationError.detail.map { $0.msg }.joined(separator: ", ")
        return .unknown("Validation error: \(errorMessages)")
    }
}