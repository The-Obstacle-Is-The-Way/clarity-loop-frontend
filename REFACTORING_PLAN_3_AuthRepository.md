# Refactoring Plan 3: Introduce AuthRepository

**Objective:** Implement the `AuthRepository` layer to decouple the `AuthService` from direct `APIClient` and Firebase interaction, adhering to Clean Architecture principles.

**Violation:** `AuthService` directly calls Firebase and `APIClient`, violating the architectural layering which mandates a repository intermediary.

**Execution Steps:**

1.  **Create `FirebaseAuthRepository.swift`:**
    *   Create a new file at path: `clarity-loop-frontend/Data/Repositories/FirebaseAuthRepository.swift`. (Note: The `Repositories` directory within `Data` should already exist).

2.  **Implement `FirebaseAuthRepository`:**
    *   Define a `final class FirebaseAuthRepository`.
    *   Make this class conform to the `AuthRepositoryProtocol` defined in `Protocols.swift`.
    *   This repository will depend on the `AuthService` and the `APIClient`.
    *   **Dependencies:**
        *   `private let authService: AuthServiceProtocol`
        *   `private let apiClient: APIClientProtocol`
    *   **Initializer:** Create an `init` that accepts these two protocols as parameters.

3.  **Implement Protocol Methods:**
    *   Implement all methods required by `AuthRepositoryProtocol`.
    *   These methods will primarily be wrappers that delegate the call to the corresponding method in `authService` or `apiClient`.
    *   For example:
        ```swift
        final class FirebaseAuthRepository: AuthRepositoryProtocol {
            private let authService: AuthServiceProtocol
            private let apiClient: APIClientProtocol

            init(authService: AuthServiceProtocol, apiClient: APIClientProtocol) {
                self.authService = authService
                self.apiClient = apiClient
            }

            func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO {
                // This would call authService, which in turn would handle Firebase sign-in
                // and then the repository would call the apiClient to get user data from your backend.
                // The logic needs to be carefully split here.
                let firebaseUser = try await authService.signInWithFirebase(email: email, password: password) // Assume this method just does firebase.
                return try await apiClient.login(requestDTO: .init(email: email, password: password, rememberMe: true, deviceInfo: nil))
            }
            // ... implement other methods
        }
        ```
    *   **NOTE:** This step will require refactoring `AuthService` itself. The methods that call `APIClient` (`register`, `login`) will be moved out of `AuthService` and into `FirebaseAuthRepository`. `AuthService` will become a pure wrapper for the Firebase SDK only.

4.  **Refactor `AuthService`:**
    *   Modify `AuthService` to remove its dependency on `APIClient`.
    *   Its methods will now only perform direct Firebase actions (e.g., `Auth.auth().signIn(...)`). They will return Firebase-native types (e.g., `AuthDataResult`).
    *   The service's responsibility shrinks to *only* managing Firebase authentication state and actions.

5.  **Update Composition Root:**
    *   In `clarity_loop_frontendApp.swift` (or wherever dependencies are composed):
        1.  Instantiate `APIClient`.
        2.  Instantiate `AuthService`.
        3.  Call `apiClient.setTokenProvider(...)` as defined in Plan 1.
        4.  Instantiate the new `FirebaseAuthRepository`, passing it the `authService` and `apiClient` instances.
        5.  Update any ViewModels that depended on `AuthService` to now depend on `AuthRepositoryProtocol` instead. This is a crucial final step to complete the decoupling.

6.  **Verification:**
    *   After the refactoring is complete, execute `xcodebuild build -scheme "clarity-loop-frontend" -destination "generic/platform=iOS"`.
    *   The build MUST succeed. 