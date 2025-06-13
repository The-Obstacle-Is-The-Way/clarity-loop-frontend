import Foundation
@testable import clarity_loop_frontend

// MARK: - Test Data Generators

extension UserSessionResponseDTO {
    static func mock(
        userId: UUID = UUID(),
        firstName: String = "Test",
        lastName: String = "User",
        email: String = "test@example.com",
        role: String = "patient",
        permissions: [String] = ["read_own_data", "write_own_data"],
        status: String = "active",
        mfaEnabled: Bool = false,
        emailVerified: Bool = true,
        createdAt: Date = Date(),
        lastLogin: Date? = Date()
    ) -> UserSessionResponseDTO {
        return UserSessionResponseDTO(
            userId: userId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            role: role,
            permissions: permissions,
            status: status,
            mfaEnabled: mfaEnabled,
            emailVerified: emailVerified,
            createdAt: createdAt,
            lastLogin: lastLogin
        )
    }
}

extension LoginResponseDTO {
    static func mock(
        user: UserSessionResponseDTO = .mock(),
        tokens: TokenResponseDTO = .mock()
    ) -> LoginResponseDTO {
        return LoginResponseDTO(
            user: user,
            tokens: tokens
        )
    }
}

extension TokenResponseDTO {
    static func mock(
        accessToken: String = "mock_access_token",
        refreshToken: String = "mock_refresh_token",
        tokenType: String = "bearer",
        expiresIn: Int = 3600
    ) -> TokenResponseDTO {
        return TokenResponseDTO(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: tokenType,
            expiresIn: expiresIn
        )
    }
}

extension RegistrationResponseDTO {
    static func mock(
        userId: UUID = UUID(),
        email: String = "newuser@example.com",
        status: String = "registered",
        verificationEmailSent: Bool = true,
        createdAt: Date = Date()
    ) -> RegistrationResponseDTO {
        return RegistrationResponseDTO(
            userId: userId,
            email: email,
            status: status,
            verificationEmailSent: verificationEmailSent,
            createdAt: createdAt
        )
    }
}

extension UserUpdateResponseDTO {
    static func mock(
        userId: UUID = UUID(),
        email: String = "updated@example.com",
        displayName: String = "Updated User",
        updated: Bool = true
    ) -> UserUpdateResponseDTO {
        return UserUpdateResponseDTO(
            userId: userId,
            email: email,
            displayName: displayName,
            updated: updated
        )
    }
}

extension MessageResponseDTO {
    static func mock(
        message: String = "Success"
    ) -> MessageResponseDTO {
        return MessageResponseDTO(
            message: message
        )
    }
}

// MARK: - Health Data Mocks

extension HealthKitDataDTO {
    static func mock(
        startDate: Date = Date().addingTimeInterval(-86400),
        endDate: Date = Date(),
        metrics: [HealthMetricDTO] = [.mockSteps(), .mockHeartRate()]
    ) -> HealthKitDataDTO {
        return HealthKitDataDTO(
            startDate: startDate,
            endDate: endDate,
            metrics: metrics
        )
    }
}

extension HealthMetricDTO {
    static func mockSteps() -> HealthMetricDTO {
        return HealthMetricDTO(
            type: "steps",
            value: 10000,
            unit: "count",
            timestamp: Date(),
            metadata: ["source": "Apple Watch"]
        )
    }
    
    static func mockHeartRate() -> HealthMetricDTO {
        return HealthMetricDTO(
            type: "heartRate",
            value: 72,
            unit: "bpm",
            timestamp: Date(),
            metadata: ["context": "resting"]
        )
    }
    
    static func mockSleep() -> HealthMetricDTO {
        return HealthMetricDTO(
            type: "sleep",
            value: 7.5,
            unit: "hours",
            timestamp: Date(),
            metadata: ["quality": "good"]
        )
    }
}

