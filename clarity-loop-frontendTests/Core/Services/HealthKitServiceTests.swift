import XCTest
@testable import clarity_loop_frontend

class MockAPIClient: APIClientProtocol {
    func register(requestDTO: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        throw APIError.notImplemented
    }
    
    func login(requestDTO: UserLoginRequestDTO) async throws -> LoginResponseDTO {
        throw APIError.notImplemented
    }
    
    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO {
        throw APIError.notImplemented
    }
    
    func uploadHealthKitData(requestDTO: HealthKitUploadRequestDTO) async throws -> HealthKitUploadResponseDTO {
        return HealthKitUploadResponseDTO(success: true, uploadId: "test", processedSamples: 1, skippedSamples: 0, errors: nil, message: nil)
    }
    
    func syncHealthKitData(requestDTO: HealthKitSyncRequestDTO) async throws -> HealthKitSyncResponseDTO {
        throw APIError.notImplemented
    }
    
    func getHealthKitSyncStatus(syncId: String) async throws -> HealthKitSyncStatusDTO {
        throw APIError.notImplemented
    }
    
    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO {
        throw APIError.notImplemented
    }
    
    func generateInsight(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO {
        throw APIError.notImplemented
    }
}

final class HealthKitServiceTests: XCTestCase {

    private var service: HealthKitService!

    override func setUp() {
        super.setUp()
        let mockAPIClient = MockAPIClient()
        service = HealthKitService(apiClient: mockAPIClient)
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // Note: This is an integration test, not a unit test, as it interacts
    // with the real HealthKit store. It requires running on a simulator or
    // device where HealthKit is available and permissions may be requested.
    func testFetchDailySteps_DoesNotThrow() async {
        // Given
        let today = Date()
        
        // When
        do {
            let steps = try await service.fetchDailySteps(for: today)
            // Then
            XCTAssertNotNil(steps, "The method should return a value, even if it's 0.")
            print("Successfully fetched steps: \(steps)")
        } catch {
            XCTFail("Fetching daily steps should not throw an error, but it threw: \(error)")
        }
    }

    func testFetchRestingHeartRate_DoesNotThrow() async {
        // Given
        let today = Date()
        
        // When
        do {
            let heartRate = try await service.fetchRestingHeartRate(for: today)
            // Then
            // It's okay for heartRate to be nil if there's no data.
            print("Successfully fetched resting heart rate: \(heartRate ?? -1)")
        } catch {
            XCTFail("Fetching resting heart rate should not throw an error, but it threw: \(error)")
        }
    }

    func testFetchSleepAnalysis_DoesNotThrow() async {
        // Given
        let today = Date()
        
        // When
        do {
            let sleepData = try await service.fetchSleepAnalysis(for: today)
            // Then
            if let sleepData = sleepData {
                XCTAssertGreaterThanOrEqual(sleepData.totalTimeInBed, 0)
                XCTAssertGreaterThanOrEqual(sleepData.totalTimeAsleep, 0)
                XCTAssertGreaterThanOrEqual(sleepData.sleepEfficiency, 0)
                XCTAssertLessThanOrEqual(sleepData.sleepEfficiency, 1)
                print("Successfully fetched sleep data: In Bed: \(sleepData.totalTimeInBed/3600)hrs, Asleep: \(sleepData.totalTimeAsleep/3600)hrs")
            } else {
                print("No sleep data available for the specified date.")
            }
        } catch {
            XCTFail("Fetching sleep analysis should not throw an error, but it threw: \(error)")
        }
    }

    func testFetchAllDailyMetrics_DoesNotThrow() async {
        // Given
        let today = Date()
        
        // When
        do {
            let metrics = try await service.fetchAllDailyMetrics(for: today)
            // Then
            XCTAssertNotNil(metrics)
            XCTAssertEqual(metrics.date, today)
            print("Successfully fetched all daily metrics for \(today): Steps: \(metrics.stepCount), RHR: \(metrics.restingHeartRate ?? -1)")
        } catch {
            XCTFail("Fetching all daily metrics should not throw an error, but it threw: \(error)")
        }
    }
} 