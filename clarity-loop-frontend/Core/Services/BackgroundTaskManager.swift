//
//  BackgroundTaskManager.swift
//  clarity-loop-frontend
//
//  Created by Assistant on 6/8/25.
//

import BackgroundTasks
import Foundation
import OSLog

/// Protocol defining background task management operations
protocol BackgroundTaskManagerProtocol {
    func registerBackgroundTasks()
    func scheduleHealthDataSync()
    func scheduleAppRefresh()
    func handleHealthDataSync() async -> Bool
    func handleAppRefresh() async -> Bool
}

/// Manages background task scheduling and execution for health data sync
@MainActor
final class BackgroundTaskManager: BackgroundTaskManagerProtocol {
    
    // MARK: - Constants
    
    private enum TaskIdentifier {
        static let healthDataSync = "com.novamindnyc.clarity-loop-frontend.healthDataSync"
        static let appRefresh = "com.novamindnyc.clarity-loop-frontend.appRefresh"
    }
    
    private enum Constants {
        static let minBackgroundFetchInterval: TimeInterval = 3600 // 1 hour
        static let preferredBackgroundFetchInterval: TimeInterval = 14400 // 4 hours
        static let maxDataAge: TimeInterval = 86400 // 24 hours
    }
    
    // MARK: - Properties
    
    private let healthKitService: HealthKitServiceProtocol
    private let healthDataRepository: HealthDataRepositoryProtocol
    private let logger = Logger(subsystem: "com.novamindnyc.clarity-loop-frontend", category: "BackgroundTaskManager")
    
    // MARK: - Singleton
    
    static let shared: BackgroundTaskManager = {
        // Get services from the app's environment
        guard let healthKitService = ServiceLocator.shared.healthKitService,
              let healthDataRepository = ServiceLocator.shared.healthDataRepository else {
            fatalError("Required services not available for BackgroundTaskManager")
        }
        
        return BackgroundTaskManager(
            healthKitService: healthKitService,
            healthDataRepository: healthDataRepository
        )
    }()
    
    // MARK: - Initializer
    
    init(healthKitService: HealthKitServiceProtocol, healthDataRepository: HealthDataRepositoryProtocol) {
        self.healthKitService = healthKitService
        self.healthDataRepository = healthDataRepository
    }
    
    // MARK: - Public Methods
    
    /// Registers background tasks with the system
    func registerBackgroundTasks() {
        // Register health data sync task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifier.healthDataSync,
            using: nil
        ) { task in
            Task { @MainActor in
                await self.handleBackgroundTask(task as! BGProcessingTask)
            }
        }
        
        // Register app refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifier.appRefresh,
            using: nil
        ) { task in
            Task { @MainActor in
                await self.handleAppRefreshTask(task as! BGAppRefreshTask)
            }
        }
        
        logger.info("Background tasks registered successfully")
    }
    
    /// Schedules a background task for health data sync
    func scheduleHealthDataSync() {
        let request = BGProcessingTaskRequest(identifier: TaskIdentifier.healthDataSync)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: Constants.minBackgroundFetchInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Health data sync background task scheduled")
        } catch {
            logger.error("Failed to schedule health data sync: \(error.localizedDescription)")
        }
    }
    
    /// Schedules an app refresh task
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: TaskIdentifier.appRefresh)
        request.earliestBeginDate = Date(timeIntervalSinceNow: Constants.preferredBackgroundFetchInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("App refresh background task scheduled")
        } catch {
            logger.error("Failed to schedule app refresh: \(error.localizedDescription)")
        }
    }
    
    /// Handles health data sync in the background
    @MainActor
    func handleHealthDataSync() async -> Bool {
        logger.info("Starting background health data sync")
        
        do {
            // Get the date range for sync
            let endDate = Date()
            let startDate = endDate.addingTimeInterval(-Constants.maxDataAge)
            
            // Sync health data
            let syncRequest = HealthKitSyncRequestDTO(
                userId: ServiceLocator.shared.currentUserId ?? "",
                startDate: startDate,
                endDate: endDate,
                dataTypes: ["stepCount", "heartRate", "sleepAnalysis"],
                forceRefresh: false
            )
            
            let syncResponse = try await healthDataRepository.syncHealthKitData(requestDTO: syncRequest)
            
            if syncResponse.success {
                logger.info("Background health data sync completed successfully")
                
                // Schedule next sync
                scheduleHealthDataSync()
                
                return true
            } else {
                logger.error("Background health data sync failed: \(syncResponse.message ?? "Unknown error")")
                return false
            }
            
        } catch {
            logger.error("Background health data sync error: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Handles app refresh in the background
    @MainActor
    func handleAppRefresh() async -> Bool {
        logger.info("Starting background app refresh")
        
        // Perform lightweight tasks like checking for new insights
        // This is less intensive than full health data sync
        
        do {
            // Check if user is authenticated
            guard let userId = ServiceLocator.shared.currentUserId else {
                logger.info("User not authenticated, skipping app refresh")
                return false
            }
            
            // Fetch latest insights to refresh cache
            let insightsRepository = ServiceLocator.shared.insightsRepository
            _ = try await insightsRepository?.getInsightHistory(
                userId: userId,
                limit: 5,
                offset: 0
            )
            
            logger.info("Background app refresh completed successfully")
            
            // Schedule next refresh
            scheduleAppRefresh()
            
            return true
            
        } catch {
            logger.error("Background app refresh error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func handleBackgroundTask(_ task: BGProcessingTask) async {
        // Schedule next sync immediately
        scheduleHealthDataSync()
        
        // Set up expiration handler
        task.expirationHandler = { [weak self] in
            self?.logger.warning("Background task expired before completion")
            task.setTaskCompleted(success: false)
        }
        
        // Perform the sync
        let success = await handleHealthDataSync()
        
        // Mark task as completed
        task.setTaskCompleted(success: success)
    }
    
    @MainActor
    private func handleAppRefreshTask(_ task: BGAppRefreshTask) async {
        // Schedule next refresh immediately
        scheduleAppRefresh()
        
        // Set up expiration handler
        task.expirationHandler = { [weak self] in
            self?.logger.warning("App refresh task expired before completion")
            task.setTaskCompleted(success: false)
        }
        
        // Perform the refresh
        let success = await handleAppRefresh()
        
        // Mark task as completed
        task.setTaskCompleted(success: success)
    }
}

// MARK: - Service Locator

/// Temporary service locator to access services from background tasks
/// This should be properly initialized in the app delegate
final class ServiceLocator {
    static let shared = ServiceLocator()
    
    var healthKitService: HealthKitServiceProtocol?
    var healthDataRepository: HealthDataRepositoryProtocol?
    var insightsRepository: InsightsRepositoryProtocol?
    var currentUserId: String?
    
    private init() {}
}