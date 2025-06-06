//
//  RemoteUserRepository.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation

/// A concrete implementation of the `UserRepositoryProtocol` that manages user data
/// with the remote backend API.
class RemoteUserRepository: UserRepositoryProtocol {
    
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func getCurrentUserProfile() async throws -> UserProfile {
        // TODO: Add API endpoint for getting user profile
        fatalError("Not implemented yet")
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        // TODO: Add API endpoint for updating user profile
        fatalError("Not implemented yet")
    }
    
    func deleteUserAccount() async throws {
        // TODO: Add API endpoint for deleting user account
        fatalError("Not implemented yet")
    }
    
    func getPrivacyPreferences() async throws -> UserPrivacyPreferencesDTO {
        // TODO: Add API endpoint for getting privacy preferences
        fatalError("Not implemented yet")
    }
    
    func updatePrivacyPreferences(_ preferences: UserPrivacyPreferencesDTO) async throws {
        // TODO: Add API endpoint for updating privacy preferences
        fatalError("Not implemented yet")
    }
} 
