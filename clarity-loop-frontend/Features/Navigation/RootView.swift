//
//  RootView.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import SwiftUI

/// The root view that manages the entire application's navigation flow
struct RootView: View {
    
    @Environment(\.authStateManager) private var authStateManager
    
    var body: some View {
        Group {
            switch authStateManager.authState {
            case .loading:
                LoadingView()
            case .unauthenticated:
                AuthenticationFlow()
            case .needsEmailVerification:
                EmailVerificationView()
            case .needsOnboarding:
                OnboardingFlow()
            case .authenticated:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authStateManager.authState)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .scaleEffect(1.2)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
                
                Text("CLARITY Pulse")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
    }
}

// MARK: - Email Verification View

struct EmailVerificationView: View {
    
    @Environment(\.authStateManager) private var authStateManager
    @State private var isCheckingVerification = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Check Your Email")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("We've sent you a verification link. Please check your email and tap the link to verify your account.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button("I've Verified My Email") {
                    checkEmailVerification()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCheckingVerification)
                
                if isCheckingVerification {
                    ProgressView("Checking verification...")
                        .font(.caption)
                }
                
                Button("Sign Out") {
                    authStateManager.signOut()
                }
                .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 32)
    }
    
    private func checkEmailVerification() {
        isCheckingVerification = true
        
        Task {
            await authStateManager.refreshAuthState()
            isCheckingVerification = false
        }
    }
}

// MARK: - Authentication Flow

struct AuthenticationFlow: View {
    var body: some View {
        NavigationStack {
            LoginView(authService: AuthService(apiClient: APIClient(tokenProvider: {
                try? await Auth.auth().currentUser?.getIDToken()
            })!))
        }
    }
}

// MARK: - Onboarding Flow

struct OnboardingFlow: View {
    
    @Environment(\.authStateManager) private var authStateManager
    
    var body: some View {
        NavigationStack {
            OnboardingView()
        }
    }
}

struct OnboardingView: View {
    
    @Environment(\.authStateManager) private var authStateManager
    @State private var currentPage = 0
    
    private let onboardingPages = [
        OnboardingPage(
            title: "Track Your Health",
            description: "Monitor your daily activities, heart rate, and sleep patterns with seamless HealthKit integration.",
            systemImage: "heart.text.square.fill",
            color: .red
        ),
        OnboardingPage(
            title: "AI-Powered Insights",
            description: "Get personalized health insights powered by advanced AI analysis of your health data.",
            systemImage: "brain.head.profile",
            color: .blue
        ),
        OnboardingPage(
            title: "Secure & Private",
            description: "Your health data is encrypted and secure. We prioritize your privacy above everything else.",
            systemImage: "lock.shield.fill",
            color: .green
        )
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<onboardingPages.count, id: \.self) { index in
                    OnboardingPageView(page: onboardingPages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom page indicator
            HStack(spacing: 8) {
                ForEach(0..<onboardingPages.count, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.bottom, 20)
            
            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("Previous") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(currentPage == onboardingPages.count - 1 ? "Get Started" : "Next") {
                    if currentPage == onboardingPages.count - 1 {
                        authStateManager.completeOnboarding()
                    } else {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .navigationBarHidden(true)
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: page.systemImage)
                .font(.system(size: 100))
                .foregroundColor(page.color)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let systemImage: String
    let color: Color
}

// MARK: - Main Tab View

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
        }
    }
}