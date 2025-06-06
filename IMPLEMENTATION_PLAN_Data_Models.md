# Implementation Plan: Data Models (DTOs & SwiftData)

This document provides a detailed specification for all data models required for the CLARITY Pulse application. It is broken down into two main sections:
1.  **Data Transfer Objects (DTOs):** Plain `Codable` Swift structs that exactly match the JSON structure of the backend API. These are used in the Networking layer.
2.  **SwiftData Models:** `@Model` classes for local persistence and caching. These are used in the Persistence layer.

Place DTOs in the `Data/DTOs` group and SwiftData models in the `Data/Models` group.

---

## 1. Data Transfer Objects (DTOs)

These structs are used for encoding and decoding data for network requests. They must conform to `Codable`.

### 1.1. Utility DTOs

- [x] **Create `AnyCodable.swift`:** Implement a generic `AnyCodable` wrapper to handle `[String: Any]` or dynamic JSON objects in responses, especially for `metadata` fields. There are standard open-source implementations available.
- [x] **Create `MessageResponseDTO.swift`:** For simple `{"message": "..."}` responses.
    ```swift
    struct MessageResponseDTO: Codable {
        let message: String
    }
    ```
- [x] **Create `ValidationErrorDTO.swift`:**
    ```swift
    struct ValidationErrorDTO: Codable {
        let field: String
        let message: String
        let code: String
    }
    ```

### 1.2. Authentication DTOs (`/api/v1/auth`)

- [x] **`UserRegistrationRequestDTO.swift`**
    - `email: String`
    - `password: String`
    - `firstName: String`
    - `lastName: String`
    - `phoneNumber: String?`
    - `termsAccepted: Bool`
    - `privacyPolicyAccepted: Bool`
- [x] **`RegistrationResponseDTO.swift`**
    - `userId: UUID`
    - `email: String`
    - `status: String`
    - `verificationEmailSent: Bool`
    - `createdAt: Date`
- [x] **`UserLoginRequestDTO.swift`**
    - `email: String`
    - `password: String`
    - `rememberMe: Bool`
    - `deviceInfo: [String: AnyCodable]?`
- [x] **`LoginResponseDTO.swift`**
    - `user: UserSessionResponseDTO`
    - `tokens: TokenResponseDTO`
- [x] **`UserSessionResponseDTO.swift`**
    - `userId: UUID`
    - `firstName: String`
    - `lastName: String`
    - `email: String`
    - `role: String`
    - `permissions: [String]`
    - `status: String`
    - `mfaEnabled: Bool`
    - `emailVerified: Bool`
    - `createdAt: Date`
    - `lastLogin: Date?`
- [x] **`TokenResponseDTO.swift`**
    - `accessToken: String`
    - `refreshToken: String`
    - `tokenType: String`
    - `expiresIn: Int`
- [x] **`RefreshTokenRequestDTO.swift`**
    - `refreshToken: String`

### 1.3. HealthKit Upload DTOs (`/api/v1/healthkit_upload`)

- [ ] **`HealthKitSampleDTO.swift`**
- [ ] **`HealthKitUploadRequestDTO.swift`**
- [ ] **`HealthKitUploadResponseDTO.swift`**
- [ ] **`HealthKitUploadStatusDTO.swift`**

### 1.4. Health Data DTOs (`/api/v1/health-data`)

- [x] **`HealthMetricDTO.swift`**
    - `metricId: UUID`
    - `metricType: String` // Or create an enum `HealthMetricType: String, Codable`
    - `biometricData: BiometricDataDTO?`
    - `sleepData: SleepDataDTO?`
    - `activityData: ActivityDataDTO?`
    - `mentalHealthData: MentalHealthIndicatorDTO?`
    - `deviceId: String?`
    - `rawData: [String: AnyCodable]?`
    - `metadata: [String: AnyCodable]?`
    - `createdAt: Date`
- [x] **`BiometricDataDTO.swift`**
    - `heartRate: Double?`
    - `bloodPressureSystolic: Int?`
    - `bloodPressureDiastolic: Int?`
    - `oxygenSaturation: Double?`
    - `heartRateVariability: Double?`
    - `respiratoryRate: Double?`
    - `bodyTemperature: Double?`
    - `bloodGlucose: Double?`
- [x] **`SleepDataDTO.swift`**
    - `totalSleepMinutes: Int`
    - `sleepEfficiency: Double`
    - `timeToSleepMinutes: Int?`
    - `wakeCount: Int?`
    - `sleepStages: [String: Int]?`
    - `sleepStart: Date`
    - `sleepEnd: Date`
- [x] **`ActivityDataDTO.swift`**
    - `steps: Int?`
    - `distance: Double?`
    - `activeEnergy: Double?`
    - `exerciseMinutes: Int?`
    - `flightsClimbed: Int?`
    - `vo2Max: Double?`
    - `activeMinutes: Int?`
    - `restingHeartRate: Double?`
- [x] **`MentalHealthIndicatorDTO.swift`**
    - `moodScore: String?`
    - `stressLevel: Double?`
    - `anxietyLevel: Double?`
    - `energyLevel: Double?`
    - `focusRating: Double?`
    - `socialInteractionMinutes: Int?`
    - `meditationMinutes: Int?`
    - `notes: String?`
    - `timestamp: Date`
- [ ] **`HealthDataUploadDTO.swift`**
    - `userId: UUID`
    - `metrics: [HealthMetricDTO]`
    - `uploadSource: String`
    - `clientTimestamp: Date`
    - `syncToken: String?`
- [ ] **`HealthDataResponseDTO.swift`**
    - `processingId: UUID`
    - `status: String`
    - `acceptedMetrics: Int`
    - `rejectedMetrics: Int`
    - `validationErrors: [ValidationErrorDTO]`
    - `estimatedProcessingTime: Int?`
    - `syncToken: String?`
    - `message: String`
    - `timestamp: Date`
