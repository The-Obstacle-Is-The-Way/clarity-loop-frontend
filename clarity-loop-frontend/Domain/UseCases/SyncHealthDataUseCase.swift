import Foundation

final class SyncHealthDataUseCase {
    
    private let healthKitService: HealthKitServiceProtocol
    private let healthDataRepository: HealthDataRepositoryProtocol
    
    init(
        healthKitService: HealthKitServiceProtocol,
        healthDataRepository: HealthDataRepositoryProtocol
    ) {
        self.healthKitService = healthKitService
        self.healthDataRepository = healthDataRepository
    }
    
    func execute(
        startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
        endDate: Date = Date()
    ) async throws -> SyncResult {
        guard healthKitService.isHealthDataAvailable() else {
            throw SyncError.healthKitNotAvailable
        }
        
        var syncResult = SyncResult()
        
        // Iterate through each day in the date range
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            do {
                // Fetch data for this specific day
                let dailyMetrics = try await healthKitService.fetchAllDailyMetrics(for: currentDate)
                
                // Convert to HealthKit upload format
                let uploadRequest = try buildUploadRequest(from: dailyMetrics, date: currentDate)
                
                // Upload to backend
                let uploadResponse = try await healthDataRepository.uploadHealthKitData(requestDTO: uploadRequest)
                
                syncResult.successfulDays += 1
                syncResult.uploadedSamples += uploadResponse.processedSamples
                
                if let errors = uploadResponse.errors, !errors.isEmpty {
                    syncResult.errors.append(contentsOf: errors)
                }
                
            } catch {
                syncResult.errors.append("Failed to sync data for \(currentDate.formatted()): \(error.localizedDescription)")
                syncResult.failedDays += 1
            }
            
            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        syncResult.isSuccess = syncResult.failedDays == 0
        return syncResult
    }
    
    private func buildUploadRequest(from dailyMetrics: DailyHealthMetrics, date: Date) throws -> HealthKitUploadRequestDTO {
        var samples: [HealthKitSampleDTO] = []
        
        // Add step count sample
        if dailyMetrics.stepCount > 0 {
            samples.append(HealthKitSampleDTO(
                identifier: "HKQuantityTypeIdentifierStepCount",
                value: Double(dailyMetrics.stepCount),
                unit: "count",
                startDate: Calendar.current.startOfDay(for: date),
                endDate: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: date)) ?? date,
                metadata: nil
            ))
        }
        
        // Add resting heart rate sample
        if let heartRate = dailyMetrics.restingHeartRate {
            samples.append(HealthKitSampleDTO(
                identifier: "HKQuantityTypeIdentifierRestingHeartRate",
                value: heartRate,
                unit: "bpm",
                startDate: date,
                endDate: date,
                metadata: nil
            ))
        }
        
        // Add sleep data samples
        if let sleepData = dailyMetrics.sleepData {
            samples.append(HealthKitSampleDTO(
                identifier: "HKCategoryTypeIdentifierSleepAnalysis",
                value: Double(sleepData.totalSleepMinutes),
                unit: "min",
                startDate: sleepData.sleepStart,
                endDate: sleepData.sleepEnd,
                metadata: [
                    "sleep_efficiency": AnyCodable(sleepData.sleepEfficiency),
                    "time_to_sleep_minutes": AnyCodable(sleepData.timeToSleepMinutes)
                ]
            ))
        }
        
        return HealthKitUploadRequestDTO(
            samples: samples,
            uploadSource: "iOS_HealthKit",
            clientTimestamp: Date(),
            syncToken: UUID().uuidString
        )
    }
}

struct SyncResult {
    var successfulDays: Int = 0
    var failedDays: Int = 0
    var uploadedSamples: Int = 0
    var errors: [String] = []
    var isSuccess: Bool = false
    
    var totalDays: Int {
        return successfulDays + failedDays
    }
    
    var successRate: Double {
        guard totalDays > 0 else { return 0.0 }
        return Double(successfulDays) / Double(totalDays)
    }
}

enum SyncError: LocalizedError {
    case healthKitNotAvailable
    case noDataToSync
    case uploadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device"
        case .noDataToSync:
            return "No health data available to sync"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        }
    }
}