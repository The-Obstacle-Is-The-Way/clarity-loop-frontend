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
}

@MainActor
class DashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var viewState: ViewState<DashboardData> = .idle
    
    // MARK: - Dependencies
    
    private let healthDataRepo: HealthDataRepositoryProtocol
    
    // MARK: - Initializer
    
    init(
        healthDataRepo: HealthDataRepositoryProtocol
    ) {
        self.healthDataRepo = healthDataRepo
    }
    
    // MARK: - Public Methods
    
    /// Loads all necessary data for the dashboard.
    func loadDashboard() async {
        viewState = .loading
        
        do {
            let response = try await healthDataRepo.getHealthData(page: 1, limit: 20)
            let data = DashboardData(metrics: response.data)
            
            if data.metrics.isEmpty {
                viewState = .empty
            } else {
                viewState = .loaded(data)
            }
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }
} 
