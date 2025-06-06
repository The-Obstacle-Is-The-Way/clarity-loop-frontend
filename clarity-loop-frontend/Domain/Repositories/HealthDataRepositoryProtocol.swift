//
//  HealthDataRepositoryProtocol.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation

/// A protocol defining the contract for a repository that handles fetching health data.
/// This abstraction allows for interchangeable concrete implementations (e.g., a remote repository
/// that fetches from an API, or a local one that fetches from a cache).
protocol HealthDataRepositoryProtocol {
    
    /// Fetches a paginated list of health metrics.
    /// - Parameters:
    ///   - page: The page number to retrieve.
    ///   - limit: The number of items per page.
    /// - Returns: A `PaginatedMetricsResponseDTO` containing the health data.
    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO
    
    // For the dashboard, we might want a higher-level summary.
    // This will be defined later. For now, the protocol is a placeholder.
} 
