import Foundation

// MARK: - Token Refresh

/// DTO for the token refresh request body.
struct RefreshTokenRequestDTO: Codable {
    let refreshToken: String
}

// MARK: - Miscellaneous Auth DTOs

/// A generic DTO for API responses that only contain a message.
/// Used for endpoints like logout or verify email.
struct MessageResponseDTO: Codable {
    let message: String
}

/// A generic DTO for representing validation errors from the API.
struct ValidationErrorDTO: Codable {
    let field: String
    let message: String
    let code: String
}

/// A DTO for user privacy preferences.
struct UserPrivacyPreferencesDTO: Codable {
    let shareDataForResearch: Bool
    let enableAnalytics: Bool
    let marketingEmails: Bool
    let pushNotifications: Bool
    let dataRetentionPeriod: Int // in days
    let allowThirdPartyIntegrations: Bool
}
