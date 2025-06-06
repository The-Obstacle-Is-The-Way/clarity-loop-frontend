//
//  DashboardView.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.viewState {
                case .idle:
                    Color.clear // Nothing shown
                case .loading:
                    ProgressView("Loading your pulse...")
                case .loaded(let data):
                    // This is where the main dashboard content will go.
                    // For now, it's just a placeholder.
                    Text("Dashboard Content Loaded")
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
                await viewModel.loadDashboard()
            }
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
} 
