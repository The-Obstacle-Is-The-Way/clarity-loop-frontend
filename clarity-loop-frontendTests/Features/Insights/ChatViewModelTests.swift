import XCTest
@testable import clarity_loop_frontend

// MARK: - Mock Insights Repository
fileprivate class MockInsightsRepository: InsightsRepositoryProtocol {
    var generateInsightShouldSucceed = true
    var mockNarrative = "This is a test insight."
    
    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO {
        fatalError("Not implemented")
    }
    
    func generateInsight(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO {
        if generateInsightShouldSucceed {
            let insight = HealthInsightDTO(userId: "test", narrative: mockNarrative, keyInsights: [], recommendations: [], confidenceScore: 1.0, generatedAt: Date())
            return InsightGenerationResponseDTO(success: true, data: insight, metadata: nil)
        } else {
            throw APIError.serverError(statusCode: 500, message: "Test error")
        }
    }
}


@MainActor
final class ChatViewModelTests: XCTestCase {

    private var viewModel: ChatViewModel!
    private var mockInsightsRepo: MockInsightsRepository!

    override func setUp() {
        super.setUp()
        mockInsightsRepo = MockInsightsRepository()
        viewModel = ChatViewModel(insightsRepo: mockInsightsRepo)
    }

    override func tearDown() {
        viewModel = nil
        mockInsightsRepo = nil
        super.tearDown()
    }

    func testSendMessage_WithEmptyInput_DoesNothing() {
        // Given
        viewModel.currentInput = "   "
        
        // When
        viewModel.sendMessage()
        
        // Then
        XCTAssertTrue(viewModel.messages.isEmpty)
    }
    
    func testSendMessage_Success_AddsUserAndAssistantMessages() async {
        // Given
        viewModel.currentInput = "Hello"
        mockInsightsRepo.generateInsightShouldSucceed = true
        
        // When
        viewModel.sendMessage()
        
        // Wait for async task to complete
        await Task.yield()
        
        // Then
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages.first?.sender, .user)
        XCTAssertEqual(viewModel.messages.first?.text, "Hello")
        XCTAssertEqual(viewModel.messages.last?.sender, .assistant)
        XCTAssertEqual(viewModel.messages.last?.text, mockInsightsRepo.mockNarrative)
        XCTAssertFalse(viewModel.isSending)
    }
    
    func testSendMessage_Failure_AddsUserAndErrorMessages() async {
        // Given
        viewModel.currentInput = "Hello"
        mockInsightsRepo.generateInsightShouldSucceed = false
        
        // When
        viewModel.sendMessage()
        
        // Wait for async task to complete
        await Task.yield()
        
        // Then
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages.first?.sender, .user)
        XCTAssertEqual(viewModel.messages.last?.sender, .assistant)
        XCTAssertTrue(viewModel.messages.last?.isError ?? false)
        XCTAssertFalse(viewModel.isSending)
    }
} 