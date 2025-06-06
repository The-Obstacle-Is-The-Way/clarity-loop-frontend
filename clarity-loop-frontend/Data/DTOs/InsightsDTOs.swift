//
//  InsightsDTOs.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation

// Note: The `AnyCodable` type from the `AnyCodable.swift` file is used here
// to handle dynamic JSON values in metadata fields.

// MARK: - Insight Generation DTOs

struct InsightGenerationRequestDTO: Codable {
    let analysisResults: [String: AnyCodable]
    let context: String?
    let insightType: String
    let includeRecommendations: Bool
    let language: String
}

struct InsightGenerationResponseDTO: Codable {
    let success: Bool
    let data: HealthInsightDTO
    let metadata: [String: AnyCodable]?
}

// MARK: - Main Insight DTO

struct HealthInsightDTO: Codable, Identifiable {
    var id: String { userId } // This might need a more stable ID from the backend.
    
    let userId: String
    let narrative: String
    let keyInsights: [String]
    let recommendations: [String]
    let confidenceScore: Double
    let generatedAt: Date
}

// MARK: - Insight History DTOs

struct InsightHistoryResponseDTO: Codable {
    let success: Bool
    let data: InsightHistoryDataDTO
    let metadata: [String: AnyCodable]?
}

struct InsightHistoryDataDTO: Codable {
    let insights: [InsightPreviewDTO]
    let totalCount: Int
    let hasMore: Bool
    let pagination: PaginationMetaDTO?
}

struct InsightPreviewDTO: Codable, Identifiable {
    let id: String
    let narrative: String
    let generatedAt: Date
    let confidenceScore: Double
    let keyInsightsCount: Int
    let recommendationsCount: Int
}

struct PaginationMetaDTO: Codable {
    let page: Int
    let limit: Int
    // Add other pagination fields as needed from the API spec
} 
