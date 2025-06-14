import XCTest
@testable import clarity_loop_frontend

final class FetchDailyHealthSummaryUseCaseTests: XCTestCase {

    var fetchDailyHealthSummaryUseCase: FetchDailyHealthSummaryUseCase!
    var mockHealthDataRepository: MockHealthDataRepository!
    var mockHealthKitService: MockHealthKitService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockHealthDataRepository = MockHealthDataRepository()
        mockHealthKitService = MockHealthKitService()
        fetchDailyHealthSummaryUseCase = FetchDailyHealthSummaryUseCase(
            healthDataRepository: mockHealthDataRepository,
            healthKitService: mockHealthKitService
        )
    }

    override func tearDownWithError() throws {
        fetchDailyHealthSummaryUseCase = nil
        mockHealthDataRepository = nil
        mockHealthKitService = nil
        try super.tearDownWithError()
    }

    // MARK: - Test Cases

    func testExecute_Success() async throws {
        // Given - Mock repository returns valid data
        mockHealthDataRepository.shouldSucceed = true
        
        // When
        let summary = try await fetchDailyHealthSummaryUseCase.execute(for: Date())
        
        // Then
        XCTAssertNotNil(summary)
        XCTAssertGreaterThan(summary.remoteMetrics.count, 0)
        XCTAssertTrue(summary.hasCompleteData)
    }

    func testExecute_Failure() async throws {
        // Given - Mock repository throws error
        mockHealthDataRepository.shouldSucceed = false
        
        // When/Then
        do {
            _ = try await fetchDailyHealthSummaryUseCase.execute(for: Date())
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }

    func testExecute_NoData() async throws {
        // Given - Mock returns empty data
        mockHealthDataRepository.shouldSucceed = true
        mockHealthKitService.mockDailyMetrics = DailyHealthMetrics(
            date: Date(),
            stepCount: 0,
            restingHeartRate: nil,
            sleepData: nil
        )
        
        // When
        let summary = try await fetchDailyHealthSummaryUseCase.execute(for: Date())
        
        // Then
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary.remoteMetrics.count, 0)
        XCTAssertFalse(summary.hasCompleteData)
    }
} 