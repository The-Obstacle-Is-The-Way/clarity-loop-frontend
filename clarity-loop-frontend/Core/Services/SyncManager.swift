//
//  SyncManager.swift
//  clarity-loop-frontend
//
//  Created by Assistant on 6/8/25.
//

import Foundation
import Network
import SwiftData
import Observation
import UIKit

/// Manages data synchronization between local storage and the backend API
@Observable
@MainActor
final class SyncManager {
    
    // MARK: - Properties
    
    /// Current sync state
    private(set) var syncState: SyncState = .idle
    
    /// Network availability status
    private(set) var isNetworkAvailable = true
    
    /// Number of items in the pending upload queue
    private(set) var pendingUploadsCount = 0
    
    /// Last successful sync timestamp
    private(set) var lastSyncDate: Date?
    
    // MARK: - Private Properties
    
    private let healthKitService: HealthKitServiceProtocol
    private let apiClient: APIClientProtocol
    private let modelContext: ModelContext
    private let networkMonitor = NWPathMonitor()
    private let syncQueue = DispatchQueue(label: "com.clarity.sync", qos: .background)
    
    /// Retry configuration
    private let maxRetryAttempts = 3
    private let baseRetryDelay: TimeInterval = 2.0
    
    // MARK: - Types
    
    enum SyncState: Equatable {
        case idle
        case syncing(progress: Double)
        case failed(error: String)
        case completed
    }
    
    // MARK: - Initializer
    
    init(
        healthKitService: HealthKitServiceProtocol,
        apiClient: APIClientProtocol,
        modelContext: ModelContext
    ) {
        self.healthKitService = healthKitService
        self.apiClient = apiClient
        self.modelContext = modelContext
        
        setupNetworkMonitoring()
        loadLastSyncDate()
    }
    
    // MARK: - Public Methods
    
    /// Triggers a full synchronization of all health data
    func syncAll() async {
        guard isNetworkAvailable else {
            syncState = .failed(error: "No network connection")
            return
        }
        
        syncState = .syncing(progress: 0.0)
        
        do {
            // Step 1: Sync HealthKit data (50% of progress)
            try await syncHealthKitData()
            syncState = .syncing(progress: 0.5)
            
            // Step 2: Process pending uploads (30% of progress)
            try await processPendingUploads()
            syncState = .syncing(progress: 0.8)
            
            // Step 3: Fetch latest insights (20% of progress)
            try await fetchLatestInsights()
            syncState = .syncing(progress: 1.0)
            
            // Update last sync date
            lastSyncDate = Date()
            saveLastSyncDate()
            
            syncState = .completed
            
        } catch {
            syncState = .failed(error: error.localizedDescription)
        }
    }
    
    /// Syncs only HealthKit data
    func syncHealthKitData() async throws {
        // Get the date range for sync
        let endDate = Date()
        let startDate = lastSyncDate ?? Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        
        // Fetch all daily metrics
        let metrics = try await healthKitService.fetchAllDailyMetrics(for: endDate)
        
        // Convert to upload format
        let uploadRequest = createHealthKitUploadRequest(from: metrics)
        
        // Upload to backend with retry
        _ = try await withRetry(maxAttempts: maxRetryAttempts) {
            try await self.healthKitService.uploadHealthKitData(uploadRequest)
        }
    }
    
    /// Processes any pending uploads from the queue
    func processPendingUploads() async throws {
        // Fetch pending uploads from SwiftData
        let descriptor = FetchDescriptor<PendingUpload>(
            predicate: #Predicate { $0.status == "pending" },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        let pendingUploads = try modelContext.fetch(descriptor)
        pendingUploadsCount = pendingUploads.count
        
        for (index, upload) in pendingUploads.enumerated() {
            let progress = Double(index) / Double(pendingUploads.count)
            syncState = .syncing(progress: 0.5 + (progress * 0.3))
            
            do {
                // Process the upload based on its type
                try await processUpload(upload)
                
                // Mark as completed
                upload.status = "completed"
                upload.completedAt = Date()
                
            } catch {
                // Mark as failed and increment retry count
                upload.status = "failed"
                upload.retryCount += 1
                upload.lastError = error.localizedDescription
                
                // Remove from queue if max retries exceeded
                if upload.retryCount >= maxRetryAttempts {
                    modelContext.delete(upload)
                }
            }
        }
        
        try modelContext.save()
        pendingUploadsCount = try modelContext.fetchCount(
            FetchDescriptor<PendingUpload>(
                predicate: #Predicate { $0.status == "pending" }
            )
        )
    }
    
    /// Adds a new item to the upload queue
    func queueUpload(type: String, data: Data, metadata: [String: String] = [:]) {
        let upload = PendingUpload(
            type: type,
            data: data,
            metadata: metadata
        )
        
        modelContext.insert(upload)
        
        do {
            try modelContext.save()
            pendingUploadsCount += 1
            
            // Trigger sync if network available
            if isNetworkAvailable {
                Task {
                    await processPendingUploads()
                }
            }
        } catch {
            print("Failed to queue upload: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isNetworkAvailable = path.status == .satisfied
                
                // Trigger sync when network becomes available
                if self?.isNetworkAvailable == true && self?.pendingUploadsCount ?? 0 > 0 {
                    await self?.processPendingUploads()
                }
            }
        }
        networkMonitor.start(queue: syncQueue)
    }
    
    private func loadLastSyncDate() {
        if let date = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date {
            lastSyncDate = date
        }
    }
    
    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
    }
    
