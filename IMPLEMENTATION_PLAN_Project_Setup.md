# Implementation Plan: Project Setup & Configuration

This document provides a detailed checklist for setting up the greenfield SwiftUI project for the CLARITY Pulse application.

## 1. Xcode Project Initialization

- [x] Create a new Xcode project.
- [x] **Platform:** iOS
- [x] **Application Template:** App
- [x] **Product Name:** `ClarityPulse` (or as per final naming decision)
- [x] **Interface:** SwiftUI
- [x] **Language:** Swift
- [x] **Storage:** SwiftData
- [x] **Include Tests:** Checked. This will create `ClarityPulseTests` and `ClarityPulseUITests` targets.
- [x] **Target iOS Version:** Set the deployment target to **iOS 17.0** or later to leverage the latest SwiftUI, SwiftData, and Observation framework features.

## 2. Dependency Management (Swift Package Manager)

The project will use Swift Package Manager (SPM) for all external dependencies.

- [x] **Add Firebase SDK:**
    - In Xcode, navigate to `File > Add Packages...`.
    - Enter the Firebase Apple SDK package URL: `https://github.com/firebase/firebase-ios-sdk.git`.
    - Select the following Firebase libraries required for the project:
        - `FirebaseAuth` (for user authentication)
        - `FirebaseCore` (will be added automatically)
        - `FirebaseAnalytics` (optional, for usage analytics - ensure it's configured to not log PHI).
        - `FirebaseCrashlytics` (optional, for crash reporting - ensure it's configured to not log PHI).

## 3. Firebase Integration

- [x] **Create Firebase Project:**
    - Go to the [Firebase Console](https://console.firebase.google.com/).
    - Create a new project for CLARITY.
    - Add an iOS app to the project, using the bundle identifier from your Xcode project.
- [x] **Download Configuration File:**
    - Download the `GoogleService-Info.plist` file from the Firebase project settings.
    - Add this file to the root of your Xcode project target. Ensure it's included in the "Copy Bundle Resources" build phase.
- [x] **Initialize Firebase in App:**
    - In your main SwiftUI `App` struct (e.g., `ClarityPulseApp.swift`), import Firebase and configure it in the initializer.

    ```swift
    import SwiftUI
    import FirebaseCore

    @main
    struct ClarityPulseApp: App {
        init() {
            FirebaseApp.configure()
        }

        var body: some Scene {
            WindowGroup {
                // Root view of the app
                ContentView() 
            }
        }
    }
    ```

## 4. Project Capabilities and Security Setup

- [x] **Enable Keychain Sharing:**
    - In the project settings, go to the `Signing & Capabilities` tab for your app target.
    - Click `+ Capability` and select **Keychain Sharing**. This is required for Firebase Auth to securely persist credentials.
- [ ] **Enable Push Notifications (for future use):**
    - Add the **Push Notifications** capability. This is needed for future real-time updates via APNs.
- [ ] **Enable Background Modes (for future use):**
    - Add the **Background Modes** capability.
    - Check the following modes:
        - `Background fetch` (for `BGAppRefreshTask`).
        - `Background processing` (for `BGProcessingTask` for HealthKit sync).
- [ ] **Set up Info.plist:**
    - Add the `NSFaceIDUsageDescription` key with a user-facing string explaining why the app needs Face ID (e.g., "Clarity Pulse uses Face ID to secure your health data.").
    - Add any URL schemes required for Firebase Authentication providers (e.g., Google Sign-In) if they are added in the future.

## 5. Project Folder Structure

Organize the project files into a clean, layered architecture. Create the following groups (folders) in Xcode:

- [x] **Application:**
    - `ClarityPulseApp.swift` (App entry point)
    - `Assets.xcassets`
    - `GoogleService-Info.plist`
- [x] **Core:**
    - **Architecture:** (DI setup, EnvironmentKeys, etc.)
    - **Networking:** (`APIClient`, `APIError`, endpoint definitions)
    - **Persistence:** (`SwiftDataManager`, persistence logic)
    - **Services:** (`AuthService`, `HealthKitService`, `InsightAIService`)
    - **Utilities:** (Extensions, helpers, etc.)
- [x] **Data:**
    - **Models:** (SwiftData `@Model` classes like `HealthMetricEntity`, `InsightEntity`, `User`)
    - **DTOs:** (Network Data Transfer Objects like `HealthMetricDTO`, `LoginRequestDTO`)
- [x] **Domain:**
    - **UseCases:** (e.g., `FetchDailyHealthSummaryUseCase`)
    - **Repositories:** (Protocols for data access, e.g., `HealthDataRepositoryProtocol`)
- [x] **Features:** (Each feature gets its own folder with View, ViewModel)
    - **Authentication:**
        - `LoginView.swift`
        - `LoginViewModel.swift`
        - `RegistrationView.swift`
        - `RegistrationViewModel.swift`
    - **Dashboard:**
        - `DashboardView.swift`
        - `DashboardViewModel.swift`
    - **Insights:**
        - `InsightsView.swift`
        - `InsightsViewModel.swift`
        - `ChatView.swift`
        - `ChatViewModel.swift`
- [x] **UI:**
    - **Components:** (Reusable views like `HealthMetricCard`, `PrimaryButtonStyle`, `MessageBubbleView`)
    - **Modifiers:** (Custom view modifiers)
    - **Theme:** (Color palette, font styles)

This structure clearly separates concerns and aligns with the proposed MVVM + Clean Architecture design. 