//
//  clarity_loop_frontendApp.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/6/25.
//

import BackgroundTasks
import SwiftData
import SwiftUI
#if canImport(UIKit) && DEBUG
import UIKit
#endif

@main
struct ClarityPulseApp: App {
    
    // MARK: - Properties
    
    // By using the @State property wrapper, we ensure that the AuthViewModel
    // is instantiated only once for the entire lifecycle of the app.
    @State private var authViewModel: AuthViewModel
    
    // The APIClient and services are instantiated here and injected into the environment.
    private let authService: AuthServiceProtocol
    private let healthKitService: HealthKitServiceProtocol
    private let apiClient: APIClientProtocol
    private let insightsRepository: InsightsRepositoryProtocol
    private let healthDataRepository: HealthDataRepositoryProtocol
    private let backgroundTaskManager: BackgroundTaskManagerProtocol
    private let offlineQueueManager: OfflineQueueManagerProtocol

    // MARK: - Initializer
    
    init() {
        // Initialize the BackendAPIClient with proper token provider
        guard let client = BackendAPIClient(tokenProvider: {
            print("🔍 APP: Token provider called")
            
            // Use TokenManager directly for backend-centric auth
            let token = await TokenManager.shared.getAccessToken()
            
            if let token = token {
                print("✅ APP: Token obtained from TokenManager")
                print("   - Length: \(token.count)")
                
                #if DEBUG
                // Print the full JWT so we can copy from the console
                print("🧪 FULL_ID_TOKEN → \(token)")

                // Copy to clipboard for CLI use
                #if canImport(UIKit)
                UIPasteboard.general.string = token
                print("📋 Token copied to clipboard")
                #endif
                #endif
            } else {
                print("⚠️ APP: No token available")
            }
            
            return token
        }) else {
            fatalError("Failed to initialize BackendAPIClient with a valid URL.")
        }
        
        self.apiClient = client
        
        // Initialize services with shared APIClient
        let service = AuthService(apiClient: client)
        self.authService = service
        
        // TokenManagementService no longer needed - using TokenManager directly
        
        let healthKit = HealthKitService(apiClient: client)
        self.healthKitService = healthKit
        
        // Initialize repositories with shared APIClient
        self.insightsRepository = RemoteInsightsRepository(apiClient: client)
        self.healthDataRepository = RemoteHealthDataRepository(apiClient: client)
        
        // Initialize service locator for background tasks
        ServiceLocator.shared.healthKitService = healthKitService
        ServiceLocator.shared.healthDataRepository = healthDataRepository
        ServiceLocator.shared.insightsRepository = insightsRepository
        
        // Initialize background task manager
        self.backgroundTaskManager = BackgroundTaskManager(
            healthKitService: healthKitService,
            healthDataRepository: healthDataRepository
        )
        
        // Register background tasks
        backgroundTaskManager.registerBackgroundTasks()
        
        // Initialize offline queue manager
        let queueManager = OfflineQueueManager(
            modelContext: PersistenceController.shared.container.mainContext,
            healthDataRepository: healthDataRepository,
            insightsRepository: insightsRepository
        )
        self.offlineQueueManager = queueManager
        
        // Connect offline queue manager to HealthKitService
        healthKit.setOfflineQueueManager(queueManager)
        
        // Start offline queue monitoring
        offlineQueueManager.startMonitoring()
        
        // The AuthViewModel is created with the concrete AuthService instance.
        _authViewModel = State(initialValue: AuthViewModel(authService: service))
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
                .environment(\.authService, authService)
                .environment(\.healthKitService, healthKitService)
                .environment(\.apiClient, apiClient)
                .environment(\.insightsRepository, insightsRepository)
                .environment(\.healthDataRepository, healthDataRepository)
                .modelContainer(PersistenceController.shared.container)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // Schedule background tasks when app enters background
                    backgroundTaskManager.scheduleHealthDataSync()
                    backgroundTaskManager.scheduleAppRefresh()
                }
                .onChange(of: authViewModel.isLoggedIn) { _, newValue in
                    // Update service locator with current user ID
                    if newValue {
                        Task {
                            if let currentUser = await authService.currentUser {
                                ServiceLocator.shared.currentUserId = currentUser.id
                            }
                        }
                    } else {
                        ServiceLocator.shared.currentUserId = nil
                    }
                }
        }
    }
}