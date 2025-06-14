import XCTest
@testable import clarity_loop_frontend

final class FetchDailyHealthSummaryUseCaseTests: XCTestCase {

    var fetchDailyHealthSummaryUseCase: FetchDailyHealthSummaryUseCase!
    var mockHealthDataRepository: MockHealthDataRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockHealthDataRepository = MockHealthDataRepository()
        fetchDailyHealthSummaryUseCase = FetchDailyHealthSummaryUseCase(
            healthDataRepository: mockHealthDataRepository
        )
    }

    override func tearDownWithError() throws {
        fetchDailyHealthSummaryUseCase = nil
        mockHealthDataRepository = nil
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
        XCTAssertGreaterThan(summary.data.count, 0)
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
        // Given - Mock repository returns empty data
        mockHealthDataRepository.shouldReturnEmpty = true
        
        // When
        let summary = try await fetchDailyHealthSummaryUseCase.execute(for: Date())
        
        // Then
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary.data.count, 0)
    }
} 