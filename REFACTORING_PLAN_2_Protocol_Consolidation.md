# Refactoring Plan 2: Consolidate All Protocols

**Objective:** Enforce the "Single Source of Truth" for protocols by moving all service and repository protocol definitions into one file.

**Violation:** Protocols are defined in multiple locations, violating the architectural directive for a centralized `Domain/Protocols.swift` file.

**Execution Steps:**

1.  **Create `Protocols.swift`:**
    *   Create a new, empty file at the path: `clarity-loop-frontend/Domain/Protocols.swift`.

2.  **Gather All Protocol Definitions:**
    *   Systematically open each of the following files and copy the protocol definition from it:
        *   `clarity-loop-frontend/Core/Networking/APIClient.swift` -> `APIClientProtocol`, `Endpoint`, `HTTPMethod`.
        *   `clarity-loop-frontend/Core/Services/AuthService.swift` -> `AuthServiceProtocol`.
        *   `clarity-loop-frontend/Core/Services/HealthKitServiceProtocol.swift` -> `HealthKitServiceProtocol`.
        *   `clarity-loop-frontend/Domain/Repositories/HealthDataRepositoryProtocol.swift` -> `HealthDataRepositoryProtocol`.
        *   `clarity-loop-frontend/Domain/Repositories/InsightsRepositoryProtocol.swift` -> `InsightsRepositoryProtocol`.
        *   `clarity-loop-frontend/Domain/Repositories/UserRepositoryProtocol.swift` -> `UserRepositoryProtocol`.

3.  **Define Missing `AuthRepositoryProtocol`:**
    *   Based on the `IMPLEMENTATION_PLAN_Core_Architecture.md` and the responsibilities of the `AuthService`, define a new `AuthRepositoryProtocol` within the gathered list of protocols.
    *   Its methods should mirror the authentication-related methods of `AuthServiceProtocol`. This will decouple the `AuthService` from the concrete `FirebaseAuthRepository` that will be created in the next step.
    *   **Example Definition:**
        ```swift
        protocol AuthRepositoryProtocol {
            var authState: AsyncStream<FirebaseAuth.User?> { get }
            var currentUser: FirebaseAuth.User? { get }
            func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO
            // ... and other auth methods
        }
        ```

4.  **Populate `Protocols.swift`:**
    *   Paste all gathered protocol definitions (including the new `AuthRepositoryProtocol`) into the `clarity-loop-frontend/Domain/Protocols.swift` file.
    *   Add necessary `import` statements at the top (e.g., `Foundation`, `FirebaseAuth`, `HealthKit`).

5.  **Clean Up Original Locations:**
    *   Go back to each file from which a protocol was copied.
    *   **Delete** the protocol definition from that file, leaving only the class/struct implementation.
    *   For example, in `APIClient.swift`, delete `protocol APIClientProtocol { ... }`, `protocol Endpoint { ... }`, and `enum HTTPMethod { ... }`.

6.  **Delete Redundant Files:**
    *   Delete the following now-empty or redundant protocol files:
        *   `clarity-loop-frontend/Core/Services/HealthKitServiceProtocol.swift`
        *   `clarity-loop-frontend/Domain/Repositories/HealthDataRepositoryProtocol.swift`
        *   `clarity-loop-frontend/Domain/Repositories/InsightsRepositoryProtocol.swift`
        *   `clarity-loop-frontend/Domain/Repositories/UserRepositoryProtocol.swift`
    *   Delete the now-empty directory: `clarity-loop-frontend/Domain/Repositories`.

7.  **Verification:**
    *   After completing all file modifications, execute `xcodebuild build -scheme "clarity-loop-frontend" -destination "generic/platform=iOS"`.
    *   The build MUST succeed. The compiler needs to be able to find all type definitions (like DTOs) referenced in the new `Protocols.swift` file. The file's target membership in Xcode is critical here. 