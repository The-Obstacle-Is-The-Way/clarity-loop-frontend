import Foundation
@testable import clarity_loop_frontend

/// Mock implementation of APIClientProtocol for testing
final class MockAPIClient: APIClientProtocol {
    
    // MARK: - Tracking Properties
    
    var registerCalled = false
    var registerRequestDTO: UserRegistrationRequestDTO?
    var registerResult: Result<RegistrationResponseDTO, Error> = .failure(MockError.notImplemented)
    
    var loginCalled = false
    var loginRequestDTO: UserLoginRequestDTO?
    var loginResult: Result<LoginResponseDTO, Error> = .failure(MockError.notImplemented)
    
    var logoutCalled = false
    var logoutResult: Result<MessageResponseDTO, Error> = .failure(MockError.notImplemented)
    
    var refreshTokenCalled = false
    var refreshTokenResult: Result<TokenResponseDTO, Error> = .failure(MockError.notImplemented)
    
    var getUserInfoCalled = false
    var getUserInfoResult: Result<UserSessionResponseDTO, Error> = .failure(MockError.notImplemented)
    
    var updateUserCalled = false
    var updateUserDTO: UserUpdateRequestDTO?
    var updateUserResult: Result<UserUpdateResponseDTO, Error> = .failure(MockError.notImplemented)
    
    var uploadHealthKitDataCalled = false
    var uploadHealthKitDataDTO: HealthKitDataDTO?
    var uploadHealthKitDataResult: Result<HealthKitUploadResponseDTO, Error> = .failure(MockError.notImplemented)
    
    var uploadHealthDataCalled = false
    var uploadHealthDataDTO: HealthDataUploadRequestDTO?
    var uploadHealthDataResult: Result<HealthDataUploadResponseDTO, Error> = .failure(MockError.notImplemented)
    
    var getHealthDataStatusCalled = false
    var getHealthDataStatusJobId: String?
    var getHealthDataStatusResult: Result<HealthDataProcessingStatusDTO, Error> = .failure(MockError.notImplemented)
    
    var getInsightsCalled = false
    var getInsightsDTO: InsightsRequestDTO?
    var getInsightsResult: Result<InsightsResponseDTO, Error> = .failure(MockError.notImplemented)
    
    var getInsightsStatusCalled = false
    var getInsightsStatusResult: Result<InsightsStatusResponseDTO, Error> = .failure(MockError.notImplemented)
    
    // PAT Analysis
    var analyzePATStepDataCalled = false
    var analyzePATStepDataDTO: PATStepAnalysisRequestDTO?
    var analyzePATStepDataResult: Result<PATAnalysisResponseDTO, Error> = .failure(MockError.notImplemented)
    
    var analyzePATActigraphyCalled = false
    var analyzePATActigraphyDTO: PATActigraphyAnalysisRequestDTO?
    var analyzePATActigraphyResult: Result<PATAnalysisResponseDTO, Error> = .failure(MockError.notImplemented)
    
    var getPATServiceHealthCalled = false
    var getPATServiceHealthResult: Result<HealthResponseDTO, Error> = .failure(MockError.notImplemented)
    
    // MARK: - APIClientProtocol Implementation
    
    func register(requestDTO: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        registerCalled = true
        registerRequestDTO = requestDTO
        return try registerResult.get()
    }
    
    func login(requestDTO: UserLoginRequestDTO) async throws -> LoginResponseDTO {
        loginCalled = true
        loginRequestDTO = requestDTO
        return try loginResult.get()
    }
    
    func logout() async throws -> MessageResponseDTO {
        logoutCalled = true
        return try logoutResult.get()
    }
    
    func refreshToken() async throws -> TokenResponseDTO {
        refreshTokenCalled = true
        return try refreshTokenResult.get()
    }
    
    func getUserInfo() async throws -> UserSessionResponseDTO {
        getUserInfoCalled = true
        return try getUserInfoResult.get()
    }
    
    func updateUser(requestDTO: UserUpdateRequestDTO) async throws -> UserUpdateResponseDTO {
        updateUserCalled = true
        updateUserDTO = requestDTO
        return try updateUserResult.get()
    }
    
