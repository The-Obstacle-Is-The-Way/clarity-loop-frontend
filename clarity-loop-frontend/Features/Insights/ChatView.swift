//
//  ChatView.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import FirebaseAuth
import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    
    // Custom initializer to inject dependencies
    init() {
        // This is a temporary solution for dependency injection.
        // A proper composition root will be established later.
        guard let apiClient = APIClient(tokenProvider: {
            try? await Auth.auth().currentUser?.getIDToken()
        }) else {
            fatalError("Failed to initialize APIClient")
        }
        let insightsRepo = RemoteInsightsRepository(apiClient: apiClient)
        _viewModel = StateObject(wrappedValue: ChatViewModel(insightsRepo: insightsRepo))
    }

    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                        }
                    }
                    .onChange(of: viewModel.messages.count) { _ in
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
                TextField("Ask about your health...", text: $viewModel.currentInput)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: viewModel.sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                }
                .disabled(viewModel.isSending || viewModel.currentInput.isEmpty)
            }
            .padding()
        }
        .navigationTitle("AI Assistant")
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatView()
        }
    }
} 
