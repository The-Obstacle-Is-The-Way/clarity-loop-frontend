//
//  clarity_loop_frontendApp.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/6/25.
//

import FirebaseAuth
import FirebaseCore
import SwiftData
import SwiftUI

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

    // MARK: - Initializer
    
    init() {
        FirebaseApp.configure()
        
        // Initialize the APIClient with proper token provider
        guard let client = APIClient(tokenProvider: {
            return try? await Auth.auth().currentUser?.getIDToken()
        }) else {
            fatalError("Failed to initialize APIClient with a valid URL.")
        }
        
        self.apiClient = client
        
        // Initialize services with shared APIClient
        let service = AuthService(apiClient: client)
        self.authService = service
        self.healthKitService = HealthKitService(apiClient: client)
        
        // Initialize repositories with shared APIClient
        self.insightsRepository = RemoteInsightsRepository(apiClient: client)
        self.healthDataRepository = RemoteHealthDataRepository(apiClient: client)
        
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
        }
    }
} 