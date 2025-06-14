import Foundation

// MARK: - UserSessionResponseDTO to AuthUser Conversion

extension UserSessionResponseDTO {
    /// Converts this DTO to an AuthUser domain model
    var authUser: AuthUser {
        AuthUser(
            id: userId.uuidString,
            email: email,
            fullName: "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces),
            isEmailVerified: emailVerified
        )
    }
}