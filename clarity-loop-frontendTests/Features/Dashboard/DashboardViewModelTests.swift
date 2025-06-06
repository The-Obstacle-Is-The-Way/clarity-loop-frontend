import XCTest
@testable import clarity_loop_frontend

// MARK: - Mock Insights Repository
fileprivate class MockInsightsRepository: InsightsRepositoryProtocol {
    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO {
        return InsightHistoryResponseDTO(success: true, data: .init(insights: [], totalCount: 0, hasMore: false, pagination: nil), metadata: nil)
    }
    func generateInsight(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO {
        fatalError("Not implemented")
    }
}

// MARK: - Mock HealthKit Service
fileprivate class MockHealthKitService: HealthKitServiceProtocol {
    var shouldSucceed = true
    var mockMetrics = DailyHealthMetrics(date: Date(), stepCount: 5000, restingHeartRate: 60, sleepData: nil)
    
    func isHealthDataAvailable() -> Bool { true }
    func requestAuthorization() async throws {
        if !shouldSucceed {
            throw APIError.unknown(NSError(domain: "test", code: 0, userInfo: nil))
        }
    }
    func fetchAllDailyMetrics(for date: Date) async throws -> DailyHealthMetrics {
        if shouldSucceed {
            return mockMetrics
        } else {
            throw APIError.unknown(NSError(domain: "test", code: 0, userInfo: nil))
        }
    }
    func fetchDailySteps(for date: Date) async throws -> Double { 0.0 }
    func fetchRestingHeartRate(for date: Date) async throws -> Double? { nil }
    func fetchSleepAnalysis(for date: Date) async throws -> SleepData? { nil }
    func uploadHealthKitData(_ uploadRequest: HealthKitUploadRequestDTO) async throws -> HealthKitUploadResponseDTO {
        return HealthKitUploadResponseDTO(success: true, uploadId: "test", processedSamples: 1, skippedSamples: 0, errors: nil, message: nil)
    }
}

@MainActor
final class DashboardViewModelTests: XCTestCase {

    private var viewModel: DashboardViewModel!
    private var mockInsightsRepo: MockInsightsRepository!
    private var mockHealthKitService: MockHealthKitService!

    override func setUp() {
        super.setUp()
        mockInsightsRepo = MockInsightsRepository()
        mockHealthKitService = MockHealthKitService()
        viewModel = DashboardViewModel(
            insightsRepo: mockInsightsRepo,
            healthKitService: mockHealthKitService
        )
    }

    override func tearDown() {
        viewModel = nil
        mockInsightsRepo = nil
        mockHealthKitService = nil
        super.tearDown()
    }

    func testLoadDashboard_InitialStateIsIdle() {
        guard case .idle = viewModel.viewState else {
            XCTFail("Initial state should be .idle, but was \(viewModel.viewState)")
            return
        }
        // Success
    }

    func testLoadDashboard_Success_TransitionsToLoadedState() async {
        // Given
        mockHealthKitService.shouldSucceed = true
        
        // When
        await viewModel.loadDashboard()
        
        // Then
        guard case .loaded(let data) = viewModel.viewState else {
            XCTFail("Expected .loaded state, but was \(viewModel.viewState)")
            return
        }
    }
    
    func testLoadDashboard_Failure_TransitionsToErrorState() async {
        // Given
        mockHealthKitService.shouldSucceed = false
        
        // When
        await viewModel.loadDashboard()
        
        // Then
        guard case .error = viewModel.viewState else {
            XCTFail("ViewModel should be in the error state, but was \(viewModel.viewState)")
            return
        }
        // Success
    }
    
    func testLoadDashboard_SetsLoadingState() async {
        // Given
        let expectation = XCTestExpectation(description: "The view model enters and exits the loading state.")
        var hasEnteredLoadingState = false
        
        let cancellable = viewModel.$viewState.sink { state in
            if case .loading = state {
                hasEnteredLoadingState = true
            }
            let isNotLoading = !({ if case .loading = state { return true } else { return false } }())
            if hasEnteredLoadingState && isNotLoading {
                expectation.fulfill()
            }
        }
        
        // When
        await viewModel.loadDashboard()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        cancellable.cancel()
    }
} 