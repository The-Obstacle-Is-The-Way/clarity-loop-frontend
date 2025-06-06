//
//  DashboardView.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import FirebaseAuth
import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    
    // Custom initializer to inject dependencies
    init() {
        // This is a temporary solution for dependency injection.
        // A proper composition root will be established later.
        guard let apiClient = APIClient(tokenProvider: {
            try? await Auth.auth().currentUser?.getIDToken()
        }) else {
            fatalError("Failed to initialize APIClient")
        }
        let healthDataRepo = RemoteHealthDataRepository(apiClient: apiClient)
        let insightsRepo = RemoteInsightsRepository(apiClient: apiClient)
        _viewModel = StateObject(wrappedValue: DashboardViewModel(healthDataRepo: healthDataRepo, insightsRepo: insightsRepo))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.viewState {
                case .idle:
                    Color.clear // Nothing shown
                case .loading:
                    ProgressView("Loading your pulse...")
                case .loaded(let data):
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if let insight = data.insightOfTheDay {
                                InsightCardView(insight: insight)
                            }
                            
                            ForEach(data.metrics) { metric in
                                HealthMetricCardView(metric: metric)
                            }
                        }
                        .padding()
                    }
                case .empty:
                    Text("No Health Data Available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                case .error(let errorMessage):
                    VStack {
                        Text("Oops, something went wrong.")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task {
                                await viewModel.loadDashboard()
                            }
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Your Pulse")
            .task {
                if case .idle = viewModel.viewState {
                    await viewModel.loadDashboard()
                }
            }
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        // The preview will use the mock repository by default
        DashboardView()
    }
} 
