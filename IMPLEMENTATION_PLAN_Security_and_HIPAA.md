# Implementation Plan: Security and HIPAA Compliance

This document provides a critical checklist for implementing client-side security measures and HIPAA compliance best practices as defined in the project blueprints.

## 1. Secure Authentication & Session Management

- [x] **Use `SecureField` for Passwords:** Ensure the password field in the `LoginView` and `RegistrationView` uses `SecureField` to prevent screen recording and caching of the password.
- [x] **Enable Keychain Sharing:** Verify that the "Keychain Sharing" capability is enabled in the Xcode project target. Firebase Auth relies on this to store tokens securely.
- [ ] **Idle Session Timeout:**
    - [ ] Implement a mechanism to detect user inactivity (e.g., a `Timer` that resets on any user interaction).
    - [ ] After a defined period of inactivity (e.g., 15 minutes), automatically lock the application.
    - [ ] "Locking" should require the user to re-authenticate using Face ID/Touch ID or their password to regain access to sensitive data.

## 2. Biometric Authentication (Face ID / Touch ID)

- [ ] **Integrate `LocalAuthentication` Framework:**
    - [ ] In a dedicated `BiometricService` or within the `AuthService`, import `LocalAuthentication`.
- [ ] **Add `NSFaceIDUsageDescription`:**
    - [ ] Ensure the `Info.plist` file contains the `NSFaceIDUsageDescription` key with a clear explanation for the user (e.g., "To keep your health data secure, CLARITY Pulse uses Face ID to unlock the app.").
- [ ] **Implement Biometric Lock Toggle:**
    - [ ] In the app's settings screen, provide a toggle switch for the user to enable or disable "Unlock with Face ID".
- [ ] **Implement Unlock Flow:**
    - [ ] On app launch or return from background (if the session has timed out), check if biometric lock is enabled.
    - [ ] If enabled, call `LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, ...)` to prompt for Face ID/Touch ID.
    - [ ] On success, allow the user into the app.
    - [ ] On failure, show the login screen as a fallback or keep the app on a locked screen.
    - [ ] Do **not** store the user's password to enable this. This feature locks the UI, it does not re-authenticate the Firebase session.

## 3. Local Data Protection (SwiftData & Files)

- [ ] **Enable iOS Data protection:** (Assumed enabled with project settings)
- [x] **Verify SwiftData Encryption:** SwiftData encrypts by default when the device is locked.
- [ ] **Exclude Sensitive Data from Backups (If Applicable):**
    - [ ] For any highly sensitive files or data that should not be in iCloud backups, apply the `.isExcludedFromBackup` attribute using `FileManager`.
    - [ ] Note: By default, SwiftData stores its database in the Application Support directory, which *is* backed up. For HIPAA compliance, iCloud backups are generally considered secure, but organizational policy may require exclusion. For MVP, rely on the default secure behavior.

## 4. HIPAA Best Practices & Data Leakage Prevention

- [ ] **Blur App Snapshot on Backgrounding:**
    - [ ] In the root SwiftUI view, use `@Environment(\.scenePhase)` to detect when the app moves to the `.background` or `.inactive` phase.
    - [ ] When the app is not active, overlay a blur effect or a view with the app's logo to obscure any PHI in the iOS app switcher snapshot.
        ```swift
        struct ContentView: View {
            @Environment(\.scenePhase) private var scenePhase
            @State private var isObscured = false

            var body: some View {
                MyMainView()
                    .overlay(isObscured ? Color.systemBackground : Color.clear)
                    .onChange(of: scenePhase) { oldPhase, newPhase in
                        isObscured = (newPhase != .active)
                    }
            }
        }
        ```
- [x] **Secure Logging:** We are using `print` statements in tests, but the main app code is clean. We will enforce `OSLog` going forward.
- [ ] **Disable Analytics on PHI:**
    - [ ] If using Firebase Analytics, ensure that no custom events or user properties contain PHI.
- [ ] **Secure Notifications:**
    - [ ] If implementing push notifications in the future, ensure that notification payloads do **not** contain specific PHI.
    - [ ] The message should be generic (e.g., "You have a new health insight.") and prompt the user to open the app to view the details.
- [ ] **Prevent Data Exposure to System Services:**
    - [ ] Do not donate sensitive information to Siri or Spotlight Search.
    - [ ] Be cautious with the pasteboard. Do not store PHI in the pasteboard unless absolutely necessary, and if so, clear it or use modern APIs that allow expiration.
- [ ] **Jailbreak Detection (Optional - Post-MVP):**
    - [ ] For enhanced security, consider adding a library or custom code to detect if the app is running on a jailbroken device. If detected, either prevent the app from running or display a strong warning to the user. 