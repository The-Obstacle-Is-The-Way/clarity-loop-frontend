//
//  JSONEncodingTests.swift
//  clarity-loop-frontendTests
//
//  Tests to verify JSON encoding/decoding with snake_case conversion
//

import XCTest
@testable import clarity_loop_frontend

final class JSONEncodingTests: XCTestCase {
    
    var encoder: JSONEncoder!
    var decoder: JSONDecoder!
    
    override func setUp() {
        super.setUp()
        
        // Match the configuration in APIClient
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func testInsightGenerationRequestEncoding() throws {
        // Given
        let request = InsightGenerationRequestDTO(
            analysisResults: ["test_key": AnyCodable("test_value")],
            context: "Test context",
            insightType: "comprehensive",
            includeRecommendations: true,
            language: "en"
        )
        
        // When
        let jsonData = try encoder.encode(request)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Then
        XCTAssertTrue(jsonString.contains("\"analysis_results\""))
        XCTAssertTrue(jsonString.contains("\"insight_type\""))
        XCTAssertTrue(jsonString.contains("\"include_recommendations\""))
        XCTAssertFalse(jsonString.contains("\"analysisResults\""))
        XCTAssertFalse(jsonString.contains("\"insightType\""))
        XCTAssertFalse(jsonString.contains("\"includeRecommendations\""))
    }
    
    func testHealthKitUploadRequestEncoding() throws {
        // Given
        let sample = HealthKitSampleDTO(
            identifier: "test-id",
            type: "quantity",
            value: 72.5,
            unit: "bpm",
            startDate: Date(),
            endDate: Date(),
            sourceName: "Apple Watch",
            device: nil,
            metadata: [:]
        )
        
        let request = HealthKitUploadRequestDTO(
            userId: "user-123",
            quantitySamples: [sample],
            categorySamples: [],
            workouts: [],
            correlationSamples: [],
            uploadMetadata: [:],
            syncToken: nil
        )
        
        // When
        let jsonData = try encoder.encode(request)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Then
        XCTAssertTrue(jsonString.contains("\"user_id\""))
        XCTAssertTrue(jsonString.contains("\"quantity_samples\""))
        XCTAssertTrue(jsonString.contains("\"category_samples\""))
        XCTAssertTrue(jsonString.contains("\"upload_metadata\""))
        XCTAssertTrue(jsonString.contains("\"sync_token\""))
        XCTAssertTrue(jsonString.contains("\"start_date\""))
        XCTAssertTrue(jsonString.contains("\"end_date\""))
        XCTAssertTrue(jsonString.contains("\"source_name\""))
    }
    
    func testInsightGenerationResponseDecoding() throws {
        // Given
        let jsonString = """
        {
            "success": true,
            "data": {
                "user_id": "test-user",
                "narrative": "Test narrative",
                "key_insights": ["Insight 1", "Insight 2"],
                "recommendations": ["Rec 1", "Rec 2"],
                "confidence_score": 0.85,
                "generated_at": "2025-06-08T12:00:00Z"
            },
            "metadata": null
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let response = try decoder.decode(InsightGenerationResponseDTO.self, from: jsonData)
        
        // Then
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.data.userId, "test-user")
        XCTAssertEqual(response.data.narrative, "Test narrative")
        XCTAssertEqual(response.data.keyInsights.count, 2)
        XCTAssertEqual(response.data.recommendations.count, 2)
        XCTAssertEqual(response.data.confidenceScore, 0.85)
    }
}