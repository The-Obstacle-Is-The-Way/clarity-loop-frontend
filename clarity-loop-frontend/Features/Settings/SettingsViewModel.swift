import Foundation
import Observation

@Observable
final class SettingsViewModel {
    
    // MARK: - Dependencies
    private let authService: any AuthServiceProtocol
    private let healthKitService: any HealthKitServiceProtocol
    
    // MARK: - State Properties
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    var showingSignOutAlert = false
    var showingDeleteAccountAlert = false
    
    // Profile editing state
    var isEditingProfile = false
    var firstName = ""
    var lastName = ""
    var email = ""
    
    // App preferences
    var notificationsEnabled = true
    var biometricAuthEnabled = false
    var dataExportEnabled = true
    var analyticsEnabled = false
    
    // Health data settings
    var healthKitAuthorizationStatus = "Unknown"
    var lastSyncDate: Date?
    var autoSyncEnabled = true
    
    // MARK: - Computed Properties
    var currentUser: String {
        // Note: This now returns a placeholder since currentUser is async
        // In UI, use async methods to get actual current user
        "Loading user..."
    }
    
    var hasUnsavedChanges: Bool {
        // Check if any profile fields have been modified
        return isEditingProfile && (!firstName.isEmpty || !lastName.isEmpty)
    }
    
    // MARK: - Initializer
    init(authService: any AuthServiceProtocol, healthKitService: any HealthKitServiceProtocol) {
        self.authService = authService
        self.healthKitService = healthKitService
        loadUserProfile()
        checkHealthKitStatus()
    }
    
    // MARK: - Profile Management
    func loadUserProfile() async {
        // Load user profile data
        if let user = await authService.currentUser {
            email = user.email ?? ""
            // In a real app, you'd fetch additional profile data from your backend
        }
    }
    
    func startEditingProfile() {
        isEditingProfile = true
        // Pre-populate fields with current values
        loadUserProfile()
    }
    
    func cancelEditingProfile() {
        isEditingProfile = false
        firstName = ""
        lastName = ""
        errorMessage = nil
    }
    
    func saveProfile() async {
        guard !firstName.isEmpty || !lastName.isEmpty else {
            errorMessage = "Please enter at least a first or last name"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // In a real app, you'd call your backend API to update profile
            // For now, we'll simulate a successful update
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            
            successMessage = "Profile updated successfully"
            isEditingProfile = false
            firstName = ""
            lastName = ""
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - HealthKit Management
    func checkHealthKitStatus() {
        if healthKitService.isHealthDataAvailable() {
            healthKitAuthorizationStatus = "Available"
        } else {
            healthKitAuthorizationStatus = "Not Available"
        }
    }
    
    func requestHealthKitAuthorization() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await healthKitService.requestAuthorization()
            healthKitAuthorizationStatus = "Authorized"
            successMessage = "HealthKit authorization granted"
        } catch {
            errorMessage = "Failed to authorize HealthKit: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func syncHealthData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // In a real app, you'd trigger a health data sync
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
            lastSyncDate = Date()
            successMessage = "Health data synced successfully"
        } catch {
            errorMessage = "Failed to sync health data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Data Management
    func exportUserData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // In a real app, you'd generate and export user data
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second delay
            successMessage = "Data export initiated. You'll receive an email when ready."
        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteAllUserData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // In a real app, you'd call your backend to delete all user data
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
            successMessage = "All user data has been deleted"
        } catch {
            errorMessage = "Failed to delete user data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Authentication Actions
    func signOut() async {
        do {
            try await authService.signOut()
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // In a real app, you'd call your backend to delete the account
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
            
            // Then sign out
            try await authService.signOut()
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Utility Methods
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    func toggleNotifications() {
        notificationsEnabled.toggle()
        // In a real app, you'd save this preference
    }
    
    func toggleBiometricAuth() {
        biometricAuthEnabled.toggle()
        // In a real app, you'd save this preference and configure biometric auth
    }
    
    func toggleAutoSync() {
        autoSyncEnabled.toggle()
        // In a real app, you'd save this preference and configure auto sync
    }
    
    func toggleAnalytics() {
        analyticsEnabled.toggle()
        // In a real app, you'd save this preference and configure analytics
    }
} 
