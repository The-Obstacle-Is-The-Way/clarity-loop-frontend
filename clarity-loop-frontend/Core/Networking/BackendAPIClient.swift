import Foundation

// MARK: - Backend API Client

/// Enhanced API client that uses the backend contract adapter for all requests
/// This ensures perfect compatibility with the backend API
final class BackendAPIClient: APIClientProtocol {
    
    // MARK: - Properties
    
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let tokenProvider: () async -> String?
    private let contractAdapter: BackendContractAdapterProtocol
    
    // MARK: - Initializer
    
    init?(
        baseURLString: String = AppConfig.apiBaseURL,
        session: URLSession = .shared,
        tokenProvider: @escaping () async -> String?,
        contractAdapter: BackendContractAdapterProtocol = BackendContractAdapter()
    ) {
        guard let baseURL = URL(string: baseURLString) else {
            return nil
        }
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
        self.contractAdapter = contractAdapter
        
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Authentication Methods
    
    func register(requestDTO: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
        // Adapt frontend DTO to backend format
        let backendRequest = contractAdapter.adaptRegistrationRequest(requestDTO)
        
        // Make the request
        let endpoint = AuthEndpoint.register(dto: requestDTO) // We'll override the body
        let backendResponse: BackendTokenResponse = try await performBackendRequest(
            for: endpoint,
            body: backendRequest,
            requiresAuth: false
        )
        
        // Adapt response back to frontend format
        return try contractAdapter.adaptRegistrationResponse(backendResponse)
    }
    
    func login(requestDTO: UserLoginRequestDTO) async throws -> LoginResponseDTO {
        // Adapt frontend DTO to backend format
        let backendRequest = contractAdapter.adaptLoginRequest(requestDTO)
        
        // Make the login request
        let endpoint = AuthEndpoint.login(dto: requestDTO) // We'll override the body
        let tokenResponse: BackendTokenResponse = try await performBackendRequest(
            for: endpoint,
            body: backendRequest,
            requiresAuth: false
        )
        
        // Now fetch user info to complete the login response
        let userInfoEndpoint = AuthEndpoint.getCurrentUser
        let userInfo: BackendUserInfoResponse = try await performBackendRequest(
            for: userInfoEndpoint,
            requiresAuth: true,
            accessToken: tokenResponse.accessToken
        )
        
        // Combine responses
        let userSession = contractAdapter.adaptUserInfoResponse(userInfo)
        let tokens = contractAdapter.adaptTokenResponse(tokenResponse)
        
        return LoginResponseDTO(user: userSession, tokens: tokens)
    }
    
    func refreshToken(requestDTO: RefreshTokenRequestDTO) async throws -> TokenResponseDTO {
        let backendRequest = contractAdapter.adaptRefreshTokenRequest(requestDTO.refreshToken)
        
        let backendResponse: BackendTokenResponse = try await performBackendRequest(
            for: AuthEndpoint.refreshToken(dto: requestDTO),
            body: backendRequest,
            requiresAuth: false
        )
        
        return contractAdapter.adaptTokenResponse(backendResponse)
    }
    
    func logout() async throws -> MessageResponseDTO {
        let backendResponse: BackendLogoutResponse = try await performBackendRequest(
            for: AuthEndpoint.logout,
            requiresAuth: true
        )
        
        return contractAdapter.adaptLogoutResponse(backendResponse)
    }
    
    func getCurrentUser() async throws -> UserSessionResponseDTO {
        let backendResponse: BackendUserInfoResponse = try await performBackendRequest(
            for: AuthEndpoint.getCurrentUser,
            requiresAuth: true
        )
        
        return contractAdapter.adaptUserInfoResponse(backendResponse)
    }
    
    // MARK: - Private Request Methods
    
    private func performBackendRequest<Response: Decodable>(
        for endpoint: Endpoint,
        requiresAuth: Bool = true,
        accessToken: String? = nil
    ) async throws -> Response {
        return try await performBackendRequest(
            for: endpoint,
            body: EmptyBody(),
            requiresAuth: requiresAuth,
            accessToken: accessToken
        )
    }
    
    private func performBackendRequest<Request: Encodable, Response: Decodable>(
        for endpoint: Endpoint,
        body: Request,
        requiresAuth: Bool = true,
        accessToken: String? = nil
    ) async throws -> Response {
        // Build URL
        guard let url = URL(string: endpoint.path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add body if provided
        if !(body is EmptyBody) {
            request.httpBody = try encoder.encode(body)
        } else if endpoint.method.requiresBody {
            // Use endpoint's body method if no override provided
            request.httpBody = try endpoint.body(encoder: encoder)
        }
        
        // Add authentication
        if requiresAuth {
            let token = accessToken ?? (await tokenProvider())
            if let token = token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                throw APIError.missingAuthToken
            }
        }
        
        // Log request for debugging
        #if DEBUG
        print("🌐 API Request: \(endpoint.method.rawValue) \(url.absoluteString)")
        if let body = request.httpBody {
            print("📤 Request Body: \(String(data: body, encoding: .utf8) ?? "Invalid UTF-8")")
        }
        #endif
        
        // Perform request
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            #if DEBUG
            print("📥 Response Status: \(httpResponse.statusCode)")
            print("📥 Response Body: \(String(data: data, encoding: .utf8) ?? "Invalid UTF-8")")
            #endif
            
            // Handle errors
            if httpResponse.statusCode >= 400 {
                // Try to adapt backend error
                if let adaptedError = contractAdapter.adaptErrorResponse(data) {
                    throw adaptedError
                }
                
                // Fallback to generic API error
                throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
            }
            
            // Decode response
            return try decoder.decode(Response.self, from: data)
            
        } catch {
            #if DEBUG
            print("❌ API Error: \(error)")
            #endif
            throw error
        }
    }
    
