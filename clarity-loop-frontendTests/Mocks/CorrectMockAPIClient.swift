import Foundation
@testable import clarity_loop_frontend

// Correct mock that matches the real APIClientProtocol
class MockAPIClient: APIClientProtocol {
    
    // MARK: - Control Properties
    
    var shouldSucceed = true
    var mockError: Error = APIError.unknown("Mock error")
    
    // Mock responses
    var mockInsightHistory = InsightHistoryResponseDTO(
        success: true,
        insights: [],
        pagination: PaginationMetadataDTO(
            currentPage: 1,
            totalPages: 1,
            totalItems: 0,
            itemsPerPage: 10,
            hasNext: false,
            hasPrevious: false
        )
    )
    
    // MARK: - Authentication
    
    func register(requestDTO: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        guard shouldSucceed else { throw mockError }
        return RegistrationResponseDTO(
            userId: UUID(),
            email: requestDTO.email,
            status: "registered",
            verificationEmailSent: true,
            createdAt: Date()
        )
    }
    
    func login(requestDTO: UserLoginRequestDTO) async throws -> LoginResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func refreshToken(requestDTO: RefreshTokenRequestDTO) async throws -> TokenResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func logout() async throws -> MessageResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func getCurrentUser() async throws -> UserSessionResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func verifyEmail(code: String) async throws -> MessageResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    // MARK: - Health Data
    
    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func uploadHealthKitData(requestDTO: HealthKitUploadRequestDTO) async throws -> HealthKitUploadResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func syncHealthKitData(requestDTO: HealthKitSyncRequestDTO) async throws -> HealthKitSyncResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func getHealthKitSyncStatus(syncId: String) async throws -> HealthKitSyncStatusDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func getHealthKitUploadStatus(uploadId: String) async throws -> HealthKitUploadStatusDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func getProcessingStatus(id: UUID) async throws -> HealthDataProcessingStatusDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    // MARK: - Insights
    
    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func generateInsight(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func getInsight(id: String) async throws -> InsightGenerationResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func getInsightsServiceStatus() async throws -> ServiceStatusResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    // MARK: - PAT Analysis
    
    func analyzeStepData(requestDTO: StepDataRequestDTO) async throws -> StepAnalysisResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func analyzeActigraphy(requestDTO: DirectActigraphyRequestDTO) async throws -> ActigraphyAnalysisResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func getPATAnalysis(id: String) async throws -> PATAnalysisResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func getPATServiceHealth() async throws -> ServiceStatusResponseDTO {
        throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
}