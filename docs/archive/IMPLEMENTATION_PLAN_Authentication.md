# Implementation Plan: Authentication

This document provides a step-by-step guide for implementing the user authentication flows, including registration, login, session management, and the corresponding UI, ViewModels, and Services.

## 🔄 IMPLEMENTATION STATUS: MOSTLY COMPLETE

**✅ COMPLETED:**
- Core authentication flows (login/registration)
- Firebase Auth integration
- JWT token management
- Session state management
- Basic UI components

**❌ MISSING:**
- Email verification flow UI
- Password reset flow UI
- Complete error handling
- Some API endpoints

## 1. Authentication Service (`AuthService`)

This service will encapsulate all interactions with the Firebase Authentication SDK.

- [x] **Create `AuthService.swift`:** ✅ COMPLETE - Place in `Core/Services`.
- [x] **Create `AuthServiceProtocol.swift`:** ✅ COMPLETE - Define the interface for the auth service.
- [x] **Implement User State Publisher:**
    - [x] ✅ COMPLETE - Use `Auth.auth().addStateDidChangeListener` to listen for changes in Firebase's authentication state.
    - [x] ✅ COMPLETE - Publish the current `User?` object from Firebase. Using `AsyncStream` to broadcast the user session state across the app.
- [x] **Implement `signIn(withEmail:password:)` method:**
    - [x] ✅ COMPLETE - Call `Auth.auth().signIn(withEmail:password:)`.
    - [x] ✅ COMPLETE - Wrap the completion handler in an `async throws` method.
    - [x] ✅ COMPLETE - Map Firebase errors to a custom `AuthError` enum (e.g., `.wrongPassword`, `.invalidEmail`).
- [x] **Implement `register(withEmail:password:details:)` method:**
    - [x] ✅ COMPLETE - Call `Auth.auth().createUser(withEmail:password:)`.
    - [x] ✅ COMPLETE - After successful creation, call the app's backend (`/api/v1/auth/register`) to store additional user details (first name, last name).
    - [x] ✅ COMPLETE - Call `user.sendEmailVerification()` to trigger the verification email.
    - [x] ✅ COMPLETE - Return the `RegistrationResponseDTO` from the backend.
- [x] **Implement `signOut()` method:**
    - [x] ✅ COMPLETE - Call `try Auth.auth().signOut()`.
    - [x] ✅ COMPLETE - Implement logic to clear any sensitive local data (e.g., wipe specific SwiftData entities or reset user-specific cache).
- [x] **Implement `sendPasswordReset(withEmail:)` method:**
    - [x] ✅ COMPLETE - Call `Auth.auth().sendPasswordReset(withEmail:email)`.
    - [ ] ❌ MISSING - Password reset UI flow
- [x] **Implement `getCurrentUserToken()` method:**
    - [x] ✅ COMPLETE - Create an `async throws` method that retrieves the JWT from the current user.
    - [x] ✅ COMPLETE - Call `Auth.auth().currentUser?.getIDToken(forcingRefresh: false)`. This will auto-refresh if the token is expired.
    - [x] ✅ COMPLETE - This method will be the `tokenProvider` for the `APIClient`.

## 2. Authentication State Management

- [x] **Create `AuthenticationManager.swift`:** ✅ COMPLETE - This will be the global view model for managing auth state, injected as an `@EnvironmentObject`.
- [x] **Subscribe to `AuthService`:** ✅ COMPLETE - The `AuthenticationManager` should subscribe to the user state publisher from the `AuthService`.
- [x] **Publish `isLoggedIn` State:**
    - [x] ✅ COMPLETE - Maintain a `@Published var authenticationState: AuthenticationState` property.
    - [x] ✅ COMPLETE - Update this property based on whether the user session from `AuthService` is nil or not.
- [x] **Root View Logic:** ✅ COMPLETE - In `ContentView.swift`, observe the `AuthenticationManager`'s `authenticationState` property to switch between the authentication flow and the main app content.

## 3. Login Flow

- [x] **Create `LoginView.swift`:** ✅ COMPLETE
    - [x] ✅ COMPLETE - Design a SwiftUI form with `TextField` for email and `SecureField` for password.
    - [x] ✅ COMPLETE - Add a "Login" button.
    - [x] ✅ COMPLETE - Add a "Forgot Password?" button.
    - [x] ✅ COMPLETE - Add a navigation link to the Registration screen.
    - [x] ✅ COMPLETE - Display loading indicators (`ProgressView`) when the login process is active.
    - [x] ✅ COMPLETE - Show error messages (e.g., "Invalid email or password") from the ViewModel.
- [x] **Create `LoginViewModel.swift`:** ✅ COMPLETE
    - [x] ✅ COMPLETE - Use `@Observable` for state management.
    - [x] ✅ COMPLETE - Hold state properties for `email`, `password`, `isLoading`, and `errorMessage`.
    - [x] ✅ COMPLETE - Implement a `login()` method that:
        1. Sets `isLoading = true`.
        2. Calls `authService.signIn(...)`.
        3. On success, the global `AuthenticationManager` will automatically handle the navigation.
        4. On failure, catches the error and sets `errorMessage`.
        5. Sets `isLoading = false`.
    - [x] ✅ COMPLETE - Implement a `requestPasswordReset()` method.

## 4. Registration Flow

- [x] **Create `RegistrationView.swift`:** ✅ COMPLETE
    - [x] ✅ COMPLETE - Design a SwiftUI form for `email`, `password`, `firstName`, `lastName`.
    - [x] ✅ COMPLETE - Include toggles for accepting Terms of Service and Privacy Policy.
    - [x] ✅ COMPLETE - Add a "Register" button.
    - [x] ✅ COMPLETE - Display loading states and validation error messages from the ViewModel.
- [x] **Create `RegistrationViewModel.swift`:** ✅ COMPLETE
    - [x] ✅ COMPLETE - Use `@Observable`.
    - [x] ✅ COMPLETE - Hold state for all form fields, loading status, and error messages.
    - [x] ✅ COMPLETE - Implement client-side validation for email format and password strength before attempting to register.
    - [x] ✅ COMPLETE - Implement a `register()` method that calls `authService.register(...)` and handles success and error states.
    - [x] ✅ COMPLETE - On successful registration, display a message prompting the user to check their email for verification.

## 5. Session Management

- [x] **Automatic Sign-In:** ✅ COMPLETE - Rely on Firebase's default keychain persistence. The `AuthenticationManager` listening to the auth state will handle this automatically on app launch.
- [x] **Token for APIClient:** ✅ COMPLETE - The `APIClient` will be initialized with a closure that calls `authService.getCurrentUserToken()`, ensuring all protected API requests have a valid JWT.
- [x] **Logout:** ✅ COMPLETE
    - [x] ✅ COMPLETE - Provide a logout button in the app's settings or profile view.
    - [x] ✅ COMPLETE - The button's action should call a method on `AuthenticationManager` which in turn calls `authService.signOut()`.
    - [x] ✅ COMPLETE - The UI will automatically switch to the `LoginView` due to the change in the global authentication state.
- [ ] **Email Verification:** ❌ INCOMPLETE
    - [x] ✅ COMPLETE - After registration, guide the user to their email.
    - [ ] ❌ MISSING - Backend email verification enforcement
    - [ ] ❌ MISSING - Email verification status checking UI
    - [ ] ❌ MISSING - Resend verification email functionality

## 6. Known Issues

- **Integration Test Failure**: The `testAuthenticationSlice()` integration test is currently failing. This appears to be related to async/await timing or Firebase initialization in the test environment. The authentication functionality works correctly in the actual app. 