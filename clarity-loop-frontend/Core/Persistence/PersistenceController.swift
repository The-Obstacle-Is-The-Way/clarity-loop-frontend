import Foundation
import SwiftData

/// A manager for the app's SwiftData stack.
///
/// This class is a singleton responsible for setting up and providing the `ModelContainer`.
/// It ensures that the database is configured with the correct schema upon app launch.
@MainActor
final class PersistenceController {
    /// The shared singleton instance of the persistence controller.
    static let shared = PersistenceController()

    /// The SwiftData model container.
    let container: ModelContainer

    private init() {
        // Define the schema with all @Model classes that need to be persisted.
        let schema = Schema([
            UserProfile.self,
            HealthMetricEntity.self,
            InsightEntity.self,
            PATAnalysisEntity.self,
        ])
        
        // Create the model configuration. The name is the filename for the SQLite database.
        let modelConfiguration = ModelConfiguration(
            "ClarityPulse",
            schema: schema,
            isStoredInMemoryOnly: false // Use a disk-based store for production.
        )

        do {
            // Initialize the container with the schema and configuration.
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If the container fails to initialize, it's a fatal error for the app.
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
} 
 
