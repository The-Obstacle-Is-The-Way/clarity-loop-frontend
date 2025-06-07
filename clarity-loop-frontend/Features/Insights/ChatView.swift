//
//  ChatView.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import FirebaseAuth
import SwiftUI

struct ChatView: View {
    @State private var viewModel: ChatViewModel?

    var body: some View {
        VStack {
            if let viewModel = viewModel {
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(message: message)
                            }
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            // Scroll to the bottom when a new message arrives
                            if let lastMessage = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                HStack {
                    TextField("Ask about your health...", text: Binding(
                        get: { viewModel.currentInput },
                        set: { viewModel.currentInput = $0 }
                    ))
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: viewModel.sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                    }
                    .disabled(viewModel.isSending || viewModel.currentInput.isEmpty)
                }
                .padding()
            } else {
                ProgressView("Loading...")
            }
        }
        .navigationTitle("AI Assistant")
        .task {
            if viewModel == nil {
                guard let apiClient = APIClient(tokenProvider: {
                    try? await Auth.auth().currentUser?.getIDToken()
                }) else {
                    return
                }
                let insightAIService = InsightAIService(apiClient: apiClient)
                viewModel = ChatViewModel(insightAIService: insightAIService)
            }
        }
    }
}

#Preview {
    NavigationView {
        ChatView()
    }
} 
