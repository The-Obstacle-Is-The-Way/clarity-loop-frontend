//
//  HealthKitService.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation
import HealthKit

class HealthKitService: HealthKitServiceProtocol {
    
    private let healthStore = HKHealthStore()
    private let apiClient: APIClientProtocol
    private var offlineQueueManager: OfflineQueueManagerProtocol?
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func setOfflineQueueManager(_ manager: OfflineQueueManagerProtocol) {
        self.offlineQueueManager = manager
    }
    
    /// The set of `HKObjectType`s the app will request permission to read.
    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        
        let identifiers: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .heartRate,
            .restingHeartRate,
            .heartRateVariabilitySDNN,
            .oxygenSaturation,
            .respiratoryRate,
        ]
        
        for identifier in identifiers {
            if let type = HKQuantityType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }
        
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        
        return types
    }
    
    func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async throws {
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }
    
    func fetchDailySteps(for date: Date) async throws -> Double {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.dataTypeNotAvailable
        }
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.endOfDay(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        _ = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, _, _ in
            // This part is tricky to wrap in an async call, let's do it properly.
        }
        
        // The above is just a placeholder, here's the real implementation using a continuation.
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sum = result?.sumQuantity() else {
                    // If there's no data, return 0 steps.
                    continuation.resume(returning: 0.0)
                    return
                }
                
                let steps = sum.doubleValue(for: .count())
                continuation.resume(returning: steps)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchRestingHeartRate(for date: Date) async throws -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            throw HealthKitError.dataTypeNotAvailable
        }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.endOfDay(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: heartRate)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchSleepAnalysis(for date: Date) async throws -> SleepData? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.dataTypeNotAvailable
        }
        
        // Predicate for the previous night (e.g., from noon yesterday to noon today)
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: date)
        guard let startDate = calendar.date(byAdding: .hour, value: -12, to: endDate) else {
            return nil
        }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let totalTimeInBed = samples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                
                let totalTimeAsleep = samples.filter {
                    $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                    $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                    $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                    $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                }.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                
                let sleepEfficiency = totalTimeInBed > 0 ? (totalTimeAsleep / totalTimeInBed) : 0
                
                let sleepData = SleepData(
                    totalTimeInBed: totalTimeInBed,
                    totalTimeAsleep: totalTimeAsleep,
                    sleepEfficiency: sleepEfficiency
                )
                
                continuation.resume(returning: sleepData)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchAllDailyMetrics(for date: Date) async throws -> DailyHealthMetrics {
        async let steps = fetchDailySteps(for: date)
        async let heartRate = fetchRestingHeartRate(for: date)
        async let sleep = fetchSleepAnalysis(for: date)
        
        let (stepCount, restingHeartRate, sleepData) = try await (steps, heartRate, sleep)
        
        return DailyHealthMetrics(
            date: date,
            stepCount: Int(stepCount),
            restingHeartRate: restingHeartRate,
            sleepData: sleepData
        )
    }
    
    func uploadHealthKitData(_ uploadRequest: HealthKitUploadRequestDTO) async throws -> HealthKitUploadResponseDTO {
        do {
            return try await apiClient.uploadHealthKitData(requestDTO: uploadRequest)
        } catch {
            // If the upload fails due to network issues, queue it for later
            if let apiError = error as? APIError,
               case .networkError = apiError,
               let queueManager = offlineQueueManager {
                let queuedUpload = try uploadRequest.toQueuedUpload()
                try await queueManager.enqueue(queuedUpload)
                
                // Return a placeholder response indicating the upload was queued
                return HealthKitUploadResponseDTO(
                    success: true,
                    uploadId: queuedUpload.id.uuidString,
                    processedSamples: uploadRequest.samples.count,
                    skippedSamples: 0,
                    errors: nil,
                    message: "Upload queued for offline processing"
                )
            }
            throw error
        }
    }
    
    // MARK: - Background Delivery
    
    func enableBackgroundDelivery() async throws {
        for dataType in readTypes {
            guard let quantityType = dataType as? HKQuantityType else { continue }
            
            return try await withCheckedThrowingContinuation { continuation in
                healthStore.enableBackgroundDelivery(for: quantityType, frequency: .hourly) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    func disableBackgroundDelivery() async throws {
        for dataType in readTypes {
            guard let quantityType = dataType as? HKQuantityType else { continue }
            
            return try await withCheckedThrowingContinuation { continuation in
                healthStore.disableBackgroundDelivery(for: quantityType) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    func setupObserverQueries() {
        for dataType in readTypes {
            // Only create observer queries for sample types (not category types)
            guard let sampleType = dataType as? HKSampleType else { continue }
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] query, completionHandler, error in
                if let error = error {
                    print("Observer query error: \(error)")
                    return
                }
                
                // Schedule background task for data sync
                self?.scheduleBackgroundSync(for: sampleType)
                
                // Call completion handler to indicate we've handled the update
                completionHandler()
            }
            
            healthStore.execute(query)
        }
    }
    
    private func scheduleBackgroundSync(for dataType: HKObjectType) {
        // Post notification that can be observed by the app
        NotificationCenter.default.post(
            name: .healthKitDataUpdated,
            object: nil,
            userInfo: ["dataType": dataType.identifier]
        )
    }
}

enum HealthKitError: Error {
    case dataTypeNotAvailable
}

extension Calendar {
    func endOfDay(for date: Date) -> Date {
        let start = startOfDay(for: date)
        guard let endOfDay = self.date(byAdding: .init(day: 1, second: -1), to: start) else {
            // This fallback is unlikely to be hit with valid dates, but it's safer than force unwrapping.
            return start.addingTimeInterval(86399) // 24 hours minus 1 second
        }
        return endOfDay
    }
}

extension Notification.Name {
    static let healthKitDataUpdated = Notification.Name("healthKitDataUpdated")
} 