- [x] **`PaginatedMetricsResponseDTO.swift`** (for `GET /health-data`)
    - `data: [HealthMetricDTO]`
    - `// Add pagination fields like 'links', 'meta' etc. as per final API spec`

### 1.5. PAT Analysis DTOs (`/api/v1/pat`)

- [ ] **`StepDataRequestDTO.swift`**
- [ ] **`ActigraphyDataPointDTO.swift`**
- [ ] **`DirectActigraphyRequestDTO.swift`**
- [ ] **`AnalysisResponseDTO.swift`** (Generic wrapper)
- [ ] **`PATAnalysisResponseDTO.swift`** (for `GET /pat/analysis/{id}`)
- [ ] **`PATServiceHealthDTO.swift`**

### 1.6. Gemini Insights DTOs (`/api/v1/insights`)

- [x] **`InsightGenerationRequestDTO.swift`**
    - `analysisResults: [String: AnyCodable]`
    - `context: String?`
    - `insightType: String`
    - `includeRecommendations: Bool`
    - `language: String`
- [x] **`InsightGenerationResponseDTO.swift`**
    - `success: Bool`
    - `data: HealthInsightDTO`
    - `metadata: [String: AnyCodable]`
- [x] **`HealthInsightDTO.swift`**
    - `userId: String`
    - `narrative: String`
    - `keyInsights: [String]`
    - `recommendations: [String]`
    - `confidenceScore: Double`
    - `generatedAt: Date`
- [x] **`InsightHistoryResponseDTO.swift`**
    - `success: Bool`
    - `data: InsightHistoryDataDTO`
    - `metadata: [String: AnyCodable]`
- [x] **`InsightHistoryDataDTO.swift`**
    - `insights: [InsightPreviewDTO]`
    - `totalCount: Int`
    - `hasMore: Bool`
    - `pagination: PaginationMetaDTO`
- [x] **`InsightPreviewDTO.swift`**
    - `id: String`
    - `narrative: String`
    - `generatedAt: Date`
    - `confidenceScore: Double`
    - `keyInsightsCount: Int`
    - `recommendationsCount: Int`
- [x] **`PaginationMetaDTO.swift`**
    - `page: Int`
    - `limit: Int`
    - `// etc.`
- [ ] **`ServiceStatusResponseDTO.swift`** (for `GET /insights/status`)
    - `success: Bool`
    - `data: ServiceStatusDataDTO`
    - `metadata: [String: AnyCodable]`
- [ ] **`ServiceStatusDataDTO.swift`**
    - `service: String`
    - `status: String`
    - `model: ModelInfoDTO`
    - `timestamp: Date`
- [ ] **`ModelInfoDTO.swift`**
    - `modelName: String`
    - `projectId: String`
    - `initialized: Bool`
    - `capabilities: [String]`

---

## 2. SwiftData Models

These classes are for local persistence using SwiftData. They should be placed in the `Data/Models` group.

- [x] **`UserProfile.swift`**
- [x] **`HealthMetricEntity.swift`** (Flattened structure for easy querying)
    - `@Attribute(.unique) id: UUID`
    - `type: String`
    - `date: Date` (Primary timestamp for sorting/querying)
    - **Biometric Fields:**
        - `heartRate: Double?`
        - `systolicBP: Int?`
        - `diastolicBP: Int?`
        - `oxygenSaturation: Double?`
        - `hrv: Double?`
        - `respiratoryRate: Double?`
        - `bodyTemperature: Double?`
        - `bloodGlucose: Double?`
    - **Sleep Fields:**
        - `totalSleepMinutes: Int?`
        - `sleepEfficiency: Double?`
        - `sleepStart: Date?`
        - `sleepEnd: Date?`
    - **Activity Fields:**
        - `steps: Int?`
        - `distance: Double?`
        - `activeEnergy: Double?`
        - `exerciseMinutes: Int?`
        - `flightsClimbed: Int?`
        - `vo2Max: Double?`
        - `activeMinutes: Int?`
        - `restingHeartRate: Double?`
    - **Mental Health Fields:**
        - `moodScore: String?`
        - `stressLevel: Double?`
        - `anxietyLevel: Double?`
        - `energyLevel: Double?`
        - `focusRating: Double?`
        - `socialInteractionMinutes: Int?`
        - `meditationMinutes: Int?`
    - **Metadata:**
        - `deviceId: String?`
        - `rawJson: Data?` (To store the original, full DTO as a JSON blob for completeness)
        - `lastSyncedAt: Date`
- [x] **`InsightEntity.swift`**
    - `@Attribute(.unique) id: String`
    - `userId: String`
    - `narrative: String`
    - `keyInsights: [String]`
    - `recommendations: [String]`
    - `confidenceScore: Double`
    - `generatedAt: Date`
    - `lastViewedAt: Date?` (local-only metadata)
- [x] **`PATAnalysisEntity.swift`** (Optional, if caching raw PAT results is desired)
    - `@Attribute(.unique) id: String`
    - `status: String`
    - `completedAt: Date?`
    - `patFeatures: Data?` (JSON-encoded dictionary)
    - `activityEmbedding: Data?` (JSON-encoded array)
    - `lastSyncedAt: Date`
- [x] **Implement Mappings:** Create convenience initializers or mapping functions to convert between DTOs and SwiftData `@Model` entities. This logic should reside within a Repository or a dedicated Mapper class.
    - [ ] `HealthMetricEntity(from dto: HealthMetricDTO)`
    - [x] `InsightEntity(from dto: HealthInsightDTO)`
    - [x] `UserProfile(from dto: UserSessionResponseDTO)` 