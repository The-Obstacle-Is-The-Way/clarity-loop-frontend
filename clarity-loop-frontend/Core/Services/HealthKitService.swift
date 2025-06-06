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
        
        let query = HKStatisticsQuery(
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
            stepCount: stepCount,
            restingHeartRate: restingHeartRate,
            sleepData: sleepData
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
