import Foundation
import SwiftData

/// Represents a user's profile information stored locally.
///
/// This model caches the user data received from the backend to provide offline access
/// and reduce network requests. It corresponds to the `UserSessionResponseDTO`.
@Model
final class UserProfile {
    /// The unique identifier for the user, matching the backend UUID.
    @Attribute(.unique) var id: UUID

    /// The user's email address.
    var email: String

    /// The user's first name.
    var firstName: String

    /// The user's last name.
    var lastName: String

    /// The user's assigned role (e.g., "user", "admin").
    var role: String

    /// A list of permissions assigned to the user.
    var permissions: [String]

    /// The current status of the user's account (e.g., "active", "pending_verification").
    var status: String

    /// A flag indicating if the user has verified their email address.
    var isEmailVerified: Bool

    /// A flag indicating if Multi-Factor Authentication is enabled for the user.
    var isMfaEnabled: Bool

    /// The timestamp when the user account was created.
    var createdAt: Date

    /// The timestamp of the user's last login.
    var lastLogin: Date?

    /// A local-only timestamp indicating when this record was last synced from the backend.
    var lastSyncedAt: Date

    init(
        id: UUID,
        email: String,
        firstName: String,
        lastName: String,
        role: String,
        permissions: [String],
        status: String,
        isEmailVerified: Bool,
        isMfaEnabled: Bool,
        createdAt: Date,
        lastLogin: Date?,
        lastSyncedAt: Date
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.role = role
        self.permissions = permissions
        self.status = status
        self.isEmailVerified = isEmailVerified
        self.isMfaEnabled = isMfaEnabled
        self.createdAt = createdAt
        self.lastLogin = lastLogin
        self.lastSyncedAt = lastSyncedAt
    }
} 
 
