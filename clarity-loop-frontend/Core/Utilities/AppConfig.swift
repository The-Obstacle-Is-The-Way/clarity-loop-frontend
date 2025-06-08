import Foundation

/// Centralized application configuration
/// Provides a single source of truth for environment-specific settings
struct AppConfig {
    
    // MARK: - API Configuration
    
    /// Base URL for the CLARITY backend API
    /// TODO: Move to environment-based configuration (Info.plist or xcconfig) for proper dev/staging/prod switching
    static let apiBaseURL = "https://crave-trinity-prod--clarity-backend-fastapi-app.modal.run"
    
    // MARK: - Preview Configuration
    
    /// Base URL specifically for SwiftUI previews
    /// Uses the same production URL for now, but can be overridden for preview-specific needs
    static let previewAPIBaseURL = apiBaseURL
    
    // MARK: - Environment Detection
    
    /// Returns true if running in debug mode
    static var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Returns true if running in a simulator
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Future Enhancement Ideas

/// TODO: Add environment-based configuration
/// Example structure for future implementation:
/*
extension AppConfig {
    enum Environment {
        case development
        case staging
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                return "https://crave-trinity-dev--clarity-backend-fastapi-app.modal.run"
            case .staging:
                return "https://crave-trinity-staging--clarity-backend-fastapi-app.modal.run"
            case .production:
                return "https://crave-trinity-prod--clarity-backend-fastapi-app.modal.run"
            }
        }
    }
    
    static var currentEnvironment: Environment {
        // Read from Info.plist, xcconfig, or environment variable
        // For now, default to production
        return .production
    }
}
*/