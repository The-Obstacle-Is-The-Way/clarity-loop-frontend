# Implementation Plan: Data Models (DTOs & SwiftData)

This document provides a detailed specification for all data models required for the CLARITY Pulse application. It is broken down into two main sections:
1.  **Data Transfer Objects (DTOs):** Plain `Codable` Swift structs that exactly match the JSON structure of the backend API. These are used in the Networking layer.
2.  **SwiftData Models:** `@Model` classes for local persistence and caching. These are used in the Persistence layer.

Place DTOs in the `Data/DTOs` group and SwiftData models in the `Data/Models` group.

---

## 1. Data Transfer Objects (DTOs)

These structs are used for encoding and decoding data for network requests. They must conform to `Codable`.

### 1.1. Utility DTOs

- [ ] **Create `AnyCodable.swift`:** Implement a generic `AnyCodable` wrapper to handle `[String: Any]` or dynamic JSON objects in responses, especially for `metadata` fields. There are standard open-source implementations available.
- [ ] **Create `MessageResponseDTO.swift`:** For simple `{"message": "..."}` responses.
    ```swift
    struct MessageResponseDTO: Codable {
        let message: String
    }
    ```
- [ ] **Create `ValidationErrorDTO.swift`:**
    ```swift
    struct ValidationErrorDTO: Codable {
        let field: String
        let message: String
        let code: String
    }
    ```

### 1.2. Authentication DTOs (`/api/v1/auth`)

- [ ] **`UserRegistrationRequestDTO.swift`**
    - `email: String`
    - `password: String`
    - `firstName: String`
    - `lastName: String`
    - `phoneNumber: String?`
    - `termsAccepted: Bool`
    - `privacyPolicyAccepted: Bool`
- [ ] **`RegistrationResponseDTO.swift`**
    - `userId: UUID`
    - `email: String`
    - `status: String`
    - `verificationEmailSent: Bool`
    - `createdAt: Date`
- [ ] **`UserLoginRequestDTO.swift`**
    - `email: String`
    - `password: String`
    - `rememberMe: Bool`
    - `deviceInfo: [String: AnyCodable]?`
- [ ] **`LoginResponseDTO.swift`**
    - `user: UserSessionResponseDTO`
    - `tokens: TokenResponseDTO`
- [ ] **`UserSessionResponseDTO.swift`**
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
- [ ] **`TokenResponseDTO.swift`**
    - `accessToken: String`
    - `refreshToken: String`
    - `tokenType: String`
    - `expiresIn: Int`
- [ ] **`RefreshTokenRequestDTO.swift`**
    - `refreshToken: String`

### 1.3. HealthKit Upload DTOs (`/api/v1/healthkit_upload`)

- [ ] **`HealthKitSampleDTO.swift`**
    - `identifier: String`
    - `type: String`
    - `value: AnyCodable` // Flexible to handle numbers or objects
    - `unit: String?`
    - `startDate: Date`
    - `endDate: Date`
    - `sourceName: String?`
    - `device: [String: AnyCodable]?`
    - `metadata: [String: AnyCodable]`
- [ ] **`HealthKitUploadRequestDTO.swift`**
    - `userId: String`
    - `quantitySamples: [HealthKitSampleDTO]`
    - `categorySamples: [HealthKitSampleDTO]`
    - `workouts: [AnyCodable]`
    - `correlationSamples: [AnyCodable]`
    - `uploadMetadata: [String: AnyCodable]`
    - `syncToken: String?`
- [ ] **`HealthKitUploadResponseDTO.swift`**
    - `uploadId: String`
    - `status: String`
    - `queuedAt: Date`
    - `samplesReceived: [String: Int]`
    - `message: String`
- [ ] **`HealthKitUploadStatusDTO.swift`**
    - `uploadId: String`
    - `status: String`
    - `progress: Double` // 0-1
    - `message: String`
    - `lastUpdated: Date`


### 1.4. Health Data DTOs (`/api/v1/health-data`)

- [ ] **`HealthMetricDTO.swift`**
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
- [ ] **`BiometricDataDTO.swift`**
    - `heartRate: Double?`
    - `bloodPressureSystolic: Int?`
    - `bloodPressureDiastolic: Int?`
    - `oxygenSaturation: Double?`
    - `heartRateVariability: Double?`
    - `respiratoryRate: Double?`
    - `bodyTemperature: Double?`
    - `bloodGlucose: Double?`
- [ ] **`SleepDataDTO.swift`**
    - `totalSleepMinutes: Int`
    - `sleepEfficiency: Double`
    - `timeToSleepMinutes: Int?`
    - `wakeCount: Int?`
    - `sleepStages: [String: Int]?`
    - `sleepStart: Date`
    - `sleepEnd: Date`
- [ ] **`ActivityDataDTO.swift`**
    - `steps: Int?`
    - `distance: Double?`
    - `activeEnergy: Double?`
    - `exerciseMinutes: Int?`
    - `flightsClimbed: Int?`
    - `vo2Max: Double?`
    - `activeMinutes: Int?`
    - `restingHeartRate: Double?`
