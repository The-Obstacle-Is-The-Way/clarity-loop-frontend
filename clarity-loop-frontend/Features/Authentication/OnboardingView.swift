import SwiftUI

struct OnboardingView: View {
    @Environment(\.authService) private var authService
    @Environment(\.healthKitService) private var healthKitService
    
    var body: some View {
        NavigationView {
            OnboardingContentView(
                viewModel: OnboardingViewModel(
                    authService: authService,
                    healthKitService: healthKitService
                )
            )
        }
        .navigationBarHidden(true)
    }
}

struct OnboardingContentView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            ProgressView(value: viewModel.progressPercentage)
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.horizontal)
                .padding(.top)
            
            // Content
            TabView(selection: $viewModel.currentStep) {
                WelcomeStepView()
                    .tag(0)
                
                TermsStepView(viewModel: viewModel)
                    .tag(1)
                
                HealthKitStepView(viewModel: viewModel)
                    .tag(2)
                
                NotificationsStepView(viewModel: viewModel)
                    .tag(3)
                
                CompletionStepView(viewModel: viewModel)
                    .tag(4)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentStep)
            
            // Navigation Buttons
            HStack {
                if viewModel.currentStep > 0 {
                    Button("Back") {
                        viewModel.previousStep()
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if viewModel.currentStep < viewModel.totalSteps - 1 {
                    Button("Next") {
                        viewModel.nextStep()
                    }
                    .disabled(!viewModel.canProceedFromCurrentStep || viewModel.isLoading)
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        viewModel.completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
    }
}

// MARK: - Step Views

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "heart.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            VStack(spacing: 16) {
                Text("Welcome to Clarity")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your personal health insights companion")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Health Analytics", description: "Track and analyze your health metrics")
                FeatureRow(icon: "brain.head.profile", title: "AI Insights", description: "Get personalized health recommendations")
                FeatureRow(icon: "lock.shield", title: "Privacy First", description: "Your data stays secure and private")
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct TermsStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Terms & Privacy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Please review and accept our terms to continue")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                HStack {
                    Button(action: viewModel.toggleTermsAcceptance) {
                        Image(systemName: viewModel.hasAcceptedTerms ? "checkmark.square.fill" : "square")
                            .foregroundColor(viewModel.hasAcceptedTerms ? .blue : .secondary)
                    }
                    
                    Text("I accept the ")
                    + Text("Terms of Service")
                        .foregroundColor(.blue)
                        .underline()
                    
                    Spacer()
                }
                
                HStack {
                    Button(action: viewModel.togglePrivacyAcceptance) {
                        Image(systemName: viewModel.hasAcceptedPrivacy ? "checkmark.square.fill" : "square")
                            .foregroundColor(viewModel.hasAcceptedPrivacy ? .blue : .secondary)
                    }
                    
                    Text("I accept the ")
                    + Text("Privacy Policy")
                        .foregroundColor(.blue)
                        .underline()
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct HealthKitStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            VStack(spacing: 16) {
                Text("HealthKit Access")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Allow Clarity to access your health data for personalized insights")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                FeatureRow(icon: "figure.walk", title: "Activity Data", description: "Steps, workouts, and movement")
                FeatureRow(icon: "bed.double", title: "Sleep Analysis", description: "Sleep patterns and quality")
                FeatureRow(icon: "heart", title: "Vital Signs", description: "Heart rate and health metrics")
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button("Allow HealthKit Access") {
                    Task {
                        await viewModel.requestHealthKitPermissions()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                
                Button("Skip for Now") {
                    viewModel.skipHealthKit()
                }
                .foregroundColor(.secondary)
            }
            
            if viewModel.healthKitAuthorized {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("HealthKit access granted!")
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct NotificationsStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "bell.badge")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 16) {
                Text("Stay Informed")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Get notified about new insights and health updates")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                FeatureRow(icon: "lightbulb", title: "New Insights", description: "When AI generates new health insights")
                FeatureRow(icon: "exclamationmark.triangle", title: "Health Alerts", description: "Important health pattern changes")
                FeatureRow(icon: "calendar", title: "Reminders", description: "Health check-ins and data sync")
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button("Enable Notifications") {
                    Task {
                        await viewModel.requestNotificationPermissions()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                
                Button("Skip for Now") {
                    viewModel.skipNotifications()
                }
                .foregroundColor(.secondary)
            }
            
            if viewModel.notificationsAuthorized {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Notifications enabled!")
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct CompletionStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Clarity is ready to help you understand your health better")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 8) {
                if viewModel.healthKitAuthorized {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("HealthKit connected")
                    }
                }
                
                if viewModel.notificationsAuthorized {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Notifications enabled")
                    }
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Terms accepted")
                }
            }
            .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Helper Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
} 