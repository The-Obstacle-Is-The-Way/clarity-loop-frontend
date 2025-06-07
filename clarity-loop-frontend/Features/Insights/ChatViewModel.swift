//
//  ChatViewModel.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation
import Observation

/// The ViewModel for the on-demand Gemini chat interface.
@Observable
final class ChatViewModel {
    
    // MARK: - Properties
    
    var messages: [ChatMessage] = []
    var currentInput: String = ""
    var isSending: Bool = false
    
    // MARK: - Dependencies
    
    private let insightAIService: InsightAIServiceProtocol
    
    // MARK: - Initializer
    
    init(insightAIService: InsightAIServiceProtocol) {
        self.insightAIService = insightAIService
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
                let response = try await insightAIService.generateChatResponse(
                    userMessage: tempInput,
                    conversationHistory: messages,
                    healthContext: nil
                )
                
                // Remove the "..." typing indicator
                _ = messages.popLast()
                
                let assistantMessage = ChatMessage(sender: .assistant, text: response.narrative)
                messages.append(assistantMessage)
                
            } catch {
                // Remove the "..." typing indicator
                _ = messages.popLast()
                
                let errorMessage = ChatMessage(sender: .assistant, text: "Sorry, I couldn't process your request. Please try again.", isError: true)
                messages.append(errorMessage)
            }
            isSending = false
        }
    }
} 
