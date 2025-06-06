//
//  ChatViewModel.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation

/// A struct representing a single message in the chat interface.
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let sender: Sender
    var text: String
    var isError: Bool = false

    enum Sender {
        case user
        case assistant
    }
}

/// The ViewModel for the on-demand Gemini chat interface.
@MainActor
class ChatViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var isSending: Bool = false
    
    // MARK: - Dependencies
    
    private let insightsRepo: InsightsRepositoryProtocol
    
    // MARK: - Initializer
    
    init(insightsRepo: InsightsRepositoryProtocol) {
        self.insightsRepo = insightsRepo
    }
    
    // MARK: - Public Methods
    
    func sendMessage() {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = ChatMessage(sender: .user, text: currentInput)
        messages.append(userMessage)
        let tempInput = currentInput
        currentInput = ""
        
        isSending = true
        messages.append(ChatMessage(sender: .assistant, text: "..."))
        
        Task {
            do {
                // Placeholder for real analysis data
                let analysisResults: [String: AnyCodable] = ["steps": .double(10000)]
                
                let request = InsightGenerationRequestDTO(
                    analysisResults: analysisResults,
                    context: tempInput,
                    insightType: "brief",
                    includeRecommendations: true,
                    language: "en"
                )
                
                let response = try await insightsRepo.generateInsight(requestDTO: request)
                
                // Remove the "..." typing indicator
                _ = messages.popLast()
                
                let assistantMessage = ChatMessage(sender: .assistant, text: response.data.narrative)
                messages.append(assistantMessage)
                
            } catch {
                // Remove the "..." typing indicator
                _ = messages.popLast()
                
                let errorMessage = ChatMessage(sender: .assistant, text: "Sorry, I couldn't fetch that insight. Please try again.", isError: true)
                messages.append(errorMessage)
            }
            isSending = false
        }
    }
} 
