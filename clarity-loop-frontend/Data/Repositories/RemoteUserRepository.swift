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
    
    // Protocol methods for fetching and updating the user profile will be implemented here.
} 