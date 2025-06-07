# Refactoring Plan 4: Final Audit and Cleanup

**Objective:** Ensure full compliance with all project directives after major refactoring.

**Violation:** Potential remaining `public` modifiers or other minor violations.

**Execution Steps:**

1.  **Global Search for `public`:**
    *   Perform a project-wide, case-sensitive search for the keyword `public `.
    *   This includes `public func`, `public class`, `public var`, etc.

2.  **Replace with `internal`:**
    *   For every instance found within the `clarity-loop-frontend` target (excluding test targets):
    *   Remove the `public` keyword. The default access level in Swift is `internal`, which is what the directive requires. Do not explicitly write `internal`.

3.  **Review Test Code Directives:**
    *   Ensure all mocks are located exclusively in `clarity-loop-frontendTests/Mocks/`.
    *   Verify that no mock files are included as compile sources for the main `clarity-loop-frontend` target.
    *   Check that all test files use `@testable import clarity_loop_frontend` to access the app's internal types.

4.  **Full Verification Cycle:**
    *   Execute the complete verification process one last time to confirm the final state of the codebase.
    *   **Build:** `xcodebuild build -scheme "clarity-loop-frontend" -destination "generic/platform=iOS"`
    *   **Lint:** Run SwiftLint (assuming it's configured).
    *   **Test:** Run the unit tests on a specific simulator destination. Example: `xcodebuild test -scheme "clarity-loop-frontend" -destination "platform=iOS Simulator,name=iPhone 15 Pro,OS=18.4"`.
    *   The entire cycle must pass without errors.

**Conclusion:**

Upon the successful completion of all four refactoring plans, the codebase will have a stable, compliant, and robust architectural foundation. Only at that point will the implementation of new features, starting with the Authentication flow, commence. 