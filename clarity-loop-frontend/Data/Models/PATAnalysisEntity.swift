import Foundation
import SwiftData

/// Represents the cached results of a PAT (Pretrained Actigraphy Transformer) analysis.
///
/// This model is optional and should be used if the app needs to display raw PAT
/// analysis results frequently without re-fetching from the server.
@Model
final class PATAnalysisEntity {
    /// The unique identifier for the analysis job.
    @Attribute(.unique) var id: String

    /// The processing status of the analysis (e.g., "completed", "failed").
    var status: String

    /// The timestamp when the analysis was completed.
    var completedAt: Date?

    /// A JSON-encoded dictionary of the extracted PAT features.
    var patFeatures: Data?

    /// A JSON-encoded array representing the activity embedding vector.
    var activityEmbedding: Data?

    /// A local-only timestamp indicating when this record was last synced.
    var lastSyncedAt: Date
    
    init(
        id: String,
        status: String,
        completedAt: Date?,
        patFeatures: Data?,
        activityEmbedding: Data?,
        lastSyncedAt: Date
    ) {
        self.id = id
        self.status = status
        self.completedAt = completedAt
        self.patFeatures = patFeatures
        self.activityEmbedding = activityEmbedding
        self.lastSyncedAt = lastSyncedAt
    }
} 
 
