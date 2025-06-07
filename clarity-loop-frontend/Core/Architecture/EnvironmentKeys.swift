import SwiftUI
#if DEBUG
import FirebaseAuth
#endif

// MARK: - AuthService

/// The key for accessing the `AuthServiceProtocol` in the SwiftUI Environment.
struct AuthServiceKey: EnvironmentKey {
    static var defaultValue: AuthServiceProtocol {
        // Provide a safe mock for previews and testing
        #if DEBUG
        return MockAuthService()
        #else
        fatalError("AuthService not found. Did you forget to inject it?")
        #endif
    }
}

private struct APIClientKey: EnvironmentKey {
    static let defaultValue: APIClientProtocol = {
        guard let client = APIClient(tokenProvider: { nil }) else {
            fatalError("Failed to create default APIClient")
        }
        return client
    }()
}

// MARK: - Repository Protocols

private struct HealthDataRepositoryKey: EnvironmentKey {
    // For previews and testing, a default mock can be useful.
    // For production, a real implementation will be injected.
    static let defaultValue: HealthDataRepositoryProtocol = MockHealthDataRepository()
}

private struct InsightsRepositoryKey: EnvironmentKey {
    static let defaultValue: InsightsRepositoryProtocol = MockInsightsRepository()
}

private struct UserRepositoryKey: EnvironmentKey {
    static let defaultValue: UserRepositoryProtocol = MockUserRepository()
}

private struct HealthKitServiceKey: EnvironmentKey {
    static let defaultValue: HealthKitServiceProtocol = MockHealthKitService()
}

extension EnvironmentValues {
    /// Provides access to the `AuthService` throughout the SwiftUI environment.
    var authService: AuthServiceProtocol {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
    
    var healthDataRepository: HealthDataRepositoryProtocol {
        get { self[HealthDataRepositoryKey.self] }
        set { self[HealthDataRepositoryKey.self] = newValue }
    }
    
    var insightsRepository: InsightsRepositoryProtocol {
        get { self[InsightsRepositoryKey.self] }
        set { self[InsightsRepositoryKey.self] = newValue }
    }
    
    var userRepository: UserRepositoryProtocol {
        get { self[UserRepositoryKey.self] }
        set { self[UserRepositoryKey.self] = newValue }
    }
    
    var healthKitService: HealthKitServiceProtocol {
        get { self[HealthKitServiceKey.self] }
        set { self[HealthKitServiceKey.self] = newValue }
    }
    
    var apiClient: APIClientProtocol {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}

#if DEBUG
// MARK: - Mock Implementations for Previews

class MockAPIClient: APIClientProtocol {
    func register(requestDTO: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        .init(userId: UUID(), email: "", status: "mock", verificationEmailSent: true, createdAt: Date())
    }
    
    func login(requestDTO: UserLoginRequestDTO) async throws -> LoginResponseDTO {
        fatalError("Mock Not Implemented")
    }
    
    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO {
        .init(data: [])
    }
    
    func uploadHealthKitData(requestDTO: HealthKitUploadRequestDTO) async throws -> HealthKitUploadResponseDTO {
        .init(success: true, uploadId: "mock", processedSamples: 0, skippedSamples: 0, errors: nil, message: "mock")
    }
    
    func syncHealthKitData(requestDTO: HealthKitSyncRequestDTO) async throws -> HealthKitSyncResponseDTO {
        .init(success: true, syncId: "mock", status: "mock", estimatedDuration: nil, message: "mock")
    }
    
    func getHealthKitSyncStatus(syncId: String) async throws -> HealthKitSyncStatusDTO {
        .init(syncId: "mock", status: "mock", progress: 1.0, processedSamples: 0, totalSamples: 0, errors: nil, completedAt: Date())
    }
    
    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO {
        .init(success: true, data: .init(insights: [], totalCount: 0, hasMore: false, pagination: nil), metadata: nil)
    }
    
    func generateInsight(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO {
        fatalError("Mock Not Implemented")
    }
}

class MockAuthService: AuthServiceProtocol {
    var currentUser: AuthUser? = AuthUser(uid: "mock-uid", email: "mock@example.com", isEmailVerified: true)
    var authState: AsyncStream<AuthUser?> {
        AsyncStream { continuation in
            continuation.yield(currentUser)
            continuation.finish()
        }
    }
    
    func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO {
        // Mock implementation
        return UserSessionResponseDTO(
            userId: UUID(),
            firstName: "Mock",
            lastName: "User",
            email: email,
            role: "user",
            permissions: [],
            status: "active",
            mfaEnabled: false,
            emailVerified: true,
            createdAt: Date(),
            lastLogin: Date()
        )
    }
    
    func register(withEmail email: String, password: String, details: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        // Mock implementation
        return RegistrationResponseDTO(
            userId: UUID(),
            email: email,
            status: "pending_verification",
            verificationEmailSent: true,
            createdAt: Date()
        )
    }
    
    func signOut() throws {
        // Mock implementation
    }
    
    func sendPasswordReset(to email: String) async throws {
        // Mock implementation
    }
    
    func getCurrentUserToken() async throws -> String {
        return "mock-token"
    }
}

class MockHealthDataRepository: HealthDataRepositoryProtocol {
    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO {
        return .init(data: [])
    }
}
class MockInsightsRepository: InsightsRepositoryProtocol {
    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO {
        return .init(success: true, data: .init(insights: [], totalCount: 0, hasMore: false, pagination: nil), metadata: nil)
    }
    func generateInsight(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO {
        fatalError("Not implemented for mock")
    }
}
class MockUserRepository: UserRepositoryProtocol {
    func getCurrentUserProfile() async throws -> UserProfile {
        fatalError("Not implemented for mock")
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        fatalError("Not implemented for mock")
    }
    
    func deleteUserAccount() async throws {
        fatalError("Not implemented for mock")
    }
    
    func getPrivacyPreferences() async throws -> UserPrivacyPreferencesDTO {
        fatalError("Not implemented for mock")
    }
    
    func updatePrivacyPreferences(_ preferences: UserPrivacyPreferencesDTO) async throws {
        fatalError("Not implemented for mock")
    }
}

// A mock service can be used for previews that need to simulate HealthKit responses.
class MockHealthKitService: HealthKitServiceProtocol {
    func isHealthDataAvailable() -> Bool { true }
    func requestAuthorization() async throws {}
    func fetchDailySteps(for date: Date) async throws -> Double { 5000 }
    func fetchRestingHeartRate(for date: Date) async throws -> Double? { 60 }
    func fetchSleepAnalysis(for date: Date) async throws -> SleepData? { nil }
    func fetchAllDailyMetrics(for date: Date) async throws -> DailyHealthMetrics {
        .init(date: Date(), stepCount: 5000, restingHeartRate: 60, sleepData: nil)
    }
    func uploadHealthKitData(_ uploadRequest: HealthKitUploadRequestDTO) async throws -> HealthKitUploadResponseDTO {
        return HealthKitUploadResponseDTO(success: true, uploadId: "mock-upload-id", processedSamples: uploadRequest.samples.count, skippedSamples: 0, errors: nil, message: "Mock upload successful")
    }
}
#endif

// NOTE: Add other service keys here as needed (e.g., for HealthKit, Networking, etc.) 
