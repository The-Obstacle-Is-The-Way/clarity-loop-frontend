import Foundation
import UIKit

/// Helper for generating device information for API requests
enum DeviceInfoHelper {
    
    /// Sanitize string to prevent JSON encoding issues
    private static func sanitizeString(_ input: String) -> String {
        return input
            .replacingOccurrences(of: "\\", with: "")  // Remove backslashes
            .replacingOccurrences(of: "\"", with: "")  // Remove quotes
            .replacingOccurrences(of: "'", with: "")   // Remove single quotes
            .replacingOccurrences(of: "\n", with: " ") // Replace newlines with space
            .replacingOccurrences(of: "\r", with: " ") // Replace carriage returns
            .replacingOccurrences(of: "\t", with: " ") // Replace tabs
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Generate device info dictionary for login requests
    static func generateDeviceInfo() -> [String: AnyCodable] {
        var deviceInfo: [String: AnyCodable] = [:]
        
        // Device ID
        if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
            deviceInfo["device_id"] = AnyCodable(sanitizeString(deviceId))
        }
        
        // OS Version
        let osVersion = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        deviceInfo["os_version"] = AnyCodable(sanitizeString(osVersion))
        
        // App Version
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            let versionString = "\(appVersion) (\(buildNumber))"
            deviceInfo["app_version"] = AnyCodable(sanitizeString(versionString))
        }
        
        // Device Model
        deviceInfo["device_model"] = AnyCodable(sanitizeString(UIDevice.current.model))
        
        // Device Name (heavily sanitized)
        let deviceName = UIDevice.current.name
            .replacingOccurrences(of: "'s", with: "")
            .replacingOccurrences(of: "'s", with: "")  // Smart apostrophe variant
        deviceInfo["device_name"] = AnyCodable(sanitizeString(deviceName))
        
        return deviceInfo
    }
    
    /// Generate minimal device info for testing
    static func generateMinimalDeviceInfo() -> [String: AnyCodable] {
        return [
            "device_id": AnyCodable("test-device"),
            "os_version": AnyCodable("iOS 18.0"),
            "app_version": AnyCodable("1.0.0")
        ]
    }
}