    func uploadHealthKitData(_ data: HealthKitDataDTO) async throws -> HealthKitUploadResponseDTO {
        uploadHealthKitDataCalled = true
        uploadHealthKitDataDTO = data
        return try uploadHealthKitDataResult.get()
    }
    
    func uploadHealthData(_ data: HealthDataUploadRequestDTO) async throws -> HealthDataUploadResponseDTO {
        uploadHealthDataCalled = true
        uploadHealthDataDTO = data
        return try uploadHealthDataResult.get()
    }
    
    func getHealthDataProcessingStatus(jobId: String) async throws -> HealthDataProcessingStatusDTO {
        getHealthDataStatusCalled = true
        getHealthDataStatusJobId = jobId
        return try getHealthDataStatusResult.get()
    }
    
    func getInsights(requestDTO: InsightsRequestDTO) async throws -> InsightsResponseDTO {
        getInsightsCalled = true
        getInsightsDTO = requestDTO
        return try getInsightsResult.get()
    }
    
    func getInsightsStatus() async throws -> InsightsStatusResponseDTO {
        getInsightsStatusCalled = true
        return try getInsightsStatusResult.get()
    }
    
    func analyzePATStepData(_ requestDTO: PATStepAnalysisRequestDTO) async throws -> PATAnalysisResponseDTO {
        analyzePATStepDataCalled = true
        analyzePATStepDataDTO = requestDTO
        return try analyzePATStepDataResult.get()
    }
    
    func analyzePATActigraphy(_ requestDTO: PATActigraphyAnalysisRequestDTO) async throws -> PATAnalysisResponseDTO {
        analyzePATActigraphyCalled = true
        analyzePATActigraphyDTO = requestDTO
        return try analyzePATActigraphyResult.get()
    }
    
    func getPATServiceHealth() async throws -> HealthResponseDTO {
        getPATServiceHealthCalled = true
        return try getPATServiceHealthResult.get()
    }
    
    // MARK: - Reset
    
    func reset() {
        registerCalled = false
        registerRequestDTO = nil
        registerResult = .failure(MockError.notImplemented)
        
        loginCalled = false
        loginRequestDTO = nil
        loginResult = .failure(MockError.notImplemented)
        
        logoutCalled = false
        logoutResult = .failure(MockError.notImplemented)
        
        refreshTokenCalled = false
        refreshTokenResult = .failure(MockError.notImplemented)
        
        getUserInfoCalled = false
        getUserInfoResult = .failure(MockError.notImplemented)
        
        updateUserCalled = false
        updateUserDTO = nil
        updateUserResult = .failure(MockError.notImplemented)
        
        uploadHealthKitDataCalled = false
        uploadHealthKitDataDTO = nil
        uploadHealthKitDataResult = .failure(MockError.notImplemented)
        
        uploadHealthDataCalled = false
        uploadHealthDataDTO = nil
        uploadHealthDataResult = .failure(MockError.notImplemented)
        
        getHealthDataStatusCalled = false
        getHealthDataStatusJobId = nil
        getHealthDataStatusResult = .failure(MockError.notImplemented)
        
        getInsightsCalled = false
        getInsightsDTO = nil
        getInsightsResult = .failure(MockError.notImplemented)
        
        getInsightsStatusCalled = false
        getInsightsStatusResult = .failure(MockError.notImplemented)
        
        analyzePATStepDataCalled = false
        analyzePATStepDataDTO = nil
        analyzePATStepDataResult = .failure(MockError.notImplemented)
        
        analyzePATActigraphyCalled = false
        analyzePATActigraphyDTO = nil
        analyzePATActigraphyResult = .failure(MockError.notImplemented)
        
        getPATServiceHealthCalled = false
        getPATServiceHealthResult = .failure(MockError.notImplemented)
    }
}

// MARK: - Mock Error

enum MockError: LocalizedError {
    case notImplemented
    case customError(String)
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Mock method not implemented"
        case .customError(let message):
            return message
        }
    }
}