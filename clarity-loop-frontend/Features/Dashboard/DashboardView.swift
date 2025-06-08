//
//  DashboardView.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import FirebaseAuth
import SwiftUI

struct DashboardView: View {
    @Environment(\.healthKitService) private var healthKitService
    @Environment(\.insightsRepository) private var insightsRepository
    
    @State private var viewModel: DashboardViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
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
                            
                            HealthMetricCardView(
                                title: "Steps",
                                value: String(format: "%.0f", data.metrics.stepCount),
                                systemImageName: "figure.walk"
                            )
                            
                            if let rhr = data.metrics.restingHeartRate {
                                HealthMetricCardView(
                                    title: "Resting Heart Rate",
                                    value: String(format: "%.0f", rhr) + " BPM",
                                    systemImageName: "heart.fill"
                                )
                            }
                            
                            if let sleep = data.metrics.sleepData {
                                HealthMetricCardView(
                                    title: "Time Asleep",
                                    value: String(format: "%.1f", sleep.totalTimeAsleep / 3600) + " hr",
                                    systemImageName: "bed.double.fill"
                                )
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadDashboard()
                    }
                case .empty:
                    VStack(spacing: 16) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Welcome to CLARITY Pulse!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        #if targetEnvironment(simulator)
                        Text("You're running in the simulator. To see real health data, run the app on a physical device with HealthKit data.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Load Sample Data") {
                            Task {
                                await viewModel.loadSampleData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        #else
                        Text("Start tracking your health by walking around with your iPhone or connecting your Apple Watch.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Enable HealthKit") {
                            Task {
                                await viewModel.loadDashboard()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        #endif
                    }
                    .padding()
                case .error(let errorMessage):
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Oops, something went wrong.")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Try Again") {
                            Task {
                                await viewModel.loadDashboard()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                    .padding()
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Your Pulse")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ChatView()) {
                        Image(systemName: "bubble.left.and.bubble.right")
                    }
                }
            }
            .task {
                if viewModel == nil {
                    viewModel = DashboardViewModel(
                        insightsRepo: insightsRepository,
                        healthKitService: healthKitService
                    )
                }
                
                if let vm = viewModel, case .idle = vm.viewState {
                    await vm.loadDashboard()
                }
            }
        }
    }
}

#Preview {
    guard let previewAPIClient = APIClient(
        baseURLString: AppConfig.previewAPIBaseURL,
        tokenProvider: { nil }
    ) else {
        return DashboardView()
    }
    
    return DashboardView()
        .environment(\.healthKitService, HealthKitService(apiClient: previewAPIClient))
        .environment(\.insightsRepository, RemoteInsightsRepository(apiClient: previewAPIClient))
} 
