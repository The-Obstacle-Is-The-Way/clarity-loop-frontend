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
    
    // By using the @StateObject property wrapper, we ensure that the AuthViewModel
    // is instantiated only once for the entire lifecycle of the app.
    @StateObject private var authViewModel: AuthViewModel
    
    // The APIClient and AuthService are instantiated here. The AuthService is then
    // passed to the AuthViewModel and also injected into the SwiftUI environment.
    private let authService: AuthServiceProtocol
    private let healthKitService: HealthKitServiceProtocol

    // MARK: - Initializer
    
    init() {
        FirebaseApp.configure()
        
        // Initialize the services. A failable initializer is used for APIClient
        // to prevent crashes from an invalid URL.
        guard let apiClient = APIClient(tokenProvider: {
            // This closure provides the APIClient with a way to get the current user's token.
            // We need a non-nil authService to do this, so we create a temporary one if needed,
            // though in the normal app flow the main one will be used.
            // A better solution will be to inject this dependency more cleanly.
            // For now, this is a placeholder to satisfy initialization order.
            // TODO: Refactor dependency injection for tokenProvider
            return try? await Auth.auth().currentUser?.getIDToken()
        }) else {
            fatalError("Failed to initialize APIClient with a valid URL.")
        }
        
        let service = AuthService(apiClient: apiClient)
        self.authService = service
        self.healthKitService = HealthKitService()
        
        // The AuthViewModel is created with the concrete AuthService instance.
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authService: service))
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environment(\.authService, authService)
                .environment(\.healthKitService, healthKitService)
                .modelContainer(PersistenceController.shared.container)
        }
    }
}
