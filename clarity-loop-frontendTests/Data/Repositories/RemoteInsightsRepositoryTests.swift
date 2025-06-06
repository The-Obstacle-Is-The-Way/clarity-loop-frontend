import XCTest
@testable import clarity_loop_frontend

fileprivate class MockAPIClient: APIClientProtocol {
    
    var insightsHistoryShouldSucceed = true
    var generateInsightShouldSucceed = true
    
    var mockInsightHistoryResponse: InsightHistoryResponseDTO?
    var mockGenerateInsightResponse: InsightGenerationResponseDTO?
    
    // Health Data Methods
    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO { fatalError("Not implemented") }
    
    // Insights Methods
    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO {
        if insightsHistoryShouldSucceed {
            return mockInsightHistoryResponse ?? InsightHistoryResponseDTO(success: true, data: InsightHistoryDataDTO(insights: [], totalCount: 0, hasMore: false, pagination: nil), metadata: nil)
        } else {
            throw APIError.serverError(statusCode: 500, message: "Test server error")
        }
    }
    
    func generateInsight(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO {
        if generateInsightShouldSucceed {
            return mockGenerateInsightResponse!
        } else {
            throw APIError.serverError(statusCode: 400, message: "Bad request")
        }
    }
    
    // Auth Methods
    func register(requestDTO: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO { fatalError("Not implemented") }
    func login(requestDTO: UserLoginRequestDTO) async throws -> LoginResponseDTO { fatalError("Not implemented") }
}

final class RemoteInsightsRepositoryTests: XCTestCase {

    private var repository: RemoteInsightsRepository!
    private var mockAPIClient: MockAPIClient!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        repository = RemoteInsightsRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        repository = nil
        mockAPIClient = nil
        super.tearDown()
    }

    func testGetInsightHistory_Success() async throws {
        // Given
        let mockInsight = InsightPreviewDTO(id: "1", narrative: "Test Insight", generatedAt: Date(), confidenceScore: 0.9, keyInsightsCount: 1, recommendationsCount: 1)
        mockAPIClient.mockInsightHistoryResponse = InsightHistoryResponseDTO(success: true, data: InsightHistoryDataDTO(insights: [mockInsight], totalCount: 1, hasMore: false, pagination: nil), metadata: nil)
        
        // When
        let response = try await repository.getInsightHistory(userId: "test", limit: 10, offset: 0)
        
        // Then
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.data.insights.count, 1)
        XCTAssertEqual(response.data.insights.first?.id, "1")
    }
    
    func testGetInsightHistory_Failure() async {
        // Given
        mockAPIClient.insightsHistoryShouldSucceed = false
        
        // When & Then
        do {
            _ = try await repository.getInsightHistory(userId: "test", limit: 10, offset: 0)
            XCTFail("Should have thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
} 