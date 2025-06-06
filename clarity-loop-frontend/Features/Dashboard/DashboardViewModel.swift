//
//  DashboardViewModel.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation
import SwiftUI

/// A struct to hold all the necessary data for the dashboard.
/// This will be expanded as more data sources are integrated.
struct DashboardData {
    let metrics: [HealthMetricDTO]
    let insightOfTheDay: InsightPreviewDTO?
}

@MainActor
class DashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var viewState: ViewState<DashboardData> = .idle
    
    // MARK: - Dependencies
    
    private let healthDataRepo: HealthDataRepositoryProtocol
    private let insightsRepo: InsightsRepositoryProtocol
    
    // MARK: - Initializer
    
    init(
        healthDataRepo: HealthDataRepositoryProtocol,
        insightsRepo: InsightsRepositoryProtocol
    ) {
        self.healthDataRepo = healthDataRepo
        self.insightsRepo = insightsRepo
    }
    
    // MARK: - Public Methods
    
    /// Loads all necessary data for the dashboard.
    func loadDashboard() async {
        viewState = .loading
        
        do {
            // Fetch health metrics and insights in parallel
            async let metricsResponse = healthDataRepo.getHealthData(page: 1, limit: 20)
            async let insightsResponse = insightsRepo.getInsightHistory(userId: "current_user_id_placeholder", limit: 1, offset: 0) // Placeholder user ID
            
            let (metrics, insights) = try await (metricsResponse, insightsResponse)
            
            let data = DashboardData(metrics: metrics.data, insightOfTheDay: insights.data.insights.first)
            
            // The view is considered "empty" only if both metrics and insights are empty.
            if data.metrics.isEmpty && data.insightOfTheDay == nil {
                viewState = .empty
            } else {
                viewState = .loaded(data)
            }
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }
} 
