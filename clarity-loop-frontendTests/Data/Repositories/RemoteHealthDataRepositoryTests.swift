import XCTest
@testable import clarity_loop_frontend




final class RemoteHealthDataRepositoryTests: XCTestCase {

    private var repository: RemoteHealthDataRepository!
    private var mockAPIClient: MockAPIClient!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        repository = RemoteHealthDataRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        repository = nil
        mockAPIClient = nil
        super.tearDown()
    }

    func testGetHealthData_Success() async throws {
        // Given
        let mockDTO = HealthMetricDTO(metricId: UUID(), metricType: "steps", biometricData: nil, sleepData: nil, activityData: ActivityDataDTO(steps: 100, distance: nil, activeEnergy: nil, exerciseMinutes: nil, flightsClimbed: nil, vo2Max: nil, activeMinutes: nil, restingHeartRate: nil), mentalHealthData: nil, deviceId: nil, rawData: nil, metadata: nil, createdAt: Date())
        mockAPIClient.mockHealthDataResponse = PaginatedMetricsResponseDTO(
            success: true,
            data: PaginatedMetricsDataDTO(
                metrics: [mockDTO],
                pagination: PaginationDTO(
                    currentPage: 1,
                    totalPages: 1,
                    totalItems: 1,
                    itemsPerPage: 10,
                    hasNext: false,
                    hasPrevious: false
                )
            ),
            message: "Success"
        )
        
        // When
        let response = try await repository.getHealthData(page: 1, limit: 10)
        
        // Then
        XCTAssertEqual(response.data.metrics.count, 1)
        XCTAssertEqual(response.data.metrics.first?.metricId, mockDTO.metricId)
        XCTAssertEqual(response.data.metrics.first?.activityData?.steps, 100)
    }
    
    func testGetHealthData_Failure() async {
        // Given
        mockAPIClient.shouldSucceed = false
        
        // When
        do {
            _ = try await repository.getHealthData(page: 1, limit: 10)
            XCTFail("The repository should have thrown an error, but it did not.")
        } catch {
            // Then
            guard let apiError = error as? APIError else {
                XCTFail("The thrown error is not of type APIError.")
                return
            }
            
            switch apiError {
            case .serverError(let statusCode, _):
                XCTAssertEqual(statusCode, 500)
            default:
                XCTFail("The error type is not the expected .serverError.")
            }
        }
    }
} 