    // MARK: - Other Protocol Methods (Not Implemented Yet)
    
    func verifyEmail(code: String) async throws -> MessageResponseDTO {
        throw APIError.notImplemented
    }
    
    func getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO {
        throw APIError.notImplemented
    }
    
    func uploadHealthKitData(requestDTO: HealthKitUploadRequestDTO) async throws -> HealthKitUploadResponseDTO {
        throw APIError.notImplemented
    }
    
    func syncHealthKitData(requestDTO: HealthKitSyncRequestDTO) async throws -> HealthKitSyncResponseDTO {
        throw APIError.notImplemented
    }
    
    func getHealthKitSyncStatus(syncId: String) async throws -> HealthKitSyncStatusDTO {
        throw APIError.notImplemented
    }
    
    func getHealthKitUploadStatus(uploadId: String) async throws -> HealthKitUploadStatusDTO {
        throw APIError.notImplemented
    }
    
    func getProcessingStatus(id: UUID) async throws -> HealthDataProcessingStatusDTO {
        throw APIError.notImplemented
    }
    
    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO {
        throw APIError.notImplemented
    }
    
    func generateInsight(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO {
        throw APIError.notImplemented
    }
    
    func getInsight(id: String) async throws -> InsightGenerationResponseDTO {
        throw APIError.notImplemented
    }
    
    func getInsightsServiceStatus() async throws -> ServiceStatusResponseDTO {
        throw APIError.notImplemented
    }
    
    func analyzeStepData(requestDTO: StepDataRequestDTO) async throws -> StepAnalysisResponseDTO {
        throw APIError.notImplemented
    }
    
    func analyzeActigraphy(requestDTO: DirectActigraphyRequestDTO) async throws -> ActigraphyAnalysisResponseDTO {
        throw APIError.notImplemented
    }
    
    func getPATAnalysis(id: String) async throws -> PATAnalysisResponseDTO {
        throw APIError.notImplemented
    }
    
    func getPATServiceHealth() async throws -> ServiceStatusResponseDTO {
        throw APIError.notImplemented
    }
}

// MARK: - HTTP Method Extension

private extension HTTPMethod {
    var requiresBody: Bool {
        switch self {
        case .post, .put, .patch:
            return true
        default:
            return false
        }
    }
}

// MARK: - Empty Body Type

private struct EmptyBody: Encodable {}