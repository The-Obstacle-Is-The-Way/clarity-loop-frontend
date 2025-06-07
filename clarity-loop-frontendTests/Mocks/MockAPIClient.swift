import Foundation
@testable import clarity_loop_frontend

class MockAPIClient: APIClientProtocol {
    var shouldSucceed = true
    var mockUserSession = UserSessionResponseDTO(
        userId: UUID(),
        firstName: "Test",
        lastName: "User",
        email: "test@example.com",
        role: "user",
        permissions: [],
        status: "active",
        mfaEnabled: false,
        emailVerified: true,
        createdAt: Date(),
        lastLogin: Date()
    )
    
    // MARK: - Authentication Methods
    
    func register(requestDTO: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        if shouldSucceed {
            return RegistrationResponseDTO(
                userId: UUID(),
                email: requestDTO.email,
                status: "pending_verification",
                verificationEmailSent: true,
                createdAt: Date()
            )
        } else {
            throw APIError.serverError(statusCode: 400, message: "Registration failed")
        }
    }
    
    func login(requestDTO: UserLoginRequestDTO) async throws -> LoginResponseDTO {
        if shouldSucceed {
            return LoginResponseDTO(
                user: mockUserSession,
                tokens: TokenResponseDTO(
                    accessToken: "mock-access-token",
                    refreshToken: "mock-refresh-token",
                    tokenType: "Bearer",
                    expiresIn: 3600
                )
            )
        } else {
            throw APIError.unauthorized
        }
    }
    
    // MARK: - Health Data Methods
    
    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO {
        if shouldSucceed {
            return PaginatedMetricsResponseDTO(
                data: []
            )
        } else {
            throw APIError.serverError(statusCode: 500, message: "Failed to fetch health data")
        }
    }
    
    func uploadHealthKitData(requestDTO: HealthKitUploadRequestDTO) async throws -> HealthKitUploadResponseDTO {
        if shouldSucceed {
            return HealthKitUploadResponseDTO(
                success: true,
                uploadId: "mock-upload-id",
                processedSamples: 0,
                skippedSamples: 0,
                errors: nil,
                message: "Upload successful"
            )
        } else {
            throw APIError.serverError(statusCode: 500, message: "Upload failed")
        }
    }
    
    func syncHealthKitData(requestDTO: HealthKitSyncRequestDTO) async throws -> HealthKitSyncResponseDTO {
        if shouldSucceed {
            return HealthKitSyncResponseDTO(
                success: true,
                syncId: "mock-sync-id",
                status: "in_progress",
                estimatedDuration: 60.0,
                message: "Sync started"
            )
        } else {
            throw APIError.serverError(statusCode: 500, message: "Sync failed")
        }
    }
    
    func getHealthKitSyncStatus(syncId: String) async throws -> HealthKitSyncStatusDTO {
        if shouldSucceed {
            return HealthKitSyncStatusDTO(
                syncId: syncId,
                status: "completed",
                progress: 1.0,
                processedSamples: 100,
                totalSamples: 100,
                errors: nil,
                completedAt: Date()
            )
        } else {
            throw APIError.serverError(statusCode: 404, message: "Sync not found")
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
                    pagination: PaginationMetaDTO(
                        page: offset / limit + 1,
                        limit: limit
                    )
                ),
                metadata: nil
            )
        } else {
            throw APIError.serverError(statusCode: 500, message: "Failed to fetch insights")
        }
    }
    
    func generateInsight(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO {
        if shouldSucceed {
            return InsightGenerationResponseDTO(
                success: true,
                data: HealthInsightDTO(
                    userId: "mock-user-id",
                    narrative: "Mock insight content",
                    keyInsights: ["Key insight 1"],
                    recommendations: ["Recommendation 1"],
                    confidenceScore: 0.85,
                    generatedAt: Date()
                ),
                metadata: nil
            )
        } else {
            throw APIError.serverError(statusCode: 500, message: "Failed to generate insight")
        }
    }
} 