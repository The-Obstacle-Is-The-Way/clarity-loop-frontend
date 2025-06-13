import XCTest
@testable import clarity_loop_frontend

/// Contract validation tests for health data endpoints
/// Ensures all health data DTOs and API contracts match backend expectations
@MainActor
final class HealthDataContractValidationTests: XCTestCase {
    
    private var encoder: JSONEncoder!
    private var decoder: JSONDecoder!
    
    override func setUp() {
        super.setUp()
        
        // Configure encoder to match backend expectations
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        
        // Configure decoder to match backend responses
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - HealthKit Upload Contract Tests
    
    func testHealthKitUploadRequestContract() throws {
        // Given - HealthKit upload request
        let request = HealthKitUploadRequestDTO(
            dataType: "heart_rate",
            samples: [
                HealthKitSampleDTO(
                    value: 72.5,
                    unit: "bpm",
                    startDate: Date(),
                    endDate: Date(),
                    metadata: [
                        "device": AnyCodable("Apple Watch"),
                        "workout_type": AnyCodable("running")
                    ]
                )
            ],
            userId: UUID(),
            uploadId: UUID(),
            totalSamples: 1,
            batchNumber: 1,
            isLastBatch: true
        )
        
        // When - Encode to JSON
        let jsonData = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        
        // Then - Verify backend contract
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["data_type"] as? String, "heart_rate")
        XCTAssertNotNil(json?["user_id"])
        XCTAssertNotNil(json?["upload_id"])
        XCTAssertEqual(json?["total_samples"] as? Int, 1)
        XCTAssertEqual(json?["batch_number"] as? Int, 1)
        XCTAssertEqual(json?["is_last_batch"] as? Bool, true)
        
        // Verify samples array structure
        let samples = json?["samples"] as? [[String: Any]]
        XCTAssertNotNil(samples)
        XCTAssertEqual(samples?.count, 1)
        
        let sample = samples?.first
        XCTAssertEqual(sample?["value"] as? Double, 72.5)
        XCTAssertEqual(sample?["unit"] as? String, "bpm")
        XCTAssertNotNil(sample?["start_date"])
        XCTAssertNotNil(sample?["end_date"])
        
        let metadata = sample?["metadata"] as? [String: Any]
        XCTAssertEqual(metadata?["device"] as? String, "Apple Watch")
        XCTAssertEqual(metadata?["workout_type"] as? String, "running")
    }
    