extension HealthKitUploadResponseDTO {
    static func mock(
        success: Bool = true,
        uploadId: String = UUID().uuidString,
        message: String = "Data uploaded successfully",
        metricsReceived: Int = 2,
        timestamp: Date = Date()
    ) -> HealthKitUploadResponseDTO {
        return HealthKitUploadResponseDTO(
            success: success,
            uploadId: uploadId,
            message: message,
            metricsReceived: metricsReceived,
            timestamp: timestamp
        )
    }
}

// MARK: - Edge Case Generators

struct TestDataEdgeCases {
    
    // Invalid email formats
    static let invalidEmails = [
        "notanemail",
        "@example.com",
        "user@",
        "user@.com",
        "user..name@example.com",
        "user@example",
        "user name@example.com"
    ]
    
    // Weak passwords
    static let weakPasswords = [
        "12345",
        "password",
        "abc123",
        "qwerty",
        ""
    ]
    
    // Extreme health metrics
    static func extremeHealthMetrics() -> [HealthMetricDTO] {
        return [
            // Zero values
            HealthMetricDTO(type: "steps", value: 0, unit: "count", timestamp: Date()),
            // Extremely high values
            HealthMetricDTO(type: "steps", value: 100000, unit: "count", timestamp: Date()),
            // Negative values (should fail)
            HealthMetricDTO(type: "heartRate", value: -50, unit: "bpm", timestamp: Date()),
            // Very high heart rate
            HealthMetricDTO(type: "heartRate", value: 250, unit: "bpm", timestamp: Date()),
            // Very low heart rate
            HealthMetricDTO(type: "heartRate", value: 20, unit: "bpm", timestamp: Date())
        ]
    }
    
    // Future and past dates
    static func edgeDateRanges() -> [(start: Date, end: Date)] {
        let now = Date()
        return [
            // Future dates
            (now.addingTimeInterval(86400), now.addingTimeInterval(172800)),
            // Very old dates
            (Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 86400)),
            // Reversed dates (end before start)
            (now, now.addingTimeInterval(-86400)),
            // Same start and end
            (now, now),
            // Very large range
            (now.addingTimeInterval(-31536000), now) // 1 year
        ]
    }
}

// MARK: - Random Data Generators

struct RandomTestDataGenerator {
    
    static func randomEmail() -> String {
        let domains = ["example.com", "test.com", "clarity.health", "demo.org"]
        let names = ["john", "jane", "test", "user", "patient", "doctor"]
        let numbers = Int.random(in: 1...9999)
        return "\(names.randomElement()!)\(numbers)@\(domains.randomElement()!)"
    }
    
    static func randomHealthMetrics(count: Int) -> [HealthMetricDTO] {
        let types = ["steps", "heartRate", "sleep", "hrv", "bloodPressure", "glucose"]
        let now = Date()
        
        return (0..<count).map { i in
            let type = types.randomElement()!
            let timestamp = now.addingTimeInterval(-Double(i * 3600)) // 1 hour intervals
            
            switch type {
            case "steps":
                return HealthMetricDTO(
                    type: type,
                    value: Double.random(in: 0...20000),
                    unit: "count",
                    timestamp: timestamp
                )
            case "heartRate":
                return HealthMetricDTO(
                    type: type,
                    value: Double.random(in: 50...120),
                    unit: "bpm",
                    timestamp: timestamp
                )
            case "sleep":
                return HealthMetricDTO(
                    type: type,
                    value: Double.random(in: 4...10),
                    unit: "hours",
                    timestamp: timestamp
                )
            case "hrv":
                return HealthMetricDTO(
                    type: type,
                    value: Double.random(in: 20...80),
                    unit: "ms",
                    timestamp: timestamp
                )
            default:
                return HealthMetricDTO(
                    type: type,
                    value: Double.random(in: 50...200),
                    unit: "unit",
                    timestamp: timestamp
                )
            }
        }
    }
    
    static func randomDateRange() -> (start: Date, end: Date) {
        let now = Date()
        let daysBack = Int.random(in: 1...30)
        let duration = Int.random(in: 1...7)
        
        let end = now.addingTimeInterval(-Double(daysBack * 86400))
        let start = end.addingTimeInterval(-Double(duration * 86400))
        
        return (start, end)
    }
}