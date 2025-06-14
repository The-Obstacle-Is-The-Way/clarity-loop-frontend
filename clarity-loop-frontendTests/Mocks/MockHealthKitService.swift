import Foundation
import HealthKit
@testable import clarity_loop_frontend

class MockHealthKitService: HealthKitServiceProtocol {
    var shouldSucceed = true
    var mockDailyMetrics: DailyHealthMetrics?
    var mockStepCount: Double = 5000.0
    var mockRestingHeartRate: Double? = 72.0
    var mockSleepData: SleepData? = SleepData(
        totalTimeInBed: 28800,    // 8 hours
        totalTimeAsleep: 25200,   // 7 hours
        sleepEfficiency: 0.875    // 87.5%
    )
    
    func isHealthDataAvailable() -> Bool {
        return shouldSucceed
    }
    
    func requestAuthorization() async throws {
        if !shouldSucceed {
            throw HealthKitError.dataTypeNotAvailable
        }
    }
    
    func fetchDailySteps(for date: Date) async throws -> Double {
        if !shouldSucceed {
            throw HealthKitError.dataTypeNotAvailable
        }
        return mockStepCount
    }
    
    func fetchRestingHeartRate(for date: Date) async throws -> Double? {
        if !shouldSucceed {
            throw HealthKitError.dataTypeNotAvailable
        }
        return mockRestingHeartRate
    }
    
    func fetchSleepAnalysis(for date: Date) async throws -> SleepData? {
        if !shouldSucceed {
            throw HealthKitError.dataTypeNotAvailable
        }
        return mockSleepData
    }
    
    func fetchAllDailyMetrics(for date: Date) async throws -> DailyHealthMetrics {
        if !shouldSucceed {
            throw HealthKitError.dataTypeNotAvailable
        }
        
        if let mockMetrics = mockDailyMetrics {
            return mockMetrics
        }
        
        return DailyHealthMetrics(
            date: date,
            stepCount: Int(mockStepCount),
            restingHeartRate: mockRestingHeartRate,
            sleepData: mockSleepData
        )
    }
    
    func uploadHealthKitData(_ uploadRequest: HealthKitUploadRequestDTO) async throws -> HealthKitUploadResponseDTO {
        if !shouldSucceed {
            throw APIError.serverError(statusCode: 500, message: "Mock upload failed")
        }
        
        return HealthKitUploadResponseDTO(
            success: true,
            uploadId: "mock-upload-id",
            processedSamples: uploadRequest.samples.count,
            skippedSamples: 0,
            errors: nil,
            message: "Mock upload successful"
        )
    }
    
    func enableBackgroundDelivery() async throws {
        if !shouldSucceed {
            throw HealthKitError.dataTypeNotAvailable
        }
    }
    
    func disableBackgroundDelivery() async throws {
        if !shouldSucceed {
            throw HealthKitError.dataTypeNotAvailable
        }
    }
    
    func setupObserverQueries() {
        // Mock implementation - no-op
    }
}