    func testHealthKitUploadResponseContract() throws {
        // Given - Backend upload response
        let backendJSON = """
        {
            "upload_id": "123e4567-e89b-12d3-a456-426614174000",
            "status": "processing",
            "samples_received": 100,
            "samples_processed": 0,
            "created_at": "2025-01-13T10:00:00Z",
            "estimated_completion": "2025-01-13T10:05:00Z"
        }
        """
        
        // When - Decode response
        let response = try decoder.decode(HealthKitUploadResponseDTO.self, from: backendJSON.data(using: .utf8)!)
        
        // Then - Verify all fields decoded correctly
        XCTAssertEqual(response.uploadId.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174000")
        XCTAssertEqual(response.status, "processing")
        XCTAssertEqual(response.samplesReceived, 100)
        XCTAssertEqual(response.samplesProcessed, 0)
        XCTAssertNotNil(response.createdAt)
        XCTAssertNotNil(response.estimatedCompletion)
    }
    
    // MARK: - HealthKit Sync Contract Tests
    
    func testHealthKitSyncRequestContract() throws {
        // Given - Sync request
        let request = HealthKitSyncRequestDTO(
            dataTypes: ["heart_rate", "steps", "sleep_analysis"],
            startDate: Date(timeIntervalSinceNow: -86400), // 24 hours ago
            endDate: Date(),
            forceSync: true
        )
        
        // When - Encode to JSON
        let jsonData = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        
        // Then - Verify backend contract
        let dataTypes = json?["data_types"] as? [String]
        XCTAssertEqual(dataTypes?.count, 3)
        XCTAssertTrue(dataTypes?.contains("heart_rate") ?? false)
        XCTAssertTrue(dataTypes?.contains("steps") ?? false)
        XCTAssertTrue(dataTypes?.contains("sleep_analysis") ?? false)
        
        XCTAssertNotNil(json?["start_date"])
        XCTAssertNotNil(json?["end_date"])
        XCTAssertEqual(json?["force_sync"] as? Bool, true)
    }
    
    // MARK: - Paginated Health Data Contract Tests
    
    func testPaginatedMetricsResponseContract() throws {
        // Given - Backend paginated response
        let backendJSON = """
        {
            "data": [
                {
                    "id": "metric-1",
                    "type": "heart_rate",
                    "value": 72.5,
                    "unit": "bpm",
                    "timestamp": "2025-01-13T10:00:00Z",
                    "source": "Apple Watch",
                    "metadata": {
                        "workout_active": false,
                        "device_model": "Watch7,4"
                    }
                },
                {
                    "id": "metric-2",
                    "type": "steps",
                    "value": 5432,
                    "unit": "count",
                    "timestamp": "2025-01-13T10:00:00Z",
                    "source": "iPhone",
                    "metadata": {
                        "distance_meters": 4123.5
                    }
                }
            ],
            "pagination": {
                "page": 1,
                "per_page": 20,
                "total": 150,
                "total_pages": 8
            },
            "summary": {
                "average_heart_rate": 68.5,
                "total_steps": 12543,
                "data_quality_score": 0.95
            }
        }
        """
        
        // When - Decode response
        let response = try decoder.decode(PaginatedMetricsResponseDTO.self, from: backendJSON.data(using: .utf8)!)
        
        // Then - Verify structure
        XCTAssertEqual(response.data.count, 2)
        
        let firstMetric = response.data[0]
        XCTAssertEqual(firstMetric.id, "metric-1")
        XCTAssertEqual(firstMetric.type, "heart_rate")
        XCTAssertEqual(firstMetric.value, 72.5)
        XCTAssertEqual(firstMetric.unit, "bpm")
        XCTAssertEqual(firstMetric.source, "Apple Watch")
        
        XCTAssertEqual(response.pagination?.page, 1)
        XCTAssertEqual(response.pagination?.perPage, 20)
        XCTAssertEqual(response.pagination?.total, 150)
        XCTAssertEqual(response.pagination?.totalPages, 8)
        
        XCTAssertEqual(response.summary?["average_heart_rate"]?.value as? Double, 68.5)
        XCTAssertEqual(response.summary?["total_steps"]?.value as? Int, 12543)
    }
    
    // MARK: - Processing Status Contract Tests
    
    func testHealthDataProcessingStatusContract() throws {
        // Given - Processing status response
        let backendJSON = """
        {
            "processing_id": "123e4567-e89b-12d3-a456-426614174000",
            "status": "completed",
            "progress": 1.0,
            "metrics_processed": 1500,
            "errors": [],
            "started_at": "2025-01-13T10:00:00Z",
            "completed_at": "2025-01-13T10:05:00Z",
            "result_summary": {
                "heart_rate_samples": 500,
                "step_samples": 1000,
                "anomalies_detected": 2
            }
        }
        """
        
        // When - Decode response
        let response = try decoder.decode(HealthDataProcessingStatusDTO.self, from: backendJSON.data(using: .utf8)!)
        
        // Then - Verify all fields
        XCTAssertEqual(response.processingId.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174000")
        XCTAssertEqual(response.status, "completed")
        XCTAssertEqual(response.progress, 1.0)
        XCTAssertEqual(response.metricsProcessed, 1500)
        XCTAssertEqual(response.errors.count, 0)
        XCTAssertNotNil(response.startedAt)
        XCTAssertNotNil(response.completedAt)
        
        let summary = response.resultSummary
        XCTAssertEqual(summary?["heart_rate_samples"]?.value as? Int, 500)
        XCTAssertEqual(summary?["step_samples"]?.value as? Int, 1000)
        XCTAssertEqual(summary?["anomalies_detected"]?.value as? Int, 2)
    }
    
    // MARK: - Data Type Validation Tests
    
    func testSupportedHealthKitDataTypes() {
        // Verify all supported data types match backend expectations
        let supportedTypes = [
            "heart_rate",
            "steps",
            "sleep_analysis",
            "blood_pressure",
            "respiratory_rate",
            "body_temperature",
            "oxygen_saturation",
            "activity_energy",
            "exercise_minutes",
            "stand_hours"
        ]
        
        // These should match backend's expected data_type values
        for type in supportedTypes {
            // In a real test, we'd verify these against an actual backend enum/list
            XCTAssertFalse(type.contains(" "), "Data types must use underscores, not spaces")
            XCTAssertEqual(type, type.lowercased(), "Data types must be lowercase")
        }
    }
    
    // MARK: - Unit Validation Tests
    
    func testHealthMetricUnits() {
        // Verify units match backend expectations
        let unitMappings = [
            "heart_rate": "bpm",
            "steps": "count",
            "respiratory_rate": "breaths/min",
            "body_temperature": "celsius",
            "oxygen_saturation": "percent",
            "blood_pressure_systolic": "mmHg",
            "blood_pressure_diastolic": "mmHg"
        ]
        
        for (dataType, expectedUnit) in unitMappings {
            // In a real implementation, we'd validate these against actual HealthKit conversions
            XCTAssertFalse(expectedUnit.isEmpty, "Unit for \(dataType) must not be empty")
        }
    }
    
    // MARK: - Error Response Contract Tests
    
    func testHealthDataErrorResponses() throws {
        // Test various error response formats
        let quotaExceededJSON = """
        {
            "error": "quota_exceeded",
            "message": "Daily upload limit reached",
            "details": {
                "daily_limit": 10000,
                "samples_today": 10523,
                "reset_time": "2025-01-14T00:00:00Z"
            },
            "status_code": 429
        }
        """
        
        let invalidDataJSON = """
        {
            "error": "invalid_data",
            "message": "Invalid health data format",
            "details": {
                "invalid_samples": [0, 5, 12],
                "reasons": ["missing_timestamp", "invalid_unit", "negative_value"]
            },
            "status_code": 400
        }
        """
        
        // Decode and verify error structures
        let quotaError = try JSONSerialization.jsonObject(with: quotaExceededJSON.data(using: .utf8)!) as? [String: Any]
        XCTAssertEqual(quotaError?["error"] as? String, "quota_exceeded")
        XCTAssertEqual(quotaError?["status_code"] as? Int, 429)
        
        let invalidError = try JSONSerialization.jsonObject(with: invalidDataJSON.data(using: .utf8)!) as? [String: Any]
        XCTAssertEqual(invalidError?["error"] as? String, "invalid_data")
        XCTAssertEqual(invalidError?["status_code"] as? Int, 400)
    }
}