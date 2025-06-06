//
//  HealthKitDomainModels.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation

/// A custom domain model to represent processed sleep analysis data.
struct SleepData {
    let totalTimeInBed: TimeInterval
    let totalTimeAsleep: TimeInterval
    let sleepEfficiency: Double
    
    // We can add more detailed stage analysis here later.
    // let timeInDeepSleep: TimeInterval
    // let timeInCoreSleep: TimeInterval
    // let timeInREMSleep: TimeInterval
}

/// A container for all the daily health metrics fetched from HealthKit.
struct DailyHealthMetrics {
    let date: Date
    let stepCount: Double
    let restingHeartRate: Double?
    let sleepData: SleepData?
    
    // Add other metrics as they are implemented
} 
