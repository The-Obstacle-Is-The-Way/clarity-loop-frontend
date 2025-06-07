import Foundation
@testable import clarity_loop_frontend

/// Centralized mock API client for all tests
/// Eliminates duplicate MockAPIClient classes across test files
class MockAPIClient: APIClientProtocol {
    
    // MARK: - Mock Control Properties
    var shouldSucceed = true
    var mockError: APIError = .serverError(statusCode: 500, message: "Mock error")
    
    // MARK: - Mock Response Data
    var mockRegistrationResponse: RegistrationResponseDTO?
    var mockLoginResponse: LoginResponseDTO?
    var mockHealthDataResponse: PaginatedMetricsResponseDTO?
    var mockHealthKitUploadResponse: HealthKitUploadResponseDTO?
    var mockHealthKitSyncResponse: HealthKitSyncResponseDTO?
    var mockHealthKitSyncStatusResponse: HealthKitSyncStatusDTO?
    var mockInsightHistoryResponse: InsightHistoryResponseDTO?
    var mockGenerateInsightResponse: InsightGenerationResponseDTO?
    
    // MARK: - Authentication Methods
    func register(requestDTO: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        if shouldSucceed {
            // Return a simple mock response - we'll fix the DTO structure later
            throw APIError.notImplemented
        } else {
            throw mockError
        }
    }
    
    func login(requestDTO: UserLoginRequestDTO) async throws -> LoginResponseDTO {
        if shouldSucceed {
            // Return a simple mock response - we'll fix the DTO structure later
            throw APIError.notImplemented
        } else {
            throw mockError
        }
    }
    
    // MARK: - Health Data Methods
    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO {
        if shouldSucceed {
            // Return a simple mock response with empty data
            return PaginatedMetricsResponseDTO(data: [])
        } else {
            throw mockError
        }
    }
    
    func uploadHealthKitData(requestDTO: HealthKitUploadRequestDTO) async throws -> HealthKitUploadResponseDTO {
        if shouldSucceed {
            return HealthKitUploadResponseDTO(
                success: true,
                uploadId: "mock-upload-id",
                processedSamples: 1,
                skippedSamples: 0,
                errors: nil,
                message: "Upload successful"
            )
        } else {
            throw mockError
        }
    }
    
    func syncHealthKitData(requestDTO: HealthKitSyncRequestDTO) async throws -> HealthKitSyncResponseDTO {
        if shouldSucceed {
            return HealthKitSyncResponseDTO(
                success: true,
                syncId: "mock-sync-id",
                status: "completed",
                estimatedDuration: 60.0,
                message: "Sync successful"
            )
        } else {
            throw mockError
        }
    }
    
    func getHealthKitSyncStatus(syncId: String) async throws -> HealthKitSyncStatusDTO {
        if shouldSucceed {
            return HealthKitSyncStatusDTO(
                syncId: syncId,
                status: "completed",
                progress: 100.0,
                processedSamples: 100,
                totalSamples: 100,
                errors: nil,
                completedAt: Date()
            )
        } else {
            throw mockError
        }
    }
    
    // MARK: - Insights Methods
    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO {
        if shouldSucceed {
            return InsightHistoryResponseDTO(
                success: true,
                data: InsightHistoryDataDTO(
                    insights: [],
                    totalCount: 0,
                    hasMore: false,
                    pagination: nil
                ),
                metadata: nil
            )
        } else {
            throw mockError
        }
    }
    
    func generateInsight(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO {
        if shouldSucceed {
            return InsightGenerationResponseDTO(
                success: true,
                data: InsightGenerationDataDTO(
                    insight: InsightPreviewDTO(
                        id: "mock-insight-id",
                        narrative: "Mock insight narrative",
                        generatedAt: Date(),
                        confidenceScore: 0.9,
                        keyInsightsCount: 1,
                        recommendationsCount: 1
                    )
                ),
                metadata: [:]
            )
        } else {
            throw mockError
        }
    }
} 