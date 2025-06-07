import Foundation

/// Defines the contract for an API client that communicates with the CLARITY backend.
/// This protocol allows for dependency injection and mocking for testing purposes.
protocol APIClientProtocol {
    // Endpoints for Authentication
    func register(requestDTO: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO
    func login(requestDTO: UserLoginRequestDTO) async throws -> LoginResponseDTO
    func refreshToken(requestDTO: RefreshTokenRequestDTO) async throws -> TokenResponseDTO
    func logout() async throws -> MessageResponseDTO
    func getCurrentUser() async throws -> UserSessionResponseDTO
    func verifyEmail(code: String) async throws -> MessageResponseDTO
    
    // Endpoints for Health Data
    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO
    func uploadHealthKitData(requestDTO: HealthKitUploadRequestDTO) async throws -> HealthKitUploadResponseDTO
    func syncHealthKitData(requestDTO: HealthKitSyncRequestDTO) async throws -> HealthKitSyncResponseDTO
    func getHealthKitSyncStatus(syncId: String) async throws -> HealthKitSyncStatusDTO
    func getHealthKitUploadStatus(uploadId: String) async throws -> HealthKitUploadStatusDTO
    func getProcessingStatus(id: UUID) async throws -> ProcessingStatusDTO
    
    // Endpoints for Insights
    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO
    func generateInsight(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO
    func getInsight(id: String) async throws -> InsightGenerationResponseDTO
    func getInsightsServiceStatus() async throws -> ServiceStatusResponseDTO
    
    // Endpoints for PAT Analysis
    func analyzeStepData(requestDTO: StepDataRequestDTO) async throws -> AnalysisResponseDTO
    func analyzeActigraphy(requestDTO: DirectActigraphyRequestDTO) async throws -> AnalysisResponseDTO
    func getPATAnalysis(id: String) async throws -> PATAnalysisResponseDTO
    func getPATServiceHealth() async throws -> ServiceStatusResponseDTO
}

/// The concrete implementation of the API client.
final class APIClient: APIClientProtocol {
    
    // MARK: - Properties

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let tokenProvider: () async -> String?

    // MARK: - Initializer

    init?(
        baseURLString: String = "https://api.clarity.health/api/v1",
        session: URLSession = .shared,
        tokenProvider: @escaping () async -> String?
    ) {
        guard let baseURL = URL(string: baseURLString) else {
            return nil // Return nil if the URL is invalid
        }
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
        
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Public API Methods
    
    func register(requestDTO: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        let endpoint = AuthEndpoint.register(dto: requestDTO)
        return try await performRequest(for: endpoint, requiresAuth: false)
    }
    
    func login(requestDTO: UserLoginRequestDTO) async throws -> LoginResponseDTO {
        let endpoint = AuthEndpoint.login(dto: requestDTO)
        return try await performRequest(for: endpoint, requiresAuth: false)
    }

    // MARK: - Health Data Methods
    
    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO {
        let endpoint = HealthDataEndpoint.getMetrics(page: page, limit: limit)
        return try await performRequest(for: endpoint)
    }
    
    func uploadHealthKitData(requestDTO: HealthKitUploadRequestDTO) async throws -> HealthKitUploadResponseDTO {
        let endpoint = HealthDataEndpoint.uploadHealthKit(dto: requestDTO)
        return try await performRequest(for: endpoint)
    }
    
    func syncHealthKitData(requestDTO: HealthKitSyncRequestDTO) async throws -> HealthKitSyncResponseDTO {
        let endpoint = HealthDataEndpoint.syncHealthKit(dto: requestDTO)
        return try await performRequest(for: endpoint)
    }
    
    func getHealthKitSyncStatus(syncId: String) async throws -> HealthKitSyncStatusDTO {
        let endpoint = HealthDataEndpoint.getSyncStatus(syncId: syncId)
        return try await performRequest(for: endpoint)
    }

    // MARK: - Insights Methods
    
    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO {
        let endpoint = InsightEndpoint.getHistory(userId: userId, limit: limit, offset: offset)
        return try await performRequest(for: endpoint)
    }
    
    func generateInsight(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO {
        let endpoint = InsightEndpoint.generate(dto: requestDTO)
        return try await performRequest(for: endpoint)
    }
    
    // MARK: - Additional Auth Methods
    
    func refreshToken(requestDTO: RefreshTokenRequestDTO) async throws -> TokenResponseDTO {
        let endpoint = AuthEndpoint.refreshToken(dto: requestDTO)
        return try await performRequest(for: endpoint, requiresAuth: false)
    }
    
    func logout() async throws -> MessageResponseDTO {
        let endpoint = AuthEndpoint.logout
        return try await performRequest(for: endpoint)
    }
    
    func getCurrentUser() async throws -> UserSessionResponseDTO {
        let endpoint = AuthEndpoint.getCurrentUser
        return try await performRequest(for: endpoint)
    }
    
    func verifyEmail(code: String) async throws -> MessageResponseDTO {
        let endpoint = AuthEndpoint.verifyEmail(code: code)
        return try await performRequest(for: endpoint)
    }
    
    // MARK: - Additional Health Data Methods
    
    func getHealthKitUploadStatus(uploadId: String) async throws -> HealthKitUploadStatusDTO {
        let endpoint = HealthDataEndpoint.getUploadStatus(uploadId: uploadId)
        return try await performRequest(for: endpoint)
    }
    
    func getProcessingStatus(id: UUID) async throws -> ProcessingStatusDTO {
        let endpoint = HealthDataEndpoint.getProcessingStatus(id: id)
        return try await performRequest(for: endpoint)
    }
    
    // MARK: - Additional Insights Methods
    
    func getInsight(id: String) async throws -> InsightGenerationResponseDTO {
        let endpoint = InsightEndpoint.getInsight(id: id)
        return try await performRequest(for: endpoint)
    }
    
    func getInsightsServiceStatus() async throws -> ServiceStatusResponseDTO {
        let endpoint = InsightEndpoint.getServiceStatus
        return try await performRequest(for: endpoint)
    }
    
    // MARK: - PAT Analysis Methods
    
    func analyzeStepData(requestDTO: StepDataRequestDTO) async throws -> AnalysisResponseDTO {
        let endpoint = PATEndpoint.analyzeStepData(dto: requestDTO)
        return try await performRequest(for: endpoint)
    }
    
    func analyzeActigraphy(requestDTO: DirectActigraphyRequestDTO) async throws -> AnalysisResponseDTO {
        let endpoint = PATEndpoint.analyzeActigraphy(dto: requestDTO)
        return try await performRequest(for: endpoint)
    }
    
    func getPATAnalysis(id: String) async throws -> PATAnalysisResponseDTO {
        let endpoint = PATEndpoint.getAnalysis(id: id)
        return try await performRequest(for: endpoint)
    }
    
    func getPATServiceHealth() async throws -> ServiceStatusResponseDTO {
        let endpoint = PATEndpoint.getServiceHealth
        return try await performRequest(for: endpoint)
    }

    // MARK: - Private Request Helper

    /// A generic helper to perform network requests, handle authentication, and decode responses.
    /// This method centralizes error handling and token attachment.
    private func performRequest<T: Decodable>(
        for endpoint: Endpoint,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let request = try? endpoint.asURLRequest(baseURL: baseURL, encoder: encoder) else {
            throw APIError.invalidURL
        }
        
        var authorizedRequest = request
        if requiresAuth {
            guard let token = await tokenProvider() else {
                throw APIError.unauthorized
            }
            authorizedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: authorizedRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown(URLError(.badServerResponse))
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    // Handle empty response body for 204 No Content
                    if data.isEmpty, let empty = EmptyResponse() as? T {
                        return empty
                    }
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            case 401:
                throw APIError.unauthorized
            default:
                let serverMessage = try? decoder.decode(MessageResponseDTO.self, from: data).message
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: serverMessage)
            }
        } catch let error as APIError {
            throw error
        } catch let error as URLError {
            throw APIError.networkError(error)
        } catch {
            throw APIError.unknown(error)
        }
    }
}

// MARK: - Endpoint Definition

protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    
    // The body is now a function that takes an encoder.
    func body(encoder: JSONEncoder) throws -> Data?
}

extension Endpoint {
    func asURLRequest(baseURL: URL, encoder: JSONEncoder) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try body(encoder: encoder)
        return request
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// A helper struct for empty JSON responses.
struct EmptyResponse: Codable {} 
