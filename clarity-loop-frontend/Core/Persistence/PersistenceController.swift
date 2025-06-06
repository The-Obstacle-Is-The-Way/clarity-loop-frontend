import Foundation
import SwiftData

/// A singleton controller to manage the SwiftData stack for the application.
@MainActor
final class PersistenceController {
    
    /// The shared singleton instance of the persistence controller.
    static let shared = PersistenceController()

    /// The main SwiftData model container.
    let container: ModelContainer

    /// The private initializer to set up the schema and container.
    private init() {
        let schema = Schema([
            UserProfile.self,
            HealthMetricEntity.self,
            InsightEntity.self,
            PATAnalysisEntity.self,
        ])
        
        let config = ModelConfiguration("ClarityPulseDB", schema: schema, isStoredInMemoryOnly: false)

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // If the container fails to initialize, it's a critical, non-recoverable error.
            fatalError("Could not configure the model container: \(error)")
        }
    }
} 
 
