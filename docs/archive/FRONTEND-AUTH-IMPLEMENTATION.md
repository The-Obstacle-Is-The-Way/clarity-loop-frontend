# 🎯 FRONTEND AUTH IMPLEMENTATION GUIDE

## Goal: Stop calling Cognito directly. All login must go through our backend.

## ✅ TASKS CHECKLIST

### 1. Remove Direct Cognito Calls
```swift
// In AuthService.swift, REMOVE/COMMENT OUT:
// _ = try await cognitoAuth.signIn(email: email, password: password)
```

### 2. Update AuthService Sign-In Logic
```swift
func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO {
    // Create login request
    let loginRequest = UserLoginRequestDTO(
        email: email,
        password: password,
        rememberMe: true,
        deviceInfo: DeviceInfoHelper.generateMinimalDeviceInfo()
    )
    
    // Call backend API
    let response = try await apiClient.login(requestDTO: loginRequest)
    
    // Store tokens in Keychain
    try await KeychainService.shared.store(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn
    )
    
    return response.user
}
```

### 3. Token Storage Implementation
```swift
// KeychainService.swift
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let accessTokenKey = "com.clarity.accessToken"
    private let refreshTokenKey = "com.clarity.refreshToken"
    private let tokenExpiryKey = "com.clarity.tokenExpiry"
    
    func store(accessToken: String, refreshToken: String, expiresIn: Int) throws {
        // Store access token
        try storeString(accessToken, for: accessTokenKey)
        
        // Store refresh token
        try storeString(refreshToken, for: refreshTokenKey)
        
        // Calculate and store expiry
        let expiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        try storeDate(expiryDate, for: tokenExpiryKey)
    }
    
    func getAccessToken() -> String? {
        return getString(for: accessTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return getString(for: refreshTokenKey)
    }
    
    func isTokenExpired() -> Bool {
        guard let expiryDate = getDate(for: tokenExpiryKey) else { return true }
        return Date() >= expiryDate.addingTimeInterval(-60) // 60s buffer
    }
}
```

### 4. Update APIClient with Auth Interceptor
```swift
// In APIClient.swift
private func performRequest<T: Decodable>(
    for endpoint: Endpoint,
    requiresAuth: Bool = true
) async throws -> T {
    var request = try endpoint.asURLRequest(baseURL: baseURL, encoder: encoder)
    
    if requiresAuth {
        // Check if token needs refresh
        if KeychainService.shared.isTokenExpired() {
            try await refreshTokenIfNeeded()
        }
        
        // Add auth header
        if let accessToken = KeychainService.shared.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            throw APIError.unauthorized
        }
    }
    
    // ... rest of request handling
}

private func refreshTokenIfNeeded() async throws {
    guard let refreshToken = KeychainService.shared.getRefreshToken() else {
        throw APIError.unauthorized
    }
    
    let refreshRequest = RefreshTokenRequestDTO(refreshToken: refreshToken)
    let response: TokenResponseDTO = try await performRequest(
        for: AuthEndpoint.refreshToken(dto: refreshRequest),
        requiresAuth: false
    )
    
    // Store new tokens
    try await KeychainService.shared.store(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn
    )
}
```

### 5. Clean Up Cognito Config
```swift
// DELETE from Info.plist:
// - CognitoUserPoolId
// - CognitoClientId
// - CognitoRegion
// - Any AWS/Cognito related keys

// DELETE or comment out:
// - CognitoConfiguration.swift
// - CognitoAuthService.swift (or mark as deprecated)
```

### 6. Update Unit Tests
```swift
// AuthServiceTests.swift
func testSignInSuccess() async throws {
    // Mock API response
    let mockResponse = LoginResponseDTO(
        user: UserSessionResponseDTO(/* ... */),
        accessToken: "mock-access-token",
        refreshToken: "mock-refresh-token",
        tokenType: "Bearer",
        expiresIn: 3600,
        scope: "openid email profile"
    )
    
    mockAPIClient.loginResponse = mockResponse
    
    // Test sign in
    let user = try await authService.signIn(
        withEmail: "test@example.com",
        password: "password123"
    )
    
    // Verify tokens stored
    XCTAssertNotNil(KeychainService.shared.getAccessToken())
    XCTAssertNotNil(KeychainService.shared.getRefreshToken())
}
```

## 📋 TESTING PLAN

1. **Remove all Cognito imports**
   ```bash
   # Search for any remaining Cognito references
   grep -r "Cognito\|AWS" --include="*.swift" .
   ```

2. **Test login flow**
   - Enter valid credentials
   - Verify request goes to `/api/v1/auth/login`
   - Check tokens are stored in Keychain
   - Verify subsequent API calls include Bearer token

3. **Test token refresh**
   - Wait for token to near expiry
   - Make an API call
   - Verify automatic refresh happens
   - Check new tokens are stored

## ✅ DEFINITION OF DONE

- [ ] No direct Cognito calls in codebase
- [ ] Login uses `/api/v1/auth/login` exclusively
- [ ] Tokens stored securely in Keychain
- [ ] Auto-refresh works before expiry
- [ ] All API calls include Bearer token
- [ ] Unit tests pass with backend mocks
- [ ] No AWS/Cognito config in Info.plist

---

**FRONTEND IS READY TO IMPLEMENT! 🚀**