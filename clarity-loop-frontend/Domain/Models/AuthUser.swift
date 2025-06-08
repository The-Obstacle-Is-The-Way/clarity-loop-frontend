import Foundation

/// Domain model representing an authenticated user
/// This abstracts away Firebase-specific types from the domain layer
struct AuthUser: Equatable {
    let uid: String
    let email: String?
    let isEmailVerified: Bool
    
    init(uid: String, email: String?, isEmailVerified: Bool = false) {
        self.uid = uid
        self.email = email
        self.isEmailVerified = isEmailVerified
    }
}

#if canImport(FirebaseAuth)
import FirebaseAuth

extension AuthUser {
    /// Convenience initializer to create AuthUser from Firebase User
    init(firebaseUser: FirebaseAuth.User) {
        self.uid = firebaseUser.uid
        self.email = firebaseUser.email
        self.isEmailVerified = firebaseUser.isEmailVerified
    }
}
#endif 