    private func createHealthKitUploadRequest(from metrics: DailyHealthMetrics) -> HealthKitUploadRequestDTO {
        // Convert DailyHealthMetrics to upload format
        var samples: [HealthKitSampleDTO] = []
        
        // Add step count
        if metrics.stepCount > 0 {
            samples.append(HealthKitSampleDTO(
                identifier: UUID().uuidString,
                type: "HKQuantityTypeIdentifierStepCount",
                value: metrics.stepCount,
                unit: "count",
                startDate: metrics.date,
                endDate: metrics.date,
                source: SourceDTO(
                    name: "CLARITY Pulse",
                    bundleIdentifier: Bundle.main.bundleIdentifier ?? "com.clarity.pulse"
                )
            ))
        }
        
        // Add heart rate if available
        if let heartRate = metrics.restingHeartRate {
            samples.append(HealthKitSampleDTO(
                identifier: UUID().uuidString,
                type: "HKQuantityTypeIdentifierRestingHeartRate",
                value: heartRate,
                unit: "count/min",
                startDate: metrics.date,
                endDate: metrics.date,
                source: SourceDTO(
                    name: "CLARITY Pulse",
                    bundleIdentifier: Bundle.main.bundleIdentifier ?? "com.clarity.pulse"
                )
            ))
        }
        
        let deviceInfo = DeviceInfoDTO(
            deviceModel: UIDevice.current.model,
            systemName: UIDevice.current.systemName,
            systemVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            timeZone: TimeZone.current.identifier
        )
        
        return HealthKitUploadRequestDTO(
            userId: "current_user", // Should get from auth service
            samples: samples,
            deviceInfo: deviceInfo,
            timestamp: Date()
        )
    }
    
    private func processUpload(_ upload: PendingUpload) async throws {
        switch upload.type {
        case "health_metrics":
            // Decode and upload health metrics
            let metrics = try JSONDecoder().decode([HealthMetricDTO].self, from: upload.data)
            let uploadRequest = HealthDataUploadDTO(
                userId: UUID(), // Should get from auth
                metrics: metrics,
                uploadSource: "ios_app",
                clientTimestamp: Date(),
                syncToken: nil
            )
            // For now, we'll skip this as we need to implement the proper health data upload
            // _ = try await apiClient.uploadHealthData(requestDTO: uploadRequest)
            print("Health data upload not yet implemented")
            
        case "pat_analysis":
            // Handle PAT analysis uploads
            break
            
        default:
            throw SyncError.unknownUploadType(upload.type)
        }
    }
    
    private func fetchLatestInsights() async throws {
        // Fetch latest insights from the backend
        // This would integrate with the insights repository
    }
    
    /// Retry helper with exponential backoff
    private func withRetry<T>(
        maxAttempts: Int,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry on certain errors
                if case APIError.unauthorized = error {
                    throw error
                }
                
                // Calculate delay with exponential backoff
                let delay = baseRetryDelay * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? SyncError.retriesExhausted
    }
}

// MARK: - Supporting Types

/// Model for tracking pending uploads
@Model
final class PendingUpload {
    @Attribute(.unique) var id: UUID
    var type: String
    var data: Data
    var metadata: [String: String]
    var status: String
    var retryCount: Int
    var lastError: String?
    var createdAt: Date
    var completedAt: Date?
    
    init(
        type: String,
        data: Data,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.type = type
        self.data = data
        self.metadata = metadata
        self.status = "pending"
        self.retryCount = 0
        self.createdAt = Date()
    }
}

// MARK: - Errors

enum SyncError: LocalizedError {
    case unknownUploadType(String)
    case retriesExhausted
    
    var errorDescription: String? {
        switch self {
        case .unknownUploadType(let type):
            return "Unknown upload type: \(type)"
        case .retriesExhausted:
            return "Maximum retry attempts exceeded"
        }
    }
}