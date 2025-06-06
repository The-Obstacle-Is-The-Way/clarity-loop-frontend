//
//  AuthStateManager.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation
import FirebaseAuth
import SwiftUI

/// Manages the global authentication state for the entire application
@MainActor
@Observable
final class AuthStateManager {
    
    // MARK: - Published Properties
    
    /// The current authentication state
    var authState: AuthenticationState = .loading
    
    /// The currently authenticated user
    var currentUser: FirebaseAuth.User?
    
    /// Whether the user has completed onboarding
    var hasCompletedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding")
        }
    }
    
    // MARK: - Private Properties
    
    private let authService: AuthServiceProtocol
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initializer
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Authentication State Management
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                await self?.updateAuthState(user: user)
            }
        }
    }
    
    private func updateAuthState(user: FirebaseAuth.User?) async {
        if let user = user {
            // Check if email is verified
            await user.reload()
            if user.isEmailVerified {
                authState = hasCompletedOnboarding ? .authenticated : .needsOnboarding
            } else {
                authState = .needsEmailVerification
            }
        } else {
            authState = .unauthenticated
        }
    }
    
    // MARK: - Public Methods
    
    /// Signs out the current user
    func signOut() {
        do {
            try authService.signOut()
            authState = .unauthenticated
            currentUser = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    /// Marks onboarding as completed
    func completeOnboarding() {
        hasCompletedOnboarding = true
        if currentUser != nil {
            authState = .authenticated
        }
    }
    
    /// Forces a refresh of the auth state
    func refreshAuthState() async {
        if let user = currentUser {
            await updateAuthState(user: user)
        }
    }
}

// MARK: - Authentication State Enum

enum AuthenticationState: Equatable {
    case loading
    case unauthenticated
    case needsEmailVerification
    case needsOnboarding
    case authenticated
}