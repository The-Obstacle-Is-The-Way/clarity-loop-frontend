import Foundation
import UIKit
import FirebaseAuth

final class AnalyzePATDataUseCase {
    
    private let apiClient: APIClientProtocol
    private let healthKitService: HealthKitServiceProtocol
    
    init(
        apiClient: APIClientProtocol,
        healthKitService: HealthKitServiceProtocol
    ) {
        self.apiClient = apiClient
        self.healthKitService = healthKitService
    }
    
    func executeStepAnalysis(
        startDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
        endDate: Date = Date()
    ) async throws -> PATAnalysisResult {
        // Fetch step data from HealthKit
        let stepData = try await collectStepData(from: startDate, to: endDate)
        
        // Create request DTO
        let userId = FirebaseAuth.Auth.auth().currentUser?.uid ?? "unknown"
        let request = StepDataRequestDTO(
            userId: userId,
            stepData: stepData,
            analysisType: "comprehensive",
            timeRange: TimeRangeDTO(startDate: startDate, endDate: endDate)
        )
        
        // Submit for analysis
        let analysisResponse = try await apiClient.analyzeStepData(requestDTO: request)
        
        // Poll for completion if needed
        if analysisResponse.status == "processing" {
            return try await pollForCompletion(analysisId: analysisResponse.analysisId)
        } else {
            // Convert step analysis data to generic PAT features
            let patFeatures: [String: AnyCodable]? = analysisResponse.data.map { stepData in
                [
                    "averageStepsPerDay": AnyCodable(stepData.dailyStepPattern.averageStepsPerDay),
                    "consistencyScore": AnyCodable(stepData.dailyStepPattern.consistencyScore),
                    "activityLevel": AnyCodable(stepData.activityInsights.activityLevel),
                    "goalProgress": AnyCodable(stepData.activityInsights.goalProgress),
                    "estimatedCaloriesBurned": AnyCodable(stepData.healthMetrics.estimatedCaloriesBurned)
                ]
            }
            
            return PATAnalysisResult(
                analysisId: analysisResponse.analysisId,
                status: analysisResponse.status,
                patFeatures: patFeatures,
                confidence: nil, // Not available in step analysis
                completedAt: analysisResponse.createdAt, // Using creation date as completion
                error: analysisResponse.message // Using message as error if needed
            )
        }
    }
    
    func executeActigraphyAnalysis(actigraphyData: [ActigraphyDataPointDTO]) async throws -> PATAnalysisResult {
        let userId = FirebaseAuth.Auth.auth().currentUser?.uid ?? "unknown"
        let startDate = actigraphyData.first?.timestamp ?? Date()
        let endDate = actigraphyData.last?.timestamp ?? Date()
        let request = DirectActigraphyRequestDTO(
            userId: userId,
            actigraphyData: actigraphyData,
            analysisType: "comprehensive",
            timeRange: TimeRangeDTO(startDate: startDate, endDate: endDate)
        )
        
        let analysisResponse = try await apiClient.analyzeActigraphy(requestDTO: request)
        
        if analysisResponse.status == "processing" {
            return try await pollForCompletion(analysisId: analysisResponse.analysisId)
        } else {
            // Convert actigraphy analysis data to generic PAT features
            let patFeatures: [String: AnyCodable]? = analysisResponse.data.map { actigraphyData in
                [
                    "totalSleepTime": AnyCodable(actigraphyData.sleepMetrics.totalSleepTime),
                    "sleepEfficiency": AnyCodable(actigraphyData.sleepMetrics.sleepEfficiency),
                    "sleepLatency": AnyCodable(actigraphyData.sleepMetrics.sleepLatency),
                    "dailyActivityScore": AnyCodable(actigraphyData.activityPatterns.dailyActivityScore),
                    "circadianPhase": AnyCodable(actigraphyData.circadianRhythm.phase),
                    "circadianAmplitude": AnyCodable(actigraphyData.circadianRhythm.amplitude)
                ]
            }
            
            return PATAnalysisResult(
                analysisId: analysisResponse.analysisId,
                status: analysisResponse.status,
                patFeatures: patFeatures,
                confidence: nil, // Not available in actigraphy analysis
                completedAt: analysisResponse.createdAt, // Using creation date as completion
                error: analysisResponse.message // Using message as error if needed
            )
        }
    }
    
    func getAnalysisResult(analysisId: String) async throws -> PATAnalysisResponseDTO {
        return try await apiClient.getPATAnalysis(id: analysisId)
    }
    
    // MARK: - Private Methods
    
    private func collectStepData(from startDate: Date, to endDate: Date) async throws -> [StepDataPointDTO] {
        var stepData: [StepDataPointDTO] = []
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            do {
                let steps = try await healthKitService.fetchDailySteps(for: currentDate)
                let timestamp = calendar.startOfDay(for: currentDate)
                
                stepData.append(StepDataPointDTO(
                    timestamp: timestamp,
                    stepCount: Int(steps),
                    source: "HealthKit"
                ))
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            } catch {
                // Skip days with no data
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        return stepData
    }
    
    private func categorizeActivityLevel(steps: Double) -> String {
        switch steps {
        case 0..<1000:
            return "sedentary"
        case 1000..<5000:
            return "low"
        case 5000..<10000:
            return "moderate"
        case 10000..<15000:
            return "high"
        default:
            return "very_high"
        }
    }
    
    private func pollForCompletion(analysisId: String, maxAttempts: Int = 30, delaySeconds: UInt64 = 10) async throws -> PATAnalysisResult {
        for attempt in 1...maxAttempts {
            let response = try await apiClient.getPATAnalysis(id: analysisId)
            
            if response.status == "completed" || response.status == "failed" {
                return PATAnalysisResult(
                    analysisId: response.analysisId,
                    status: response.status,
                    patFeatures: response.patFeatures,
                    confidence: response.confidence,
                    completedAt: response.completedAt,
                    error: response.error
                )
            }
            
            if attempt < maxAttempts {
                try await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
            }
        }
        
        throw PATAnalysisError.analysisTimeout
    }
}

struct PATAnalysisResult {
    let analysisId: String
    let status: String
    let patFeatures: [String: AnyCodable]?
    let confidence: Double?
    let completedAt: Date?
    let error: String?
    
    var isCompleted: Bool {
        return status == "completed"
    }
    
    var isFailed: Bool {
        return status == "failed"
    }
    
    var isProcessing: Bool {
        return status == "processing"
    }
}

enum PATAnalysisError: LocalizedError {
    case analysisTimeout
    case invalidData
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .analysisTimeout:
            return "PAT analysis timed out. Please try again later."
        case .invalidData:
            return "The provided data is invalid for PAT analysis."
        case .serviceUnavailable:
            return "PAT analysis service is currently unavailable."
        }
    }
}