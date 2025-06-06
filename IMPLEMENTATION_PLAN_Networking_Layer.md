# Implementation Plan: Networking Layer

This document details the implementation of the `APIClient`, the central component responsible for all communication with the CLARITY backend. This client will be built using modern Swift concurrency (`async/await`) and will be designed for testability and clarity.

## 1. APIClient Setup

- [ ] **Create `APIClient.swift`:** Place this file in `Core/Networking`. It will be a class that handles all network requests.
- [ ] **Define `APIClientProtocol`:** Create a protocol that the `APIClient` will conform to. This is crucial for dependency injection and testing.
- [ ] **Base URL Configuration:**
    - [ ] Store the base URL `https://api.clarity.health/api/v1` in a centralized, private property. Make it easily updatable for different environments (e.g., staging vs. production).
- [ ] **JSON Coder Configuration:**
    - [ ] Create shared `JSONEncoder` and `JSONDecoder` instances within the `APIClient`.
    - [ ] Configure the `JSONDecoder`'s date decoding strategy to `.iso8601` to correctly handle timestamps from the backend.
    - [ ] Configure the `JSONEncoder`'s date encoding strategy to `.iso8601`.
- [ ] **Authentication Provider:**
    - [ ] The `APIClient` initializer should accept an authentication token provider closure: `tokenProvider: () async -> String?`.
    - [ ] This decouples the `APIClient` from the `AuthService`, allowing a mock token provider to be injected during tests.
- [ ] **Unified Error Handling:**
    - [ ] Create a custom `APIError.swift` enum in `Core/Networking`.
        ```swift
        enum APIError: Error, LocalizedError {
            case invalidURL
            case networkError(URLError)
            case serverError(statusCode: Int, message: String?)
            case decodingError(Error)
            case unauthorized
            case unknown(Error)
            
            var errorDescription: String? {
                // Implement user-friendly error descriptions
            }
        }
        ```
    - [ ] Implement a private helper method `performRequest(request: URLRequest)` that wraps `URLSession.shared.data(for:)` and handles response validation and error mapping. This helper will be used by all public-facing API methods.

## 2. Generic Request Helper

- [ ] **Implement `perform<T: Decodable>(endpoint: Endpoint)`:** Create a generic private method to handle the common logic for all requests.
    - It should construct the `URLRequest` from an `Endpoint` struct/enum.
    - It should call the `tokenProvider` to get the latest JWT and add the `Authorization: Bearer <token>` header for protected endpoints.
    - It should use `try await URLSession.shared.data(for: request)`.
    - It should check the HTTP status code. If not in the 200-299 range, it should attempt to decode a server error message and throw the appropriate `APIError` case.
    - On success, it should decode the response data into the generic type `T` and return it.
    - This approach centralizes error handling and auth logic, keeping endpoint-specific methods clean.

## 3. API Endpoint Implementation Checklist

Implement a public method in `APIClient` for each backend endpoint. Each method should create the `URLRequest` and call the generic `performRequest` helper.

### Auth Endpoints (`/api/v1/auth`)
- [ ] `register(requestDTO: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO`
- [ ] `login(requestDTO: UserLoginRequestDTO) async throws -> LoginResponseDTO`
- [ ] `refreshToken(requestDTO: RefreshTokenRequestDTO) async throws -> TokenResponseDTO`
- [ ] `logout() async throws -> MessageResponseDTO`
- [ ] `getCurrentUser() async throws -> UserSessionResponseDTO`
- [ ] `verifyEmail(code: String) async throws -> MessageResponseDTO`

### HealthKit Upload Endpoints (`/api/v1/healthkit_upload`)
- [ ] `uploadHealthKit(requestDTO: HealthKitUploadRequestDTO) async throws -> HealthKitUploadResponseDTO`
- [ ] `getHealthKitUploadStatus(uploadId: String) async throws -> HealthKitUploadStatusDTO`

### Health Data Endpoints (`/api/v1/health-data`)
- [ ] `uploadHealthData(requestDTO: HealthDataUploadDTO) async throws -> HealthDataResponseDTO`
- [ ] `getHealthData(page: Int, limit: Int) async throws -> PaginatedMetricsResponseDTO`
- [ ] `getProcessingStatus(id: UUID) async throws -> ProcessingStatusDTO` (*Note: Define `ProcessingStatusDTO` based on expected response*)

### PAT Analysis Endpoints (`/api/v1/pat`)
- [ ] `analyzeStepData(requestDTO: StepDataRequestDTO) async throws -> AnalysisResponseDTO<ActigraphyAnalysisDTO>`
- [ ] `analyzeActigraphy(requestDTO: DirectActigraphyRequestDTO) async throws -> AnalysisResponseDTO<ActigraphyAnalysisDTO>`
- [ ] `getPATAnalysis(id: String) async throws -> PATAnalysisResponseDTO`
- [ ] `getPATServiceHealth() async throws -> PATServiceHealthDTO`

### Gemini Insights Endpoints (`/api/v1/insights`)
- [ ] `generateInsights(requestDTO: InsightGenerationRequestDTO) async throws -> InsightGenerationResponseDTO`
- [ ] `getInsight(id: String) async throws -> InsightGenerationResponseDTO`
- [ ] `getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO`
- [ ] `getInsightsServiceStatus() async throws -> ServiceStatusResponseDTO`

## 4. Token Refresh and Retry Logic

- [ ] **Handle 401 Unauthorized:** The `performRequest` helper should specifically check for a `401` status code.
- [ ] **Implement Retry Logic (Optional but Recommended):** When a `401` is received, the `APIClient` should:
    1. Attempt to get a new token by calling the `refreshToken` endpoint (if a refresh token is available) or forcing a Firebase refresh.
    2. If a new token is obtained, retry the original request **once**.
    3. If the refresh fails or the retried request also fails with a `401`, throw `APIError.unauthorized` to signal that the user must log in again.
- [ ] This logic can be encapsulated within the `performRequest` helper to be transparent to the individual API call sites. 