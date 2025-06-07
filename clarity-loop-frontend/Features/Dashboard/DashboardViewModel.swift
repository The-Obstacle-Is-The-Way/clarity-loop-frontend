//
//  DashboardViewModel.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation
import SwiftUI
import FirebaseAuth
import Observation

/// A struct to hold all the necessary data for the dashboard.
/// This will be expanded as more data sources are integrated.
struct DashboardData {
    let metrics: DailyHealthMetrics
    let insightOfTheDay: InsightPreviewDTO?
}

@Observable
final class DashboardViewModel {
    
    // MARK: - Properties
    
    var viewState: ViewState<DashboardData> = .idle
    
    // MARK: - Dependencies
    
    private let insightsRepo: InsightsRepositoryProtocol
    private let healthKitService: HealthKitServiceProtocol
    
    // MARK: - Initializer
    
    init(
        insightsRepo: InsightsRepositoryProtocol,
        healthKitService: HealthKitServiceProtocol
    ) {
        self.insightsRepo = insightsRepo
        self.healthKitService = healthKitService
    }
    
    // MARK: - Public Methods
    
    /// Loads all necessary data for the dashboard.
    func loadDashboard() async {
        viewState = .loading
        
        do {
            // Request HealthKit authorization before fetching data.
            try await healthKitService.requestAuthorization()
            
            // Fetch health metrics and insights in parallel
            async let metrics = healthKitService.fetchAllDailyMetrics(for: Date())
            let userId = Auth.auth().currentUser?.uid ?? "unknown"
            async let insightsResponse = insightsRepo.getInsightHistory(userId: userId, limit: 1, offset: 0)
            
            let (dailyMetrics, insights) = try await (metrics, insightsResponse)
            
            let data = DashboardData(metrics: dailyMetrics, insightOfTheDay: insights.data.insights.first)
            
            // The view is considered "empty" only if both metrics and insights are empty.
            let hasMetrics = data.metrics.stepCount > 0 || data.metrics.restingHeartRate != nil || data.metrics.sleepData != nil
            if !hasMetrics && data.insightOfTheDay == nil {
                viewState = .empty
            } else {
                viewState = .loaded(data)
            }
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }
} 
