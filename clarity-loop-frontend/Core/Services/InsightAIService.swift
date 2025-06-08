import Foundation
import Observation

@Observable
final class InsightAIService {
    
    // MARK: - Properties
    private let apiClient: APIClientProtocol
    
    // MARK: - Initialization
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    // MARK: - Public Methods
    
    func generateInsight(
        from analysisResults: [String: Any],
        context: String? = nil,
        insightType: String = "daily_summary",
        includeRecommendations: Bool = true,
        language: String = "en"
    ) async throws -> HealthInsightDTO {
        let request = InsightGenerationRequestDTO(
            analysisResults: analysisResults.mapValues { AnyCodable($0) },
            context: context,
            insightType: insightType,
            includeRecommendations: includeRecommendations,
            language: language
        )
        
        let response = try await apiClient.generateInsight(requestDTO: request)
        return response.data
    }
    
    func generateInsightFromHealthData(
        metrics: [HealthMetricDTO],
        patAnalysis: [String: Any]? = nil,
        customContext: String? = nil
    ) async throws -> HealthInsightDTO {
        // Convert health metrics to analysis format
        var analysisResults: [String: Any] = [:]
        
        // Group metrics by type
        let groupedMetrics = Dictionary(grouping: metrics) { $0.metricType }
        
        for (metricType, metricList) in groupedMetrics {
            switch metricType {
            case "steps":
                analysisResults["daily_steps"] = metricList.compactMap { $0.activityData?.steps }.reduce(0, +)
            case "heart_rate":
                let heartRates = metricList.compactMap { $0.biometricData?.heartRate }
                if !heartRates.isEmpty {
                    analysisResults["avg_heart_rate"] = heartRates.reduce(0, +) / Double(heartRates.count)
                    analysisResults["max_heart_rate"] = heartRates.max()
                    analysisResults["min_heart_rate"] = heartRates.min()
                }
            case "sleep":
                let sleepData = metricList.compactMap { $0.sleepData }
                if !sleepData.isEmpty {
                    analysisResults["total_sleep_minutes"] = sleepData.map { $0.totalSleepMinutes }.reduce(0, +)
                    analysisResults["avg_sleep_efficiency"] = sleepData.map { $0.sleepEfficiency }.reduce(0, +) / Double(sleepData.count)
                }
            default:
                break
            }
        }
        
        // Include PAT analysis if available
        if let patAnalysis = patAnalysis {
            analysisResults["pat_analysis"] = patAnalysis
        }
        
        let context = customContext ?? "Generate insights based on the user's recent health data patterns."
        
        return try await generateInsight(
            from: analysisResults,
            context: context,
            insightType: "health_summary"
        )
    }
    
    func generateChatResponse(
        userMessage: String,
        conversationHistory: [ChatMessage] = [],
        healthContext: [String: Any]? = nil
    ) async throws -> HealthInsightDTO {
        // Build context from conversation history
        var contextParts: [String] = []
        
        // Add recent conversation for context
        let recentMessages = conversationHistory.suffix(6) // Last 6 messages for context
        for message in recentMessages {
            let role = message.sender == .user ? "User" : "Assistant"
            contextParts.append("\(role): \(message.text)")
        }
        
        // Add current user message
        contextParts.append("User: \(userMessage)")
        
        let conversationContext = contextParts.joined(separator: "\n")
        
        var analysisResults: [String: Any] = [
            "user_question": userMessage,
            "conversation_context": conversationContext,
        ]
        
        // Include health context if available
        if let healthContext = healthContext {
            analysisResults["health_data_context"] = healthContext
        }
        
        return try await generateInsight(
            from: analysisResults,
            context: "Respond to the user's health-related question in a conversational manner. Be helpful, accurate, and empathetic. If medical advice is requested, remind the user to consult healthcare professionals.",
            insightType: "chat_response",
            includeRecommendations: false
        )
    }
    
    func getInsightHistory(userId: String, limit: Int = 20, offset: Int = 0) async throws -> InsightHistoryResponseDTO {
        return try await apiClient.getInsightHistory(userId: userId, limit: limit, offset: offset)
    }
    
    func checkServiceStatus() async throws -> ServiceStatusResponseDTO {
        return try await apiClient.getInsightsServiceStatus()
    }
}

// MARK: - Protocol
protocol InsightAIServiceProtocol {
    func generateInsight(
        from analysisResults: [String: Any],
        context: String?,
        insightType: String,
        includeRecommendations: Bool,
        language: String
    ) async throws -> HealthInsightDTO
    
    func generateInsightFromHealthData(
        metrics: [HealthMetricDTO],
        patAnalysis: [String: Any]?,
        customContext: String?
    ) async throws -> HealthInsightDTO
    
    func generateChatResponse(
        userMessage: String,
        conversationHistory: [ChatMessage],
        healthContext: [String: Any]?
    ) async throws -> HealthInsightDTO
    
    func getInsightHistory(userId: String, limit: Int, offset: Int) async throws -> InsightHistoryResponseDTO
    
    func checkServiceStatus() async throws -> ServiceStatusResponseDTO
}

extension InsightAIService: InsightAIServiceProtocol {}

// MARK: - Supporting Types
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let sender: Sender
    var text: String
    var timestamp: Date = Date()
    var isError: Bool = false
    
    enum Sender: String, CaseIterable {
        case user = "user"
        case assistant = "assistant"
    }
}
