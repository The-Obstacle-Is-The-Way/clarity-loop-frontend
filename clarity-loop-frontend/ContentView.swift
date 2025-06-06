//
//  ContentView.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/6/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.authService) private var authService

    var body: some View {
        // The RootView now correctly switches between Login and the main app content
        // based on the global authentication state.
        if authViewModel.isLoggedIn {
            // This will be replaced with the main TabView or DashboardView later.
            Text("Main App Content")
        } else {
            // Pass the authService from the environment into the LoginView
            LoginView(authService: authService)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
