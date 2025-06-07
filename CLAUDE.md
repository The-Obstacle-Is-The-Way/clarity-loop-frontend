# CLARITY Pulse iOS Application

## Overview
CLARITY Pulse is a HIPAA-compliant iOS health data tracking application built with SwiftUI, following MVVM + Clean Architecture principles. The app integrates with HealthKit, Firebase, and provides secure biometric authentication for sensitive health data management.

## Architecture

### Design Pattern
- **MVVM + Clean Architecture** with Protocol-Oriented Design
- **SwiftUI + iOS 17's @Observable** for reactive UI
- **Environment-based Dependency Injection** for lightweight IoC
- **Repository Pattern** for data abstraction
- **ViewState<T>** pattern for async operation handling

### Layer Structure
```
UI Layer         → SwiftUI Views + ViewModels
Domain Layer     → Use Cases + Domain Models + Repository Protocols  
Data Layer       → Repositories + Services + DTOs
Core Layer       → Networking + Persistence + Utilities
```

### Key Frameworks
- **SwiftUI**: Primary UI framework
- **SwiftData**: Persistence (iOS 17+)
- **HealthKit**: Health data integration
- **Firebase**: Authentication & backend
- **LocalAuthentication**: Biometric auth

## Development Commands

### Build Commands
```bash
# Clean build
xcodebuild clean -scheme clarity-loop-frontend

# Debug build
xcodebuild -scheme clarity-loop-frontend -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16'

# Release build  
xcodebuild -scheme clarity-loop-frontend -configuration Release -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Test Commands
⚠️ **CURRENT ISSUE**: Test targets have compilation errors due to DTO mismatch in mock implementations. Fix test targets in Xcode before running.

```bash
# Unit tests (fix compilation issues first)
xcodebuild test -scheme clarity-loop-frontendTests -destination 'platform=iOS Simulator,name=iPhone 16'

# UI tests
xcodebuild test -scheme clarity-loop-frontendUITests -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Lint Commands
Currently no linting tools configured. Recommended to add:
- SwiftLint for style consistency
- SwiftFormat for auto-formatting
- Periphery for unused code detection

## Project Configuration

### Requirements
- **iOS**: 18.4+
- **Xcode**: 16.0+
- **Swift**: 5.0+

### Bundle Information
- **Bundle ID**: com.novamindnyc.clarity-loop-frontend
- **Development Team**: HJ7W9PTAD8

## Security & HIPAA Compliance

### Access Control Standards
- **PRIVATE by default**: All implementation details should be `private`
- **INTERNAL**: Module-internal access for shared components
- **PUBLIC**: Only for protocols and essential interfaces
- **NO public classes/structs** unless absolutely necessary for external access

### Security Features
- **Biometric Authentication**: Face ID/Touch ID via `BiometricAuthService`
- **Session Management**: Auto-logout with `SessionTimeoutService`
- **App Security**: Background blur, jailbreak detection via `AppSecurityService`
- **Secure Storage**: SwiftData with iOS file protection
- **Token Security**: Firebase Keychain storage for JWT tokens

## Testing Architecture

### Test Targets
1. **clarity-loop-frontendTests**: Unit tests with comprehensive mocks
2. **clarity-loop-frontendUITests**: SwiftUI UI automation tests

### Mock Strategy
Protocol-based mocks for all major services:
- `MockAuthService`
- `MockAPIClient` 
- `MockHealthKitService`
- Repository mocks

### Testing Guidelines
- Mock all external dependencies (Firebase, HealthKit, API)
- Use Environment injection for test doubles
- Test ViewModels in isolation
- Integration tests for critical health data flows

## Code Conventions

### Naming Patterns
- **ViewModels**: `[Feature]ViewModel` (e.g., `AuthViewModel`)
- **Services**: `[Purpose]Service` (e.g., `HealthKitService`)
- **Repositories**: `[Domain]Repository` (e.g., `RemoteHealthDataRepository`)
- **DTOs**: Descriptive names ending in `DTO`

### File Organization
```
clarity-loop-frontend/
├── Application/         # App lifecycle
├── Core/               # Infrastructure layer
│   ├── Architecture/   # ViewState, Environment keys
│   ├── Networking/     # API clients, endpoints
│   ├── Services/       # Business services
│   └── Persistence/    # SwiftData controllers
├── Data/               # Data layer
│   ├── DTOs/          # Data transfer objects
│   ├── Models/        # Data models (SwiftData)
│   └── Repositories/  # Repository implementations
├── Domain/             # Business logic layer
│   ├── Models/        # Domain models
│   └── Repositories/  # Repository protocols
├── Features/           # Feature modules (MVVM)
│   ├── Authentication/
│   ├── Dashboard/
│   ├── Insights/
│   └── Settings/
└── UI/                 # Shared UI components
    ├── Components/     # Reusable SwiftUI views
    └── Theme/          # Design system
```

### SwiftUI Best Practices
- Use `@Observable` for ViewModels (iOS 17+)
- Environment injection over singletons
- Prefer composition over inheritance
- Keep Views lightweight - logic in ViewModels
- Use `ViewState<T>` for async operations

## Critical Development Notes

### Test Target Issues
⚠️ **STOP CODING** if you encounter test compilation errors. Ask developer to fix test targets in Xcode since we're working in Cursor/external editor.

### Health Data Sensitivity
- All health data handling must maintain HIPAA compliance
- No logging of sensitive health information
- Secure data transmission only
- User consent required for all HealthKit access

### Firebase Integration
- Authentication handled by Firebase Auth
- JWT tokens auto-refreshed by Firebase SDK
- API calls use Bearer token authentication
- No manual token management required

## Development Workflow

### Before Starting Development
1. Ensure test targets compile in Xcode
2. Verify Firebase configuration
3. Check HealthKit permissions in simulator/device
4. Run clean build to verify setup

### Code Quality Checklist
- [ ] All new code follows access control standards (private by default)
- [ ] ViewModels use `@Observable` pattern
- [ ] Services implement protocols for testability  
- [ ] No sensitive data in logs
- [ ] Proper error handling with `ViewState<T>`
- [ ] Mock implementations for all external dependencies

### Recommended Tools to Add
- SwiftLint configuration
- SwiftFormat rules
- GitHub Actions CI/CD
- Fastlane for deployment automation

## Common Issues

### Test Compilation Errors
**Problem**: Mock implementations don't match DTO initializers
**Solution**: Fix in Xcode test targets, update mock implementations

### HealthKit Permissions
**Problem**: Simulator doesn't support all HealthKit features
**Solution**: Test on physical device for full HealthKit functionality

### Firebase Configuration
**Problem**: Missing GoogleService-Info.plist
**Solution**: Ensure Firebase config file is properly added to project

## API Integration

### Backend Endpoints
- Authentication: `/auth/*` 
- Health Data: `/health/*`
- Insights: `/insights/*`

### Error Handling
- Use `APIError` enum for structured error handling
- `ViewState<T>` pattern for UI error states
- Network retry logic built into `APIClient`

---

*This is a production health application handling sensitive user data. Always prioritize security, privacy, and HIPAA compliance in all development decisions.*