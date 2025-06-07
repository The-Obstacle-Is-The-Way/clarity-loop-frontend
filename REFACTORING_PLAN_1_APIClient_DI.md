# Refactoring Plan 1: Correct APIClient Dependency Injection

**Objective:** Modify the `APIClient` to break the initialization dependency cycle with `AuthService`.

**Violation:** The `APIClient`'s `tokenProvider` dependency is currently injected via its initializer. The project directives mandate a setter method to break the DI cycle.

**Execution Steps:**

1.  **Locate `APIClient.swift`:**
    *   File Path: `clarity-loop-frontend/Core/Networking/APIClient.swift`

2.  **Modify `APIClient` Properties:**
    *   Change the `tokenProvider` property from a non-optional constant (`let`) to an optional variable (`var`).
    *   **From:** `private let tokenProvider: () async -> String?`
    *   **To:** `private var tokenProvider: (() async -> String?)?`

3.  **Modify `APIClient` Initializer:**
    *   Remove the `tokenProvider` parameter from the `init?` method signature.
    *   Remove the line `self.tokenProvider = tokenProvider` from the initializer body.
    *   The initializer will now be simpler, only taking `baseURLString` and `session`.

4.  **Create Setter Method:**
    *   Add a new public method to the `APIClient` class named `setTokenProvider`.
    *   This method will take one parameter: a closure of type `@escaping () async -> String?`.
    *   **Method Signature:** `func setTokenProvider(_ provider: @escaping () async -> String?)`
    *   **Implementation:** The method will assign the provided closure to the `self.tokenProvider` property.

5.  **Update Call Site (Composition Root):**
    *   Identify where `APIClient` and `AuthService` are instantiated. This is the application's "Composition Root," likely in `clarity_loop_frontendApp.swift`.
    *   The current instantiation logic creates a cycle. It must be updated.
    *   **Instantiation Order:**
        1.  Instantiate `APIClient`.
        2.  Instantiate `AuthService`, passing the `apiClient` instance to its initializer.
        3.  Call the new `apiClient.setTokenProvider` method, passing a closure that captures `authService` weakly and calls its `getCurrentUserToken()` method. Using `[weak authService]` is critical to prevent a retain cycle.
    *   **Example Closure:** `apiClient.setTokenProvider { [weak authService] in return try? await authService?.getCurrentUserToken() }`

6.  **Update `performRequest` Method:**
    *   The `performRequest` method in `APIClient` must be updated to safely unwrap the optional `tokenProvider`.
    *   **From:** `guard let token = await tokenProvider() else { ... }`
    *   **To:** `guard let tokenProvider = self.tokenProvider, let token = await tokenProvider() else { ... }`

7.  **Verification:**
    *   After completing all code changes for this step, execute `xcodebuild build -scheme "clarity-loop-frontend" -destination "generic/platform=iOS"`.
    *   The build MUST succeed before proceeding to the next refactoring plan. 