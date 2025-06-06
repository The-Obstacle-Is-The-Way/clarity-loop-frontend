//
//  clarity_loop_frontendApp.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/6/25.
//

import SwiftData
import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct clarity_loop_frontendApp: App {
    
    // StateObject for the global authentication view model.
    @StateObject private var authViewModel: AuthViewModel
    
    // The single instance of our AuthService, constructed with a real APIClient.
    private let authService: AuthServiceProtocol

    init() {
        // 1. Configure Firebase
        FirebaseApp.configure()
        
        // 2. Initialize the APIClient with a token provider closure that uses the AuthService.
        //    We need a temporary auth service to break the circular dependency.
        let tempAuthService = AuthService(apiClient: APIClient(tokenProvider: { nil }))
        let apiClient = APIClient {
            try? await tempAuthService.getCurrentUserToken()
        }
        
        // 3. Initialize the real AuthService with the configured APIClient.
        let authService = AuthService(apiClient: apiClient)
        self.authService = authService
        
        // 4. Initialize the AuthViewModel with the real AuthService.
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }

    var body: some Scene {
        WindowGroup {
            // The ContentView will decide whether to show Login or the main app.
            ContentView()
                .environmentObject(authViewModel)
                .environment(\.authService, authService)
                .modelContainer(PersistenceController.shared.container)
        }
    }
}
