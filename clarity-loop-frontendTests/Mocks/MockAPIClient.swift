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
    
    func refreshToken(requestDTO: RefreshTokenRequestDTO) async throws -> TokenResponseDTO {
        if shouldSucceed {
            return TokenResponseDTO(
                accessToken: "mock-refreshed-access-token",
                refreshToken: "mock-refreshed-refresh-token",
                tokenType: "Bearer",
                expiresIn: 3600
            )
        } else {
            throw APIError.unauthorized
        }
    }
    
    func logout() async throws -> MessageResponseDTO {
        if shouldSucceed {
            return MessageResponseDTO(message: "Successfully logged out")
        } else {
            throw APIError.serverError(statusCode: 500, message: "Logout failed")
        }
    }
    
    func getCurrentUser() async throws -> UserSessionResponseDTO {
        if shouldSucceed {
            return mockUserSession
        } else {
            throw APIError.unauthorized
        }
    }
    
    func verifyEmail(code: String) async throws -> MessageResponseDTO {
        if shouldSucceed {
            return MessageResponseDTO(message: "Email verified successfully")
        } else {
            throw APIError.serverError(statusCode: 400, message: "Invalid verification code")
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
    
    func getHealthKitUploadStatus(uploadId: String) async throws -> HealthKitUploadStatusDTO {
        if shouldSucceed {
            return HealthKitUploadStatusDTO(
                uploadId: uploadId,
                status: "completed",
                progress: 1.0,
                processedSamples: 100,
                totalSamples: 100,
                errors: nil,
                completedAt: Date(),
                message: "Upload completed successfully"
            )
        } else {
            throw APIError.serverError(statusCode: 404, message: "Upload status not found")
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
                    keyInsights: ["Key insight 1", "Key insight 2"],
                    recommendations: ["Recommendation 1", "Recommendation 2"],
                    confidenceScore: 0.85,
                    generatedAt: Date()
                ),
                metadata: nil
            )
        } else {
            throw APIError.serverError(statusCode: 500, message: "Failed to generate insight")
        }
    }
    
    func getInsight(id: String) async throws -> InsightGenerationResponseDTO {
        if shouldSucceed {
            return InsightGenerationResponseDTO(
                success: true,
                data: HealthInsightDTO(
                    userId: "mock-user-id",
                    narrative: "Mock insight content for ID: \(id)",
                    keyInsights: ["Key insight 1", "Key insight 2"],
                    recommendations: ["Recommendation 1", "Recommendation 2"],
                    confidenceScore: 0.85,
                    generatedAt: Date()
                ),
                metadata: nil
            )
        } else {
            throw APIError.serverError(statusCode: 404, message: "Insight not found")
        }
    }
    
    func getInsightsServiceStatus() async throws -> ServiceStatusResponseDTO {
        if shouldSucceed {
            return ServiceStatusResponseDTO(
                success: true,
                data: ServiceStatusDataDTO(
                    service: "insights-service",
                    status: "healthy",
                    modelInfo: ModelInfoDTO(
                        modelName: "test-model",
                        projectId: "test-project",
                        initialized: true,
                        capabilities: ["insights", "recommendations"]
                    ),
                    timestamp: Date(),
                    uptime: 86400,
                    version: "1.0.0"
                ),
                metadata: nil
            )
        } else {
            throw APIError.serverError(statusCode: 503, message: "Service unavailable")
        }
    }
    
    // MARK: - Processing Status Methods
    
    func getProcessingStatus(id: UUID) async throws -> HealthDataProcessingStatusDTO {
        if shouldSucceed {
            return HealthDataProcessingStatusDTO(
                processingId: id,
                status: "completed",
                progress: 1.0,
                processedMetrics: 100,
                totalMetrics: 100,
                estimatedTimeRemaining: nil,
                completedAt: Date(),
                errors: nil,
                message: "Processing completed successfully"
            )
        } else {
            throw APIError.serverError(statusCode: 404, message: "Processing not found")
        }
    }
    
    // MARK: - PAT Analysis Methods
    
    func analyzeStepData(requestDTO: StepDataRequestDTO) async throws -> StepAnalysisResponseDTO {
        if shouldSucceed {
            return StepAnalysisResponseDTO(
                success: true,
                data: StepAnalysisDTO(
                    dailyStepPattern: DailyStepPatternDTO(
                        averageStepsPerDay: 8000,
                        peakActivityHours: [9, 15],
                        consistencyScore: 0.8,
                        trendsOverTime: ["Increasing activity"]
                    ),
                    activityInsights: ActivityInsightsDTO(
                        activityLevel: "Moderate",
                        goalProgress: 0.85,
                        improvementAreas: ["Evening activity"],
                        strengths: ["Consistent morning activity"]
                    ),
                    healthMetrics: StepHealthMetricsDTO(
                        estimatedCaloriesBurned: 400,
                        activeMinutesPerDay: 60,
                        sedentaryTimePercentage: 0.6
                    ),
                    recommendations: ["Increase evening activity"]
                ),
                analysisId: "mock-step-analysis-id",
                status: "completed",
                message: "Analysis completed",
                estimatedCompletionTime: nil,
                createdAt: Date()
            )
        } else {
            throw APIError.serverError(statusCode: 500, message: "Step analysis failed")
        }
    }
    
    func analyzeActigraphy(requestDTO: DirectActigraphyRequestDTO) async throws -> ActigraphyAnalysisResponseDTO {
        if shouldSucceed {
            return ActigraphyAnalysisResponseDTO(
                success: true,
                data: ActigraphyAnalysisDTO(
                    sleepMetrics: SleepMetricsDTO(
                        totalSleepTime: 480,
                        sleepEfficiency: 0.85,
                        sleepLatency: 15,
                        wakeAfterSleepOnset: 30,
                        numberOfAwakenings: 3,
                        sleepStages: ["Light", "Deep", "REM"]
                    ),
                    activityPatterns: ActivityPatternsDTO(
                        dailyActivityScore: 0.8,
                        peakActivityTime: "14:00",
                        restPeriods: [],
                        activityVariability: 0.6
                    ),
                    circadianRhythm: CircadianRhythmDTO(
                        phase: 0.2,
                        amplitude: 0.8,
                        stability: 0.9,
                        regularity: 0.85,
                        recommendations: ["Maintain consistent sleep schedule"]
                    ),
                    recommendations: ["Reduce screen time before bed"]
                ),
                analysisId: "mock-actigraphy-analysis-id",
                status: "completed",
                message: "Analysis completed",
                estimatedCompletionTime: nil,
                createdAt: Date()
            )
        } else {
            throw APIError.serverError(statusCode: 500, message: "Actigraphy analysis failed")
        }
    }
    
    func getPATAnalysis(id: String) async throws -> PATAnalysisResponseDTO {
        if shouldSucceed {
            return PATAnalysisResponseDTO(
                id: id,
                status: "completed",
                patFeatures: [
                    "sleep_efficiency": 0.85,
                    "total_sleep_time": 480,
                    "step_count": 8000
                ],
                analysis: PATAnalysisDataDTO(
                    sleepStages: ["Light", "Deep", "REM"],
                    clinicalInsights: ["Good sleep efficiency"],
                    confidenceScore: 0.85,
                    sleepEfficiency: 0.85,
                    totalSleepTime: 480,
                    wakeAfterSleepOnset: 30,
                    sleepLatency: 15
                ),
                errorMessage: nil,
                createdAt: Date(),
                completedAt: Date()
            )
        } else {
            throw APIError.serverError(statusCode: 404, message: "PAT analysis not found")
        }
    }
    
    func getPATServiceHealth() async throws -> ServiceStatusResponseDTO {
        if shouldSucceed {
            return ServiceStatusResponseDTO(
                success: true,
                data: ServiceStatusDataDTO(
                    service: "pat-analysis-service",
                    status: "healthy",
                    modelInfo: ModelInfoDTO(
                        modelName: "pat-model",
                        projectId: "pat-project",
                        initialized: true,
                        capabilities: ["pat-analysis", "sleep-analysis"]
                    ),
                    timestamp: Date(),
                    uptime: 86400,
                    version: "1.0.0"
                ),
                metadata: nil
            )
        } else {
            throw APIError.serverError(statusCode: 503, message: "PAT service unavailable")
        }
    }
} 