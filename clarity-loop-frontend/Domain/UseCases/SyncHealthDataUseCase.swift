import Foundation
import UIKit

final class SyncHealthDataUseCase {
    
    private let healthKitService: HealthKitServiceProtocol
    private let healthDataRepository: HealthDataRepositoryProtocol
    private let apiClient: APIClientProtocol
    private let authService: AuthServiceProtocol
    
    init(
        healthKitService: HealthKitServiceProtocol,
        healthDataRepository: HealthDataRepositoryProtocol,
        apiClient: APIClientProtocol,
        authService: AuthServiceProtocol
    ) {
        self.healthKitService = healthKitService
        self.healthDataRepository = healthDataRepository
        self.apiClient = apiClient
        self.authService = authService
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
                
                // Upload to backend (direct API call since this is an infrastructure operation)
                let uploadResponse = try await apiClient.uploadHealthKitData(requestDTO: uploadRequest)
                
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
                sampleType: "stepCount",
                value: Double(dailyMetrics.stepCount),
                categoryValue: nil,
                unit: "count",
                startDate: Calendar.current.startOfDay(for: date),
                endDate: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: date)) ?? date,
                metadata: nil,
                sourceRevision: createSourceRevision()
            ))
        }
        
        // Add resting heart rate sample
        if let heartRate = dailyMetrics.restingHeartRate {
            samples.append(HealthKitSampleDTO(
                sampleType: "restingHeartRate",
                value: heartRate,
                categoryValue: nil,
                unit: "bpm",
                startDate: date,
                endDate: date,
                metadata: nil,
                sourceRevision: createSourceRevision()
            ))
        }
        
        // Add sleep data samples
        if let sleepData = dailyMetrics.sleepData {
            // Calculate sleep start/end from total time asleep and time in bed
            let sleepStart = Calendar.current.startOfDay(for: date).addingTimeInterval(22 * 3600) // Assume 10 PM start
            let sleepEnd = sleepStart.addingTimeInterval(sleepData.totalTimeInBed)
            
            samples.append(HealthKitSampleDTO(
                sampleType: "sleepAnalysis",
                value: sleepData.totalTimeAsleep / 60.0, // Convert to minutes
                categoryValue: 1, // HKCategoryValueSleepAnalysis.asleep
                unit: "min",
                startDate: sleepStart,
                endDate: sleepEnd,
                metadata: [
                    "sleep_efficiency": AnyCodable(sleepData.sleepEfficiency),
                    "total_time_in_bed": AnyCodable(sleepData.totalTimeInBed / 60.0)
                ],
                sourceRevision: createSourceRevision()
            ))
        }
        
        // Get current user ID from auth service
        guard let currentUser = authService.currentUser else {
            throw SyncError.userNotAuthenticated
        }
        
        return HealthKitUploadRequestDTO(
            userId: currentUser.uid,
            samples: samples,
            deviceInfo: createDeviceInfo(),
            timestamp: Date()
        )
    }
    
    private func createSourceRevision() -> SourceRevisionDTO {
        return SourceRevisionDTO(
            source: SourceDTO(
                name: "CLARITY Pulse",
                bundleIdentifier: Bundle.main.bundleIdentifier ?? "com.novamindnyc.clarity-loop-frontend"
            ),
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            productType: UIDevice.current.model,
            operatingSystemVersion: UIDevice.current.systemVersion
        )
    }
    
    private func createDeviceInfo() -> DeviceInfoDTO {
        return DeviceInfoDTO(
            deviceModel: UIDevice.current.model,
            systemName: UIDevice.current.systemName,
            systemVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            timeZone: TimeZone.current.identifier
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
    case userNotAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device"
        case .noDataToSync:
            return "No health data available to sync"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .userNotAuthenticated:
            return "User must be authenticated to sync health data"
        }
    }
}