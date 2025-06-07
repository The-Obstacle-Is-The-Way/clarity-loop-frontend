import XCTest
@testable import clarity_loop_frontend

final class RemoteInsightsRepositoryTests: XCTestCase {

    var insightsRepository: RemoteInsightsRepository!
    var mockAPIClient: MockAPIClient!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockAPIClient = MockAPIClient()
        insightsRepository = RemoteInsightsRepository(apiClient: mockAPIClient)
    }

    override func tearDownWithError() throws {
        insightsRepository = nil
        mockAPIClient = nil
        try super.tearDownWithError()
    }

    // MARK: - Test Cases

    func testFetchInsights_Success() async throws {
        // Given
        mockAPIClient.shouldSucceed = true

        // When
        let insights = try await insightsRepository.getInsightHistory(userId: "test", limit: 10, offset: 0)

        // Then
        XCTAssertNotNil(insights)
        XCTAssertTrue(insights.success)
    }

    func testFetchInsights_Failure() async throws {
        // Given
        mockAPIClient.shouldSucceed = false

        // When / Then
        do {
            _ = try await insightsRepository.getInsightHistory(userId: "test", limit: 10, offset: 0)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testFetchInsights_Empty() async throws {
        // Given
        mockAPIClient.shouldSucceed = true
        // You might need to configure your mock to return an empty array specifically
        
        // When
        let insights = try await insightsRepository.getInsightHistory(userId: "test", limit: 10, offset: 0)
        
        // Then
        XCTAssertNotNil(insights)
        XCTAssertTrue(insights.success)
        XCTAssertTrue(insights.data.insights.isEmpty)
    }
} 