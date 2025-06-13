# 🚀 Backend Integration Architecture

## Overview

This frontend uses a **Contract Adapter Pattern** to ensure perfect compatibility with the backend API. The backend is the source of truth for all API contracts.

## Architecture Components

### 1. Backend Contract DTOs (`BackendContract.swift`)
- Exact mirrors of backend Pydantic models
- Snake_case to camelCase mapping
- Type-safe representations of all backend requests/responses

### 2. Contract Adapter (`BackendContractAdapter.swift`)
- Protocol-based adaptation layer
- Bidirectional mapping between frontend and backend DTOs
- Error response adaptation
- Handles all contract mismatches elegantly

### 3. Backend API Client (`BackendAPIClient.swift`)
- Enhanced API client using the contract adapter
- Automatic request/response transformation
- Comprehensive error handling
- Debug logging for development

## Testing Strategy

### Integration Tests (`BackendIntegrationTests.swift`)
- Tests against real backend endpoints
- Validates contract compatibility
- End-to-end authentication flows
- Error handling validation

### E2E Tests with Mock Server (`BackendE2ETests.swift`)
- Complete user journeys without external dependencies
- Mock server that exactly mirrors backend behavior
- Contract conformance validation
- Performance and concurrency testing

### Contract Validation Script
```bash
./Scripts/validate_backend_contract.swift
```
Runs automated validation against backend endpoints to catch contract changes.

## Key Features

### 🔒 Type Safety
- All backend responses are validated at compile time
- Contract mismatches caught during development
- No runtime surprises

### 🔄 Automatic Adaptation
```swift
// Frontend sends rich DTOs
let frontendRequest = UserRegistrationRequestDTO(
    email: "user@example.com",
    password: "password",
    firstName: "John",
    lastName: "Doe",
    phoneNumber: "+1234567890",
    termsAccepted: true,
    privacyPolicyAccepted: true
)

// Adapter converts to backend format automatically
{
    "email": "user@example.com",
    "password": "password",
    "display_name": "John Doe"
}
```

### 🛡️ Error Handling
- Backend errors are automatically adapted to frontend error types
- Problem Details (RFC 7807) support
- Validation error handling
- User-friendly error messages

## Usage

### Development
1. Use `BackendAPIClient` instead of `APIClient`
2. All contract mismatches are handled automatically
3. Check debug logs for request/response details

### Testing
```bash
# Run integration tests
xcodebuild test -scheme clarity-loop-frontend -only-testing:clarity-loop-frontendTests/BackendIntegrationTests

# Run E2E tests
xcodebuild test -scheme clarity-loop-frontend -only-testing:clarity-loop-frontendTests/BackendE2ETests

# Validate backend contract
./Scripts/validate_backend_contract.swift
```

### CI/CD
Add contract validation to your pipeline:
```yaml
- name: Validate Backend Contract
  run: ./Scripts/validate_backend_contract.swift
```

## Benefits

1. **Zero Backend Coupling**: Frontend can evolve independently
2. **Contract Safety**: Compile-time validation of API contracts
3. **Easy Maintenance**: Single place to update when backend changes
4. **Comprehensive Testing**: Integration, E2E, and contract tests
5. **Developer Experience**: Clear error messages and debug logging

## Future Enhancements

1. **OpenAPI Integration**: Generate contracts from backend OpenAPI spec
2. **Contract Versioning**: Support multiple backend versions
3. **Automatic Mocking**: Generate mocks from contract definitions
4. **Performance Monitoring**: Track adapter overhead

## Troubleshooting

### Contract Mismatch Errors
1. Run contract validation script
2. Check backend API documentation
3. Update `BackendContract.swift` with new fields
4. Update adapter mappings if needed

### Authentication Failures
1. Verify Cognito configuration matches backend
2. Check token format in debug logs
3. Ensure backend is running and accessible

### Test Failures
1. Integration tests require backend to be running
2. E2E tests are self-contained (no external deps)
3. Contract tests validate current backend state

---

**Remember**: The backend is the source of truth. When in doubt, check the backend code or run the contract validation script.