import XCTest
import FirebaseAuth
@testable import clarity_loop_frontend

/// Integration tests to verify our vertical slices work end-to-end
@MainActor
final class IntegrationTests: XCTestCase {
    
    var apiClient: MockAPIClient!
    var authService: MockAuthService!
    var healthKitService: HealthKitService!
    var insightsRepository: RemoteInsightsRepository!
    
    override func setUp() {
        super.setUp()
        apiClient = MockAPIClient()
        authService = MockAuthService(apiClient: apiClient)
        healthKitService = HealthKitService(apiClient: apiClient)
        insightsRepository = RemoteInsightsRepository(apiClient: apiClient)
    }
    
    override func tearDown() {
        apiClient = nil
        authService = nil
        healthKitService = nil
        insightsRepository = nil
        super.tearDown()
    }
    
    /// Test that the authentication slice works end-to-end
    func testAuthenticationSlice() async throws {
        // Given
        let registrationRequest = UserRegistrationRequestDTO(
            email: "test@example.com",
            password: "password123",
            firstName: "Test",
            lastName: "User",
            phoneNumber: nil,
            termsAccepted: true,
            privacyPolicyAccepted: true
        )
        
        // When
        let response = try await authService.register(
            withEmail: registrationRequest.email,
            password: registrationRequest.password,
            details: registrationRequest
        )
        
        // Then
        XCTAssertEqual(response.email, "test@example.com")
        XCTAssertTrue(response.verificationEmailSent)
    }
    
    /// Test that the health data slice works end-to-end
    func testHealthDataSlice() async throws {
        // Given
        let uploadRequest = HealthKitUploadRequestDTO(
            userId: "test-user",
            samples: [
                HealthKitSampleDTO(
                    sampleType: "stepCount",
                    value: 1000,
                    categoryValue: nil,
                    unit: "count",
                    startDate: Date(),
                    endDate: Date(),
                    metadata: nil,
                    sourceRevision: nil
                )
            ],
            deviceInfo: nil,
            timestamp: Date()
        )
        
        // When
        let response = try await healthKitService.uploadHealthKitData(uploadRequest)
        
        // Then
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.processedSamples, 1)
    }
    
    /// Test that the insights slice works end-to-end
    func testInsightsSlice() async throws {
        // Given
        let userId = "test-user"
        
        // When
        let response = try await insightsRepository.getInsightHistory(
            userId: userId,
            limit: 10,
            offset: 0
        )
        
        // Then
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.data.insights.count, 0) // Mock returns empty
    }
}

/// Mock Auth Service for testing
class MockAuthService: AuthServiceProtocol {
    private let apiClient: APIClientProtocol
    private var _currentUser: FirebaseAuth.User?
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    var authState: AsyncStream<FirebaseAuth.User?> {
        AsyncStream { continuation in
            continuation.yield(_currentUser)
            continuation.finish()
        }
    }
    
    var currentUser: FirebaseAuth.User? {
        _currentUser
    }
    
    func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO {
        let loginDTO = UserLoginRequestDTO(email: email, password: password, rememberMe: true, deviceInfo: nil)
        let response = try await apiClient.login(requestDTO: loginDTO)
        return response.user
    }
    
    func register(withEmail email: String, password: String, details: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        let response = try await apiClient.register(requestDTO: details)
        return response
    }
    
    func signOut() throws {
        _currentUser = nil
    }
    
    func sendPasswordReset(to email: String) async throws {
        // Mock implementation - do nothing
    }
    
    func getCurrentUserToken() async throws -> String {
        return "mock-token"
    }
}

/// Mock API client for testing
class MockAPIClient: APIClientProtocol {
    
    func register(requestDTO: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        return RegistrationResponseDTO(
            userId: UUID(),
            email: requestDTO.email,
            status: "pending_verification",
            verificationEmailSent: true,
            createdAt: Date()
        )
    }
    
    func login(requestDTO: UserLoginRequestDTO) async throws -> LoginResponseDTO {
        let userSession = UserSessionResponseDTO(
            userId: UUID(),
            firstName: "Test",
            lastName: "User",
            email: requestDTO.email,
            role: "user",
            permissions: [],
            status: "active",
            mfaEnabled: false,
            emailVerified: true,
            createdAt: Date(),
            lastLogin: Date()
        )
        
        let tokens = TokenResponseDTO(
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token",
            tokenType: "Bearer",
            expiresIn: 3600
        )
        
        return LoginResponseDTO(user: userSession, tokens: tokens)
    }
    
    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO {
        return PaginatedMetricsResponseDTO(data: [])
    }
    
    func uploadHealthKitData(requestDTO: HealthKitUploadRequestDTO) async throws -> HealthKitUploadResponseDTO {
        return HealthKitUploadResponseDTO(
            success: true,
            uploadId: "mock-upload-id",
            processedSamples: requestDTO.samples.count,
            skippedSamples: 0,
            errors: nil,
            message: "Mock upload successful"
        )
    }
    
    func syncHealthKitData(requestDTO: HealthKitSyncRequestDTO) async throws -> HealthKitSyncResponseDTO {
        return HealthKitSyncResponseDTO(
            success: true,
            syncId: "mock-sync-id",
            status: "completed",
            estimatedDuration: nil,
            message: "Mock sync successful"
        )
    }
    
    func getHealthKitSyncStatus(syncId: String) async throws -> HealthKitSyncStatusDTO {
        return HealthKitSyncStatusDTO(
            syncId: syncId,
            status: "completed",
            progress: 1.0,
            processedSamples: 100,
            totalSamples: 100,
            errors: nil,
            completedAt: Date()
        )
    }
    
    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO {
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
    }
    
    func generateInsight(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO {
        let insight = HealthInsightDTO(
            userId: "test-user",
            narrative: "Mock insight narrative",
            keyInsights: ["Mock insight 1", "Mock insight 2"],
            recommendations: ["Mock recommendation 1"],
            confidenceScore: 0.85,
            generatedAt: Date()
        )
        
        return InsightGenerationResponseDTO(
            success: true,
            data: insight,
            metadata: nil
        )
    }
}