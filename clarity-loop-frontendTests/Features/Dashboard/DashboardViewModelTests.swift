import XCTest
@testable import clarity_loop_frontend

// A mock repository for testing the view model.
fileprivate class MockHealthDataRepository: HealthDataRepositoryProtocol {
    
    var healthDataShouldSucceed = true
    var shouldReturnEmptyData = false
    
    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO {
        if healthDataShouldSucceed {
            if shouldReturnEmptyData {
                return PaginatedMetricsResponseDTO(data: [])
            } else {
                let mockDTO = HealthMetricDTO(metricId: UUID(), metricType: "steps", biometricData: nil, sleepData: nil, activityData: ActivityDataDTO(steps: 100, distance: nil, activeEnergy: nil, exerciseMinutes: nil, flightsClimbed: nil, vo2Max: nil, activeMinutes: nil, restingHeartRate: nil), mentalHealthData: nil, deviceId: nil, rawData: nil, metadata: nil, createdAt: Date())
                return PaginatedMetricsResponseDTO(data: [mockDTO])
            }
        } else {
            throw APIError.serverError(statusCode: 500, message: "Test server error")
        }
    }
}

@MainActor
final class DashboardViewModelTests: XCTestCase {

    private var viewModel: DashboardViewModel!
    private var mockRepository: MockHealthDataRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockHealthDataRepository()
        viewModel = DashboardViewModel(healthDataRepo: mockRepository)
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        super.tearDown()
    }

    func testLoadDashboard_InitialStateIsIdle() {
        if case .idle = viewModel.viewState {
            // Success
        } else {
            XCTFail("Initial state should be .idle, but was \(viewModel.viewState)")
        }
    }

    func testLoadDashboard_Success_TransitionsToLoadedState() async {
        // Given
        mockRepository.healthDataShouldSucceed = true
        
        // When
        await viewModel.loadDashboard()
        
        // Then
        if case .loaded(let data) = viewModel.viewState {
            XCTAssertFalse(data.metrics.isEmpty, "Loaded data should not be empty.")
        } else {
            XCTFail("ViewModel should be in the loaded state, but was \(viewModel.viewState)")
        }
    }
    
    func testLoadDashboard_Success_WithEmptyData_TransitionsToEmptyState() async {
        // Given
        mockRepository.healthDataShouldSucceed = true
        mockRepository.shouldReturnEmptyData = true
        
        // When
        await viewModel.loadDashboard()
        
        // Then
        if case .empty = viewModel.viewState {
            // Success
        } else {
            XCTFail("ViewModel should be in the empty state, but was \(viewModel.viewState)")
        }
    }
    
    func testLoadDashboard_Failure_TransitionsToErrorState() async {
        // Given
        mockRepository.healthDataShouldSucceed = false
        
        // When
        await viewModel.loadDashboard()
        
        // Then
        if case .error = viewModel.viewState {
            // Success
        } else {
            XCTFail("ViewModel should be in the error state, but was \(viewModel.viewState)")
        }
    }
    
    func testLoadDashboard_SetsLoadingState() async {
        // Given
        let expectation = XCTestExpectation(description: "The view model enters and exits the loading state.")
        var hasEnteredLoadingState = false
        
        let cancellable = viewModel.$viewState.sink { state in
            if case .loading = state {
                hasEnteredLoadingState = true
            }
            if hasEnteredLoadingState && (if case .loading = state { false } else { true }) {
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