import XCTest
import SwiftData
@testable import clarity_loop_frontend

@MainActor
final class PersistenceControllerTests: XCTestCase {

    var container: ModelContainer!

    override func setUp() {
        super.setUp()
        // Use an in-memory store for testing to avoid side effects.
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema([
            UserProfile.self,
            HealthMetricEntity.self,
            InsightEntity.self,
            PATAnalysisEntity.self
        ])
        
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            XCTFail("Failed to create ModelContainer for testing: \(error)")
        }
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    func testContainerInitialization() {
        XCTAssertNotNil(container, "The ModelContainer should not be nil.")
    }
    
    func testSaveAndFetchUserProfile() throws {
        // Given
        let userProfile = UserProfile(
            id: UUID(),
            email: "test@example.com",
            firstName: "Test",
            lastName: "User",
            role: "user",
            permissions: [],
            status: "active",
            emailVerified: true,
            mfaEnabled: false,
            createdAt: Date(),
            lastLogin: nil
        )
        
        // When
        container.mainContext.insert(userProfile)
        try container.mainContext.save()
        
        // Then
        let descriptor = FetchDescriptor<UserProfile>()
        let fetchedProfiles = try container.mainContext.fetch(descriptor)
        
        XCTAssertEqual(fetchedProfiles.count, 1)
        XCTAssertEqual(fetchedProfiles.first?.email, "test@example.com")
    }
} 