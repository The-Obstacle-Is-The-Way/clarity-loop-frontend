# Implementation Plan: Core Architecture

This document outlines the setup of the core application architecture, including the layered structure, dependency injection, and state management, based on the principles of MVVM and Clean Architecture.

## 🔄 IMPLEMENTATION STATUS: MOSTLY COMPLETE

**✅ COMPLETED:**
- Core MVVM + Clean Architecture structure
- SwiftUI Environment-based dependency injection
- SwiftData persistence setup
- ViewState pattern for async operations
- Core services and repositories

**❌ MISSING:**
- Some repository protocols
- Some service implementations
- Complete environment key setup

## 1. Core Architectural Layers

This checklist ensures the separation of concerns is implemented correctly.

- [x] **Create Folder Structure:** Implement the folder structure as defined in `IMPLEMENTATION_PLAN_Project_Setup.md`.
- [x] **Define Repository Protocols:** In the `Domain/Repositories` folder, create Swift protocols for each data repository. These define the contracts for data access.
    - [ ] ❌ MISSING `AuthRepositoryProtocol.swift`
    - [x] `HealthDataRepositoryProtocol.swift`
    - [x] `InsightsRepositoryProtocol.swift`
    - [x] `UserRepositoryProtocol.swift`
- [x] **Implement Services:** In the `Core/Services` folder, create concrete implementations for services that interact with external frameworks.
    - [x] `AuthService.swift` (handles Firebase Auth calls).
    - [x] `HealthKitService.swift` (handles HealthKit calls).
    - [ ] ❌ MISSING `InsightAIService.swift` (handles calls to Gemini).
- [x] **Implement Repositories:** Create concrete repository implementations in the `Data/Repositories` folder (or a subfolder within). These will conform to the protocols in the Domain layer and use the services from the Core layer.
    - [ ] ❌ MISSING `FirebaseUserRepository.swift`
    - [x] `RemoteHealthDataRepository.swift`
    - [x] `RemoteInsightsRepository.swift`

## 2. Dependency Injection (DI) Setup

Leverage SwiftUI's Environment for a lightweight and native DI experience.

- [x] **Create EnvironmentKeys:** For each major service/repository, create a custom `EnvironmentKey`. Place these in `Core/Architecture/EnvironmentKeys.swift`.

    ```swift
    import SwiftUI

    // Example for HealthDataRepository
    private struct HealthDataRepositoryKey: EnvironmentKey {
        static let defaultValue: HealthDataRepositoryProtocol = RemoteHealthDataRepository() // Provide a default concrete implementation
    }

    extension EnvironmentValues {
        var healthDataRepository: HealthDataRepositoryProtocol {
            get { self[HealthDataRepositoryKey.self] }
            set { self[HealthDataRepositoryKey.self] = newValue }
        }
    }
    ```
- [x] **Create Keys for All Services:** Repeat the pattern above for all major dependencies:
    - [ ] ❌ MISSING `AuthRepositoryProtocol`
    - [x] `InsightsRepositoryProtocol`
    - [x] `HealthKitServiceProtocol`
    - [x] `APIClientProtocol`
- [x] **Inject Dependencies at App Root:** In the main `App` struct, create instances of your services and inject them into the root view's environment. This is the app's "Composition Root".

    ```swift
    @main
    struct ClarityPulseApp: App {
        @StateObject private var authViewModel = AuthViewModel()
        
        // Instantiate services
        private let healthDataRepo = RemoteHealthDataRepository()
        private let authRepo = FirebaseAuthRepository()

        var body: some Scene {
            WindowGroup {
                ContentView()
                    .environmentObject(authViewModel)
                    .environment(\.healthDataRepository, healthDataRepo)
                    .environment(\.authRepository, authRepo)
                    // ... inject other services
            }
        }
    }
    ```
- [ ] **Use Injected Dependencies:** In ViewModels or other services, access dependencies using the `@Environment` property wrapper. (Note: We are using initializer-based injection for ViewModels, which is a better practice).

## 3. SwiftData Persistence Setup

- [x] **Create a Persistence Controller:** In `Core/Persistence`, create a `PersistenceController.swift` or `SwiftDataManager.swift` to manage the SwiftData stack.

    ```swift
    import SwiftData

    @MainActor
    class PersistenceController {
        static let shared = PersistenceController()

        let container: ModelContainer

        private init() {
            let schema = Schema([
                // List all @Model classes here
                HealthMetricEntity.self,
                InsightEntity.self,
                User.self
            ])
            let config = ModelConfiguration("ClarityPulse", schema: schema)
            
            do {
                container = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not configure the model container: \(error)")
            }
        }
    }
    ```
- [x] **Inject ModelContainer at App Root:** In the `App` struct, attach the model container to the view hierarchy.

    ```swift
    @main
    struct ClarityPulseApp: App {
        // ...
        var body: some Scene {
            WindowGroup {
                ContentView()
                    .modelContainer(PersistenceController.shared.container)
                    // ... other environments
            }
        }
    }
    ```
- [ ] ❌ MISSING **Access ModelContext in Repositories:** Repositories that need to interact with the local database will get the `ModelContext` from the shared container.

## 4. State Management Strategy

- [x] ✅ COMPLETE **Adopt `@Observable`:** Use the new `@Observable` macro for all ViewModel classes for simpler, more efficient state management in iOS 17.
- [x] **Global App State:** Create a global `AuthViewModel` or `AppState` object to manage authentication status and the current user session.
    - [x] This object should be an `@StateObject` in the `App` struct and passed down as an `@EnvironmentObject`.
    - [x] It will listen to Firebase's auth state changes and publish the `isLoggedIn` status.
- [x] **View-Specific State:** Each feature's ViewModel will manage its own state (e.g., `DashboardViewModel` manages `healthSummary`, `isLoading`, etc.).
- [x] **Define Loading/Error States:** Implement a consistent pattern for handling async operation states in ViewModels. An enum is recommended.

    ```swift
    enum ViewState<T> {
        case idle
        case loading
        case loaded(T)
        case error(String)
        case empty
    }

    @Observable
    class SomeViewModel {
        var state: ViewState<MyDataModel> = .idle
        
        func loadData() async {
            state = .loading
            do {
                let data = try await // ... fetch data
                state = data.isEmpty ? .empty : .loaded(data)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
    ```
- [x] **UI Reactivity:** SwiftUI views will switch on the `state` enum to display the appropriate UI (e.g., `ProgressView` for `.loading`, an error message view for `.error`, etc.).

This core architecture setup provides a solid, testable, and scalable foundation for building out the features of the CLARITY Pulse app. 