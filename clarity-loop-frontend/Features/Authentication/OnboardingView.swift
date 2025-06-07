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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                
                // Content area
                TabView(selection: $viewModel.currentStep) {
                    stepView(for: 0)
                        .tag(0)
                    stepView(for: 1)
                        .tag(1)
                    stepView(for: 2)
                        .tag(2)
                    stepView(for: 3)
                        .tag(3)
                    stepView(for: 4)
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)
                
                // Navigation buttons
                navigationButtons
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: .constant(false)) {
            TermsAndConditionsView(
                onAccept: {
                    viewModel.acceptTerms()
                    viewModel.acceptPrivacy()
                },
                onDecline: {
                    // Handle decline
                }
            )
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        VStack(spacing: 16) {
            HStack {
                ForEach(0..<viewModel.totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= viewModel.currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .scaleEffect(step == viewModel.currentStep ? 1.2 : 1.0)
                        .animation(.easeInOut, value: viewModel.currentStep)
                    
                    if step != viewModel.totalSteps - 1 {
                        Rectangle()
                            .fill(step < viewModel.currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                            .animation(.easeInOut, value: viewModel.currentStep)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Text("Step \(viewModel.currentStep + 1) of \(viewModel.totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    // MARK: - Step Views
    
    @ViewBuilder
    private func stepView(for step: Int) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)
                
                switch step {
                case 0:
                    welcomeStepView
                case 1:
                    termsStepView
                case 2:
                    healthKitStepView
                case 3:
                    notificationsStepView
                case 4:
                    completionStepView
                default:
                    welcomeStepView
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 32)
        }
    }
    
    private var welcomeStepView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            Text("Welcome to Clarity")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Your personal health insights companion")
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Health Tracking",
                    description: "Monitor your daily health metrics"
                )
                
                FeatureRow(
                    icon: "brain.head.profile",
                    title: "AI Insights",
                    description: "Get personalized health recommendations"
                )
                
                FeatureRow(
                    icon: "lock.shield",
                    title: "Privacy First",
                    description: "Your data stays secure and private"
                )
            }
            .padding(.top, 20)
        }
    }
    
    private var termsStepView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Terms & Privacy")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Please review our terms of service and privacy policy to continue.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
                         VStack(spacing: 16) {
                 HStack {
                     Button(action: viewModel.toggleTermsAcceptance) {
                         Image(systemName: viewModel.hasAcceptedTerms ? "checkmark.circle.fill" : "circle")
                             .foregroundColor(viewModel.hasAcceptedTerms ? .green : .gray)
                     }
                     
                     Text("I accept the Terms of Service")
                         .font(.body)
                     
                     Spacer()
                 }
                 
                 HStack {
                     Button(action: viewModel.togglePrivacyAcceptance) {
                         Image(systemName: viewModel.hasAcceptedPrivacy ? "checkmark.circle.fill" : "circle")
                             .foregroundColor(viewModel.hasAcceptedPrivacy ? .green : .gray)
                     }
                     
                     Text("I accept the Privacy Policy")
                         .font(.body)
                     
                     Spacer()
                 }
             }
             .padding()
             .background(Color(.systemGray6))
             .cornerRadius(12)
        }
    }
    
    private var healthKitStepView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("HealthKit Integration")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Connect with Apple Health to automatically sync your health data and get personalized insights.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                PermissionRow(
                    icon: "figure.walk",
                    title: "Steps & Activity",
                    description: "Daily step count and activity levels",
                    isGranted: viewModel.healthKitPermissions.stepsGranted
                )
                
                PermissionRow(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    description: "Resting and active heart rate data",
                    isGranted: viewModel.healthKitPermissions.heartRateGranted
                )
                
                PermissionRow(
                    icon: "bed.double.fill",
                    title: "Sleep Analysis",
                    description: "Sleep duration and quality metrics",
                    isGranted: viewModel.healthKitPermissions.sleepGranted
                )
            }
            
            if viewModel.isRequestingHealthKitPermission {
                ProgressView("Requesting permissions...")
                    .padding()
            } else {
                Button("Grant HealthKit Permissions") {
                    Task {
                        await viewModel.requestHealthKitPermission()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.healthKitPermissions.allGranted)
            }
            
            if viewModel.healthKitPermissions.allGranted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("All permissions granted!")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    private var notificationsStepView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Stay Informed")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Get timely reminders and insights to help you maintain your health goals.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                NotificationTypeRow(
                    icon: "brain.head.profile",
                    title: "Health Insights",
                    description: "New AI-generated insights about your health",
                    isEnabled: viewModel.notificationPreferences.insightsEnabled
                ) {
                    viewModel.toggleNotification(.insights)
                }
                
                NotificationTypeRow(
                    icon: "clock.fill",
                    title: "Daily Reminders",
                    description: "Reminders to check your health metrics",
                    isEnabled: viewModel.notificationPreferences.remindersEnabled
                ) {
                    viewModel.toggleNotification(.reminders)
                }
                
                NotificationTypeRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Health Alerts",
                    description: "Important health-related notifications",
                    isEnabled: viewModel.notificationPreferences.alertsEnabled
                ) {
                    viewModel.toggleNotification(.alerts)
                }
            }
            
            if viewModel.isRequestingNotificationPermission {
                ProgressView("Requesting notification permission...")
                    .padding()
            } else if !viewModel.notificationPermissionGranted {
                Button("Enable Notifications") {
                    Task {
                        await viewModel.requestNotificationPermission()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var completionStepView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Welcome to your personalized health journey with Clarity.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                CompletionSummaryRow(
                    icon: "doc.text.fill",
                    title: "Terms Accepted",
                    isCompleted: viewModel.termsAccepted && viewModel.privacyAccepted
                )
                
                CompletionSummaryRow(
                    icon: "heart.text.square.fill",
                    title: "HealthKit Connected",
                    isCompleted: viewModel.healthKitPermissions.allGranted
                )
                
                CompletionSummaryRow(
                    icon: "bell.fill",
                    title: "Notifications Configured",
                    isCompleted: viewModel.notificationPermissionGranted
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button("Start Using Clarity") {
                viewModel.completeOnboarding()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack {
            if viewModel.currentStep != 0 {
                Button("Back") {
                    viewModel.previousStep()
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            if viewModel.currentStep != 4 {
                Button(viewModel.canProceedFromCurrentStep ? "Next" : "Skip") {
                    if viewModel.canProceedFromCurrentStep {
                        viewModel.nextStep()
                    } else {
                        viewModel.nextStep()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.currentStep == 1 && !viewModel.canProceedFromCurrentStep)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
}

// MARK: - Supporting Views

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
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.red)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isGranted ? .green : .gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct NotificationTypeRow: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(isEnabled))
                .onChange(of: isEnabled) { _, _ in
                    onToggle()
                }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CompletionSummaryRow: View {
    let icon: String
    let title: String
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isCompleted ? .green : .red)
        }
    }
}

struct TermsAndConditionsView: View {
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Terms of Service")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("By using Clarity, you agree to the following terms...")
                        .font(.body)
                    
                    // Add actual terms content here
                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
                        .font(.body)
                    
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Your privacy is important to us...")
                        .font(.body)
                    
                    // Add actual privacy policy content here
                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
                        .font(.body)
                }
                .padding()
            }
            .navigationTitle("Terms & Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Decline") {
                        onDecline()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Accept") {
                        onAccept()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
} 