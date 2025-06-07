import XCTest
@testable import clarity_loop_frontend

final class GenerateInsightUseCaseTests: XCTestCase {

    var generateInsightUseCase: GenerateInsightUseCase!
    var mockInsightAIService: MockInsightAIService!
    var mockHealthDataRepository: MockHealthDataRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockInsightAIService = MockInsightAIService()
        mockHealthDataRepository = MockHealthDataRepository()
        generateInsightUseCase = GenerateInsightUseCase(
            insightAIService: mockInsightAIService,
            healthDataRepository: mockHealthDataRepository
        )
    }

    override func tearDownWithError() throws {
        generateInsightUseCase = nil
        mockInsightAIService = nil
        mockHealthDataRepository = nil
        try super.tearDownWithError()
    }

    // MARK: - Test Cases

    func testExecute_Success() async throws {
        // Given
        mockHealthDataRepository.shouldSucceed = true
        mockInsightAIService.shouldSucceed = true
        
        // When
        let insight = try await generateInsightUseCase.execute()
        
        // Then
        XCTAssertNotNil(insight)
    }

    func testExecute_Failure() async throws {
        // Given
        mockHealthDataRepository.shouldSucceed = false
        
        // When / Then
        do {
            _ = try await generateInsightUseCase.execute()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testExecute_InsufficientData() async throws {
        // Given
        mockHealthDataRepository.shouldSucceed = true
        mockInsightAIService.shouldSucceed = true
        // TODO: Configure mock to return empty data
        
        // When / Then
        do {
            let insight = try await generateInsightUseCase.execute()
            XCTAssertNotNil(insight, "Should still return an insight, but it may be a generic one.")
        } catch {
            XCTFail("Should handle insufficient data gracefully")
        }
    }
}

class MockInsightAIService: InsightAIServiceProtocol {
    var shouldSucceed = true
    
    func generateInsight(from analysisResults: [String : Any], context: String?, insightType: String, includeRecommendations: Bool, language: String) async throws -> HealthInsightDTO {
        if shouldSucceed {
            return HealthInsightDTO(userId: "test", narrative: "Test narrative", keyInsights: [], recommendations: [], confidenceScore: 0.9, generatedAt: Date())
        } else {
            throw APIError.serverError(statusCode: 500, message: "AI service error")
        }
    }
    
    func generateInsightFromHealthData(metrics: [HealthMetricDTO], patAnalysis: [String : Any]?, customContext: String?) async throws -> HealthInsightDTO {
        if shouldSucceed {
            return HealthInsightDTO(userId: "test", narrative: "Test narrative", keyInsights: [], recommendations: [], confidenceScore: 0.9, generatedAt: Date())
        } else {
            throw APIError.serverError(statusCode: 500, message: "AI service error")
        }
    }
    
    func generateChatResponse(userMessage: String, conversationHistory: [ChatMessage], healthContext: [String : Any]?) async throws -> HealthInsightDTO {
        if shouldSucceed {
            return HealthInsightDTO(userId: "test", narrative: "Test narrative", keyInsights: [], recommendations: [], confidenceScore: 0.9, generatedAt: Date())
        } else {
            throw APIError.serverError(statusCode: 500, message: "AI service error")
        }
    }
    
    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO {
        if shouldSucceed {
            let data = InsightHistoryDataDTO(insights: [], totalCount: 0, hasMore: false, pagination: nil)
            return InsightHistoryResponseDTO(success: true, data: data, metadata: nil)
        } else {
            throw APIError.serverError(statusCode: 500, message: "History error")
        }
    }
    
    func checkServiceStatus() async throws -> ServiceStatusResponseDTO {
        if shouldSucceed {
            let modelInfo = ModelInfoDTO(modelName: "test", projectId: "test", initialized: true, capabilities: [])
            let data = ServiceStatusDataDTO(service: "test", status: "ok", modelInfo: modelInfo, timestamp: Date(), uptime: nil, version: nil)
            return ServiceStatusResponseDTO(success: true, data: data, metadata: nil)
        } else {
            throw APIError.serverError(statusCode: 500, message: "Status error")
        }
    }
}

class MockHealthDataRepository: HealthDataRepositoryProtocol {
    var shouldSucceed = true
    
    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO {
        if shouldSucceed {
            return PaginatedMetricsResponseDTO(data: [])
        } else {
            throw APIError.serverError(statusCode: 500, message: "Database error")
        }
    }
} 