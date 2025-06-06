//
//  HealthDataDTOs.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation

// Note: The `AnyCodable` type from the `AnyCodable.swift` file is used here
// to handle dynamic JSON values in metadata fields.

// MARK: - Main Health Metric DTO

struct HealthMetricDTO: Codable, Identifiable {
    var id: UUID { metricId }
    
    let metricId: UUID
    let metricType: String // Consider creating a specific enum for this
    let biometricData: BiometricDataDTO?
    let sleepData: SleepDataDTO?
    let activityData: ActivityDataDTO?
    let mentalHealthData: MentalHealthIndicatorDTO?
    let deviceId: String?
    let rawData: [String: AnyCodable]?
    let metadata: [String: AnyCodable]?
    let createdAt: Date
}

// MARK: - Component DTOs

struct BiometricDataDTO: Codable {
    let heartRate: Double?
    let bloodPressureSystolic: Int?
    let bloodPressureDiastolic: Int?
    let oxygenSaturation: Double?
    let heartRateVariability: Double?
    let respiratoryRate: Double?
    let bodyTemperature: Double?
    let bloodGlucose: Double?
}

struct SleepDataDTO: Codable {
    let totalSleepMinutes: Int
    let sleepEfficiency: Double
    let timeToSleepMinutes: Int?
    let wakeCount: Int?
    let sleepStages: [String: Int]?
    let sleepStart: Date
    let sleepEnd: Date
}

struct ActivityDataDTO: Codable {
    let steps: Int?
    let distance: Double?
    let activeEnergy: Double?
    let exerciseMinutes: Int?
    let flightsClimbed: Int?
    let vo2Max: Double?
    let activeMinutes: Int?
    let restingHeartRate: Double?
}

struct MentalHealthIndicatorDTO: Codable {
    let moodScore: String?
    let stressLevel: Double?
    let anxietyLevel: Double?
    let energyLevel: Double?
    let focusRating: Double?
    let socialInteractionMinutes: Int?
    let meditationMinutes: Int?
    let notes: String?
    let timestamp: Date
}

// MARK: - Pagination DTO

struct PaginatedMetricsResponseDTO: Codable {
    let data: [HealthMetricDTO]
    // Pagination metadata will be added here based on the final API spec.
    // let meta: PaginationMetaDTO
}

// MARK: - Health Data Upload DTOs

struct HealthDataUploadDTO: Codable {
    let userId: UUID
    let metrics: [HealthMetricDTO]
    let uploadSource: String
    let clientTimestamp: Date
    let syncToken: String?
}

struct HealthDataResponseDTO: Codable {
    let processingId: UUID
    let status: String
    let acceptedMetrics: Int
    let rejectedMetrics: Int
    let validationErrors: [ValidationErrorDTO]
    let message: String
    let timestamp: Date
} 