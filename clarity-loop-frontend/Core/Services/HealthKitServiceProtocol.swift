//
//  HealthKitServiceProtocol.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation
import HealthKit

/// A protocol that defines the contract for a service that interacts with HealthKit.
/// This abstraction allows for mocking the HealthKit interactions during testing.
protocol HealthKitServiceProtocol {
    
    /// Checks if HealthKit data is available on the current device.
    /// - Returns: A boolean indicating if `HKHealthStore.isHealthDataAvailable()` is true.
    func isHealthDataAvailable() -> Bool
    
    /// Requests authorization from the user to read health data.
    /// - Throws: An error if the authorization request fails.
    func requestAuthorization() async throws
    
    // Methods for fetching specific data types will be added here.
    // e.g., func fetchDailySteps(for date: Date) async throws -> Int
} 