//
//  DashboardViewModel.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation
import Observation
import SwiftUI

/// A struct to hold all the necessary data for the dashboard.
/// This will be expanded as more data sources are integrated.
struct DashboardData: Equatable {
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
    private let authService: AuthServiceProtocol
    
    // MARK: - Initializer
    
    init(
        insightsRepo: InsightsRepositoryProtocol,
        healthKitService: HealthKitServiceProtocol,
        authService: AuthServiceProtocol
    ) {
        self.insightsRepo = insightsRepo
        self.healthKitService = healthKitService
        self.authService = authService
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
            let userId = await authService.currentUser?.id ?? "unknown"
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
    
    #if targetEnvironment(simulator)
    /// Loads sample data for simulator testing
    func loadSampleData() async {
        viewState = .loading
        
        // Create sample data for simulator
        let sampleMetrics = DailyHealthMetrics(
            date: Date(),
            stepCount: 8_247,
            restingHeartRate: 65.0,
            sleepData: SleepData(
                totalTimeInBed: 28_800,  // 8 hours
                totalTimeAsleep: 25_200, // 7 hours
                sleepEfficiency: 0.875
            )
        )
        
        let sampleInsight: InsightPreviewDTO? = InsightPreviewDTO(
            id: UUID().uuidString,
            narrative: "You achieved 7 hours of sleep with 87.5% efficiency. This is excellent for recovery and cognitive function. Your resting heart rate of 65 BPM indicates good cardiovascular fitness.",
            generatedAt: Date(),
            confidenceScore: 0.92,
            keyInsightsCount: 2,
            recommendationsCount: 1
        )
        
        let data = DashboardData(
            metrics: sampleMetrics,
            insightOfTheDay: sampleInsight
        )
        
        // Small delay to simulate loading
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        viewState = .loaded(data)
    }
    #endif
} 
