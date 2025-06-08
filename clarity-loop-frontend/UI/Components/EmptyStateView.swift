import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        message: String,
        systemImage: String = "tray.fill",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Specialized Empty State Views

struct NoHealthDataView: View {
    let onSetupHealthKit: () -> Void
    
    var body: some View {
        EmptyStateView(
            title: "No Health Data",
            message: "Start tracking your health by connecting to HealthKit. We'll analyze your sleep, activity, and wellness patterns.",
            systemImage: "heart.fill",
            actionTitle: "Connect HealthKit",
            action: onSetupHealthKit
        )
    }
}

struct NoInsightsView: View {
    let onGenerateInsight: (() -> Void)?
    
    init(onGenerateInsight: (() -> Void)? = nil) {
        self.onGenerateInsight = onGenerateInsight
    }
    
    var body: some View {
        EmptyStateView(
            title: "No Insights Yet",
            message: "Once you have health data, we'll generate personalized insights about your wellness patterns.",
            systemImage: "lightbulb.fill",
            actionTitle: onGenerateInsight != nil ? "Generate Insight" : nil,
            action: onGenerateInsight
        )
    }
}

struct NoSearchResultsView: View {
    let searchTerm: String
    let onClearSearch: () -> Void
    
    var body: some View {
        EmptyStateView(
            title: "No Results Found",
            message: "We couldn't find anything matching '\(searchTerm)'. Try different keywords or clear the search.",
            systemImage: "magnifyingglass",
            actionTitle: "Clear Search",
            action: onClearSearch
        )
    }
}

struct NoConversationView: View {
    let onStartChat: () -> Void
    
    var body: some View {
        EmptyStateView(
            title: "Start a Conversation",
            message: "Ask me anything about your health data, patterns, or get personalized wellness recommendations.",
            systemImage: "message.fill",
            actionTitle: "Start Chatting",
            action: onStartChat
        )
    }
}

struct NoAnalysisHistoryView: View {
    let onRunAnalysis: () -> Void
    
    var body: some View {
        EmptyStateView(
            title: "No Analysis History",
            message: "Run your first PAT analysis to see detailed insights about your sleep and activity patterns.",
            systemImage: "chart.bar.fill",
            actionTitle: "Run Analysis",
            action: onRunAnalysis
        )
    }
}

struct MaintenanceModeView: View {
    let estimatedDowntime: String?
    
    var body: some View {
        EmptyStateView(
            title: "Under Maintenance",
            message: estimatedDowntime.map { "We're improving our services. Expected completion: \($0)" }
                ?? "We're performing scheduled maintenance. Please check back soon.",
            systemImage: "wrench.and.screwdriver.fill"
        )
    }
}

struct FeatureUnavailableView: View {
    let featureName: String
    let reason: String
    
    var body: some View {
        EmptyStateView(
            title: "\(featureName) Unavailable",
            message: reason,
            systemImage: "exclamationmark.triangle.fill"
        )
    }
}

// MARK: - Loading State View

struct LoadingStateView: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Skeleton Loading View

struct SkeletonLoadingView: View {
    @State private var animateGradient = false
    let numberOfRows: Int
    
    init(numberOfRows: Int = 3) {
        self.numberOfRows = numberOfRows
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<numberOfRows, id: \.self) { _ in
                SkeletonRow()
            }
        }
        .padding()
    }
}

private struct SkeletonRow: View {
    @State private var animateGradient = false
    
    var body: some View {
        HStack {
            // Icon placeholder
            Circle()
                .fill(skeletonGradient)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                // Title placeholder
                Rectangle()
                    .fill(skeletonGradient)
                    .frame(height: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Subtitle placeholder
                Rectangle()
                    .fill(skeletonGradient)
                    .frame(height: 12)
                    .frame(maxWidth: 200, alignment: .leading)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
    
    private var skeletonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(.systemGray5),
                Color(.systemGray4),
                Color(.systemGray5)
            ],
            startPoint: animateGradient ? .leading : .trailing,
            endPoint: animateGradient ? .trailing : .leading
        )
    }
}

// MARK: - Preview

#Preview("Empty Health Data") {
    NoHealthDataView(onSetupHealthKit: {})
}

#Preview("No Insights") {
    NoInsightsView(onGenerateInsight: {})
}

#Preview("Loading State") {
    LoadingStateView(message: "Analyzing your health data...")
}

#Preview("Skeleton Loading") {
    SkeletonLoadingView(numberOfRows: 4)
}

#Preview("Maintenance Mode") {
    MaintenanceModeView(estimatedDowntime: "2 hours")
}