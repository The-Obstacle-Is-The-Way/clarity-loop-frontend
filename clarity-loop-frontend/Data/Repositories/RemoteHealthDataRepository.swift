//
//  RemoteHealthDataRepository.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation

/// A concrete implementation of the `HealthDataRepositoryProtocol` that fetches health data
/// from the remote backend API.
class RemoteHealthDataRepository: HealthDataRepositoryProtocol {
    
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO {
        return try await apiClient.getHealthData(page: page, limit: limit)
    }
    
    // Protocol methods will be implemented here later.
    // For example:
    // func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO {
    //     return try await apiClient.getHealthData(page: page, limit: limit)
    // }
} 
