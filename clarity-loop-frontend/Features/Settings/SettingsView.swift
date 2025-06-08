//
//  SettingsView.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.authService) private var authService
    @Environment(\.healthKitService) private var healthKitService
    @State private var viewModel: SettingsViewModel?
    
    var body: some View {
        NavigationStack {
            if let viewModel = viewModel {
                SettingsContentView(viewModel: viewModel)
            } else {
                ProgressView("Loading...")
                    .onAppear {
                        self.viewModel = SettingsViewModel(
                            authService: authService,
                            healthKitService: healthKitService
                        )
                    }
            }
        }
    }
}

struct SettingsContentView: View {
    @Bindable var viewModel: SettingsViewModel
    
    var body: some View {
        List {
            // Profile Section
            Section("Profile") {
                if viewModel.isEditingProfile {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("First Name", text: $viewModel.firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Last Name", text: $viewModel.lastName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack {
                            Button("Cancel") {
                                viewModel.cancelEditingProfile()
                            }
                            .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Save") {
                                Task {
                                    await viewModel.saveProfile()
                                }
                            }
                            .disabled(viewModel.isLoading)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.currentUser)
                            .font(.headline)
                        Text("Tap to edit profile")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        viewModel.startEditingProfile()
                    }
                }
            }
            
            // Health Data Section
            Section("Health Data") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("HealthKit Status:")
                        Spacer()
                        Text(viewModel.healthKitAuthorizationStatus)
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastSync = viewModel.lastSyncDate {
                        HStack {
                            Text("Last Sync:")
                            Spacer()
                            Text(lastSync, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Button("Request HealthKit Authorization") {
                    Task {
                        await viewModel.requestHealthKitAuthorization()
                    }
                }
                .disabled(viewModel.isLoading)
                
                Button("Sync Health Data") {
                    Task {
                        await viewModel.syncHealthData()
                    }
                }
                .disabled(viewModel.isLoading)
                
                Toggle("Auto Sync", isOn: Binding(
                    get: { viewModel.autoSyncEnabled },
                    set: { _ in viewModel.toggleAutoSync() }
                ))
            }
            
            // App Preferences Section
            Section("Preferences") {
                Toggle("Notifications", isOn: Binding(
                    get: { viewModel.notificationsEnabled },
                    set: { _ in viewModel.toggleNotifications() }
                ))
                
                Toggle("Biometric Authentication", isOn: Binding(
                    get: { viewModel.biometricAuthEnabled },
                    set: { _ in viewModel.toggleBiometricAuth() }
                ))
                
                Toggle("Analytics", isOn: Binding(
                    get: { viewModel.analyticsEnabled },
                    set: { _ in viewModel.toggleAnalytics() }
                ))
            }
            
            // Data Management Section
            Section("Data Management") {
                Button("Export My Data") {
                    Task {
                        await viewModel.exportUserData()
                    }
                }
                .disabled(viewModel.isLoading)
                
                Button("Delete All My Data") {
                    Task {
                        await viewModel.deleteAllUserData()
                    }
                }
                .foregroundColor(.red)
                .disabled(viewModel.isLoading)
            }
            
            // Account Section
            Section("Account") {
                Button("Sign Out") {
                    viewModel.showingSignOutAlert = true
                }
                .foregroundColor(.red)
                
                Button("Delete Account") {
                    viewModel.showingDeleteAccountAlert = true
                }
                .foregroundColor(.red)
                .disabled(viewModel.isLoading)
            }
        }
        .navigationTitle("Settings")
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") {
                viewModel.clearMessages()
            }
        } message: {
            if let message = viewModel.successMessage {
                Text(message)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearMessages()
            }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
        .alert("Sign Out", isPresented: $viewModel.showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                viewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $viewModel.showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteAccount()
                }
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
}

#if DEBUG
#Preview {
    SettingsView()
}
#endif
