# Implementation Plan: Authentication

This document provides a step-by-step guide for implementing the user authentication flows, including registration, login, session management, and the corresponding UI, ViewModels, and Services.

## 1. Authentication Service (`AuthService`)

This service will encapsulate all interactions with the Firebase Authentication SDK.

- [x] **Create `AuthService.swift`:** Place in `Core/Services`.
- [x] **Create `AuthServiceProtocol.swift`:** Define the interface for the auth service.
- [x] **Implement User State Publisher:**
    - [ ] Use `Auth.auth().addStateDidChangeListener` to listen for changes in Firebase's authentication state.
    - [ ] Publish the current `User?` object from Firebase. A Combine `CurrentValueSubject` or an `AsyncStream` can be used to broadcast the user session state across the app.
- [x] **Implement `signIn(withEmail:password:)` method:**
    - [ ] Call `Auth.auth().signIn(withEmail:password:)`.
    - [ ] Wrap the completion handler in an `async throws` method.
    - [ ] Map Firebase errors to a custom `AuthError` enum (e.g., `.wrongPassword`, `.invalidEmail`).
- [x] **Implement `register(withEmail:password:details:)` method:**
    - [ ] Call `Auth.auth().createUser(withEmail:password:)`.
    - [ ] After successful creation, call the app's backend (`/api/v1/auth/register`) to store additional user details (first name, last name).
    - [ ] Call `user.sendEmailVerification()` to trigger the verification email.
    - [ ] Return the `RegistrationResponseDTO` from the backend.
- [x] **Implement `signOut()` method:**
    - [ ] Call `try Auth.auth().signOut()`.
    - [ ] Implement logic to clear any sensitive local data (e.g., wipe specific SwiftData entities or reset user-specific cache).
- [x] **Implement `sendPasswordReset(withEmail:)` method:**
    - [ ] Call `Auth.auth().sendPasswordReset(withEmail:email)`.
- [x] **Implement `getCurrentUserToken()` method:**
    - [ ] Create an `async throws` method that retrieves the JWT from the current user.
    - [ ] Call `Auth.auth().currentUser?.getIDToken(forcingRefresh: false)`. This will auto-refresh if the token is expired.
    - [ ] This method will be the `tokenProvider` for the `APIClient`.

## 2. Authentication State Management

- [x] **Create `AuthViewModel.swift`:** This will be the global view model for managing auth state, injected as an `@EnvironmentObject`.
- [x] **Subscribe to `AuthService`:** The `AuthViewModel` should subscribe to the user state publisher from the `AuthService`.
- [x] **Publish `isLoggedIn` State:**
    - [ ] Maintain a `@Published var isLoggedIn: Bool` property.
    - [ ] Update this property based on whether the user session from `AuthService` is nil or not.
- [x] **Root View Logic:** In `ClarityPulseApp.swift` or a root `ContentView.swift`, observe the `AuthViewModel`'s `isLoggedIn` property to switch between the authentication flow and the main app content.

    ```swift
    struct RootView: View {
        @EnvironmentObject var authViewModel: AuthViewModel

        var body: some View {
            if authViewModel.isLoggedIn {
                MainTabView() // Or DashboardView
            } else {
                LoginView()
            }
        }
    }
    ```

## 3. Login Flow

- [x] **Create `LoginView.swift`:**
    - [ ] Design a SwiftUI form with `TextField` for email and `SecureField` for password.
    - [ ] Add a "Login" button.
    - [ ] Add a "Forgot Password?" button.
    - [ ] Add a navigation link to the Registration screen.
    - [ ] Display loading indicators (`ProgressView`) when the login process is active.
    - [ ] Show error messages (e.g., "Invalid email or password") from the ViewModel.
- [x] **Create `LoginViewModel.swift`:**
    - [ ] Use `@Observable` for state management.
    - [ ] Hold state properties for `email`, `password`, `isLoading`, and `errorMessage`.
    - [ ] Implement a `login()` method that:
        1. Sets `isLoading = true`.
        2. Calls `authService.signIn(...)`.
        3. On success, the global `AuthViewModel` will automatically handle the navigation.
        4. On failure, catches the error and sets `errorMessage`.
        5. Sets `isLoading = false`.
    - [ ] Implement a `requestPasswordReset()` method.

## 4. Registration Flow

- [x] **Create `RegistrationView.swift`:**
    - [ ] Design a SwiftUI form for `email`, `password`, `firstName`, `lastName`.
    - [ ] Include toggles for accepting Terms of Service and Privacy Policy.
    - [ ] Add a "Register" button.
    - [ ] Display loading states and validation error messages from the ViewModel.
- [x] **Create `RegistrationViewModel.swift`:**
    - [ ] Use `@Observable`.
    - [ ] Hold state for all form fields, loading status, and error messages.
    - [ ] Implement client-side validation for email format and password strength before attempting to register.
    - [ ] Implement a `register()` method that calls `authService.register(...)` and handles success and error states.
    - [ ] On successful registration, display a message prompting the user to check their email for verification.

## 5. Session Management

- [x] **Automatic Sign-In:** Rely on Firebase's default keychain persistence. The `AuthViewModel` listening to the auth state will handle this automatically on app launch.
- [x] **Token for APIClient:** The `APIClient` will be initialized with a closure that calls `authService.getCurrentUserToken()`, ensuring all protected API requests have a valid JWT.
- [ ] **Logout:**
    - [ ] Provide a logout button in the app's settings or profile view.
    - [x] The button's action should call a method on `AuthViewModel` which in turn calls `authService.signOut()`.
    - [x] The UI will automatically switch to the `LoginView` due to the change in the global `isLoggedIn` state.
- [ ] **Email Verification:**
    - [ ] After registration, guide the user to their email.
    - [ ] On the backend, API endpoints should reject requests from users whose `email_verified` claim in the JWT is `false`.
    - [ ] In the app, you can optionally add a screen that periodically checks `Auth.auth().currentUser?.isEmailVerified` and allows the user to resend the verification email. 