import Foundation
import UIKit

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
        let request = StepDataRequestDTO(
            stepData: stepData,
            startDate: startDate,
            endDate: endDate,
            timezone: TimeZone.current.identifier,
            metadata: [
                "source": AnyCodable("HealthKit"),
                "device_model": AnyCodable(UIDevice.current.model),
                "app_version": AnyCodable(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")
            ]
        )
        
        // Submit for analysis
        let analysisResponse = try await apiClient.analyzeStepData(requestDTO: request)
        
        // Poll for completion if needed
        if analysisResponse.status == "processing" {
            return try await pollForCompletion(analysisId: analysisResponse.analysisId)
        } else {
            return PATAnalysisResult(
                analysisId: analysisResponse.analysisId,
                status: analysisResponse.status,
                patFeatures: analysisResponse.patFeatures,
                confidence: analysisResponse.confidence,
                completedAt: analysisResponse.completedAt,
                error: analysisResponse.error
            )
        }
    }
    
    func executeActigraphyAnalysis(actigraphyData: [ActigraphyDataPointDTO]) async throws -> PATAnalysisResult {
        let request = DirectActigraphyRequestDTO(
            actigraphyData: actigraphyData,
            samplingRate: 30.0, // 30 Hz default
            timezone: TimeZone.current.identifier,
            metadata: [
                "source": AnyCodable("DirectInput"),
                "data_points": AnyCodable(actigraphyData.count)
            ]
        )
        
        let analysisResponse = try await apiClient.analyzeActigraphy(requestDTO: request)
        
        if analysisResponse.status == "processing" {
            return try await pollForCompletion(analysisId: analysisResponse.analysisId)
        } else {
            return PATAnalysisResult(
                analysisId: analysisResponse.analysisId,
                status: analysisResponse.status,
                patFeatures: analysisResponse.patFeatures,
                confidence: analysisResponse.confidence,
                completedAt: analysisResponse.completedAt,
                error: analysisResponse.error
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