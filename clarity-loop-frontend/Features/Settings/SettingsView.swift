//
//  SettingsView.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    
    @Environment(\.authService) private var authService
    @Environment(\.healthKitService) private var healthKitService
    @State private var showingSignOutAlert = false
    @State private var showingHealthKitAuth = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Health Data") {
                    Button("Request HealthKit Authorization") {
                        requestHealthKitAuthorization()
                    }
                    .foregroundColor(.blue)
                }
                
                Section("Account") {
                    Button("Sign Out") {
                        showingSignOutAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private func requestHealthKitAuthorization() {
        Task {
            do {
                try await healthKitService.requestAuthorization()
            } catch {
                print("Failed to request HealthKit authorization: \(error)")
            }
        }
    }
    
    private func signOut() {
        do {
            try authService.signOut()
        } catch {
            print("Failed to sign out: \(error)")
        }
    }
}

#if DEBUG
#Preview {
    SettingsView()
}
#endif