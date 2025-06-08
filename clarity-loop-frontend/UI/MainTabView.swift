//
//  MainTabView.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import SwiftUI
import FirebaseAuth

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Image(systemName: "heart.fill")
                Text("Dashboard")
            }
            
            NavigationStack {
                ChatView()
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("AI Chat")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("Settings")
            }
            
            NavigationStack {
                DebugAPIView()
            }
            .tabItem {
                Image(systemName: "ladybug.fill")
                Text("Debug")
            }
        }
        .accentColor(.red)
    }
}

#Preview {
    let previewAPIClient = APIClient(
        baseURLString: AppConfig.previewAPIBaseURL,
        tokenProvider: { nil }
    )!
    
    MainTabView()
        .environment(\.authService, AuthService(apiClient: previewAPIClient))
        .environment(\.healthKitService, HealthKitService(apiClient: previewAPIClient))
}