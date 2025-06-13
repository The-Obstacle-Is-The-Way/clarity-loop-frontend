import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    let systemImage: String
    let retryAction: (() -> Void)?
    let dismissAction: (() -> Void)?
    
    init(
        title: String = "Something went wrong",
        message: String,
        systemImage: String = "exclamationmark.triangle.fill",
        retryAction: (() -> Void)? = nil,
        dismissAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.retryAction = retryAction
        self.dismissAction = dismissAction
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 60))
                    .foregroundColor(errorColor)
                
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
            
            VStack(spacing: 12) {
                if let retryAction = retryAction {
                    Button("Try Again", action: retryAction)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
                
                if let dismissAction = dismissAction {
                    Button("Dismiss", action: dismissAction)
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var errorColor: Color {
        switch systemImage {
        case let image where image.contains("wifi") || image.contains("network"):
            return .orange
        case let image where image.contains("lock") || image.contains("key"):
            return .red
        case let image where image.contains("exclamationmark"):
            return .orange
        case let image where image.contains("xmark"):
            return .red
        default:
            return .orange
        }
    }
}

// MARK: - Specialized Error Views

struct NetworkErrorView: View {
    let onRetry: () -> Void
    
    var body: some View {
        ErrorView(
            title: "Connection Problem",
            message: "Unable to connect to our servers. Please check your internet connection and try again.",
            systemImage: "wifi.exclamationmark",
            retryAction: onRetry
        )
    }
}

struct AuthenticationErrorView: View {
    let onSignIn: () -> Void
    
    var body: some View {
        ErrorView(
            title: "Authentication Required",
            message: "Your session has expired. Please sign in again to continue.",
            systemImage: "key.fill",
            retryAction: onSignIn
        )
    }
}

struct ServerErrorView: View {
    let onRetry: () -> Void
    
    var body: some View {
        ErrorView(
            title: "Server Error",
            message: "Our servers are experiencing issues. Please try again in a few moments.",
            systemImage: "server.rack",
            retryAction: onRetry
        )
    }
}

struct PermissionErrorView: View {
    let permissionType: String
    let onOpenSettings: () -> Void
    
    var body: some View {
        ErrorView(
            title: "\(permissionType) Permission Required",
            message: "This feature requires access to \(permissionType.lowercased()). Please enable permissions in Settings.",
            systemImage: "lock.shield.fill",
            retryAction: onOpenSettings
        )
    }
}

struct DataUnavailableErrorView: View {
    let dataType: String
    let onRefresh: (() -> Void)?
    
    init(dataType: String, onRefresh: (() -> Void)? = nil) {
        self.dataType = dataType
        self.onRefresh = onRefresh
    }
    
    var body: some View {
        ErrorView(
            title: "No \(dataType) Available",
            message: "We couldn't find any \(dataType.lowercased()) to display. Try refreshing or check back later.",
            systemImage: "chart.line.downtrend.xyaxis",
            retryAction: onRefresh
        )
    }
}

// MARK: - API Error Handling

extension ErrorView {
    init(apiError: APIError, onRetry: (() -> Void)? = nil) {
        switch apiError {
        case .networkError:
            self.init(
                title: "Connection Problem",
                message: "Unable to connect to our servers. Please check your internet connection.",
                systemImage: "wifi.exclamationmark",
                retryAction: onRetry
            )
        case .unauthorized:
            self.init(
                title: "Authentication Required",
                message: "Your session has expired. Please sign in again.",
                systemImage: "key.fill",
                retryAction: onRetry
            )
        case .serverError(let statusCode, let message):
            let serverMessage = message ?? "The server encountered an error."
            self.init(
                title: "Server Error (\(statusCode))",
                message: serverMessage,
                systemImage: "server.rack",
                retryAction: onRetry
            )
        case .decodingError:
            self.init(
                title: "Data Format Error",
                message: "The data we received was in an unexpected format. Please try again.",
                systemImage: "doc.text.fill",
                retryAction: onRetry
            )
        case .invalidURL:
            self.init(
                title: "Configuration Error",
                message: "There's a problem with the app configuration. Please contact support.",
                systemImage: "gear.badge.xmark",
                retryAction: onRetry
            )
        case .unknown(let error):
            self.init(
                title: "Unexpected Error",
                message: error.localizedDescription,
                systemImage: "questionmark.circle.fill",
                retryAction: onRetry
            )
        case .notImplemented:
            self.init(
                title: "Feature Unavailable",
                message: "This feature is not yet implemented. Please check back later.",
                systemImage: "wrench.and.screwdriver",
                retryAction: nil
            )
        case .validationError(let message):
            self.init(
                title: "Invalid Data",
                message: message,
                systemImage: "exclamationmark.triangle.fill",
                retryAction: onRetry
            )
        case .httpError(let statusCode, _):
            self.init(
                title: "HTTP Error \(statusCode)",
                message: "An error occurred while communicating with the server.",
                systemImage: "network.badge.shield.half.filled",
                retryAction: onRetry
            )
        case .missingAuthToken:
            self.init(
                title: "Authentication Missing",
                message: "Please sign in to continue.",
                systemImage: "person.badge.key.fill",
                retryAction: onRetry
            )
        }
    }
}

// MARK: - Preview

#Preview("General Error") {
    ErrorView(
        title: "Something went wrong",
        message: "We encountered an unexpected error while processing your request. Please try again.",
        retryAction: {},
        dismissAction: {}
    )
}

#Preview("Network Error") {
    NetworkErrorView(onRetry: {})
}

#Preview("Auth Error") {
    AuthenticationErrorView(onSignIn: {})
}

#Preview("Permission Error") {
    PermissionErrorView(permissionType: "HealthKit", onOpenSettings: {})
}