- [ ] **`MentalHealthIndicatorDTO.swift`**
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
- [ ] **`PaginatedMetricsResponseDTO.swift`** (for `GET /health-data`)
    - `data: [HealthMetricDTO]`
    - `// Add pagination fields like 'links', 'meta' etc. as per final API spec`

### 1.5. PAT Analysis DTOs (`/api/v1/pat`)

- [ ] **`StepDataRequestDTO.swift`**
    - `stepCounts: [Int]`
    - `timestamps: [Date]`
    - `userMetadata: [String: AnyCodable]?`
- [ ] **`ActigraphyDataPointDTO.swift`**
    - `timestamp: Date`
    - `value: Double`
- [ ] **`DirectActigraphyRequestDTO.swift`**
    - `dataPoints: [ActigraphyDataPointDTO]`
    - `samplingRate: Double`
    - `durationHours: Int`
- [ ] **`AnalysisResponseDTO.swift`** (Generic wrapper)
    - `analysisId: String`
    - `status: String`
    - `analysis: T?` // Generic payload
    - `processingTimeMs: Double?`
    - `message: String?`
    - `cached: Bool`
- [ ] **`PATAnalysisResponseDTO.swift`** (for `GET /pat/analysis/{id}`)
    - `processingId: String`
    - `status: String`
    - `message: String?`
    - `analysisDate: Date?`
    - `patFeatures: [String: Double]?`
    - `activityEmbedding: [Double]?`
    - `metadata: [String: AnyCodable]?`
- [ ] **`PATServiceHealthDTO.swift`**
    - `service: String`
    - `status: String`
    - `timestamp: Date`
    - `version: String`
    - `inferenceEngine: [String: AnyCodable]`
    - `patModel: [String: AnyCodable]`


### 1.6. Gemini Insights DTOs (`/api/v1/insights`)

- [ ] **`InsightGenerationRequestDTO.swift`**
    - `analysisResults: [String: AnyCodable]`
    - `context: String?`
    - `insightType: String`
    - `includeRecommendations: Bool`
    - `language: String`
- [ ] **`InsightGenerationResponseDTO.swift`**
    - `success: Bool`
    - `data: HealthInsightDTO`
    - `metadata: [String: AnyCodable]`
- [ ] **`HealthInsightDTO.swift`**
    - `userId: String`
    - `narrative: String`
    - `keyInsights: [String]`
    - `recommendations: [String]`
    - `confidenceScore: Double`
    - `generatedAt: Date`
- [ ] **`InsightHistoryResponseDTO.swift`**
    - `success: Bool`
    - `data: InsightHistoryDataDTO`
    - `metadata: [String: AnyCodable]`
- [ ] **`InsightHistoryDataDTO.swift`**
    - `insights: [InsightPreviewDTO]`
    - `totalCount: Int`
    - `hasMore: Bool`
    - `pagination: PaginationMetaDTO`
- [ ] **`InsightPreviewDTO.swift`**
    - `id: String`
    - `narrative: String`
    - `generatedAt: Date`
    - `confidenceScore: Double`
    - `keyInsightsCount: Int`
    - `recommendationsCount: Int`
- [ ] **`PaginationMetaDTO.swift`**
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

- [ ] **`User.swift`**
    - `@Attribute(.unique) id: UUID`
    - `email: String`
    - `firstName: String`
    - `lastName: String`
    - `role: String`
    - `permissions: [String]`
    - `status: String`
    - `emailVerified: Bool`
    - `mfaEnabled: Bool`
    - `createdAt: Date`
    - `lastLogin: Date?`
    - `lastSyncedAt: Date` (local-only metadata)
- [ ] **`HealthMetricEntity.swift`** (Flattened structure for easy querying)
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
- [ ] **`InsightEntity.swift`**
    - `@Attribute(.unique) id: String`
    - `userId: String`
    - `narrative: String`
    - `keyInsights: [String]`
    - `recommendations: [String]`
    - `confidenceScore: Double`
    - `generatedAt: Date`
    - `lastViewedAt: Date?` (local-only metadata)
- [ ] **`PATAnalysisEntity.swift`** (Optional, if caching raw PAT results is desired)
    - `@Attribute(.unique) id: String`
    - `status: String`
    - `completedAt: Date?`
    - `patFeatures: Data?` (JSON-encoded dictionary)
    - `activityEmbedding: Data?` (JSON-encoded array)
    - `lastSyncedAt: Date`
- [ ] **Implement Mappings:** Create convenience initializers or mapping functions to convert between DTOs and SwiftData `@Model` entities. This logic should reside within a Repository or a dedicated Mapper class.
    - [ ] `HealthMetricEntity(from dto: HealthMetricDTO)`
    - [ ] `InsightEntity(from dto: HealthInsightDTO)`
    - [ ] `User(from dto: UserSessionResponseDTO)` 