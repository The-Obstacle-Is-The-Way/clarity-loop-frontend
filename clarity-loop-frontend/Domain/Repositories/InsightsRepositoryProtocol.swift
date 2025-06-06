//
//  InsightsRepositoryProtocol.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation

/// A protocol defining the contract for a repository that handles fetching AI-generated insights.
protocol InsightsRepositoryProtocol {
    
    /// Fetches the history of insights for a given user.
    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO
    
    /// Generates a new insight based on the provided data.
    func generateInsight(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO
    
    /// Fetches the "Insight of the Day" for the dashboard.
    // func getInsightOfTheDay() async throws -> InsightEntity?
    
    // Additional methods for fetching insight history or generating new insights
    // will be added here later.
} 
