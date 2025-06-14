# 🎯 FRONTEND AUTH IMPLEMENTATION TASKS

## Goal: Stop calling Cognito directly. All login must go through our backend.

## ✅ Task Checklist

### 1. Remove/Disable Direct Cognito Calls
- [ ] Comment out or delete `CognitoAuthService.swift`
- [ ] Remove AWS SDK imports from project
- [ ] Delete Cognito configuration from `Info.plist`
- [ ] Remove `CognitoConfiguration.swift`

### 2. Update AuthService Implementation
```swift
// In AuthService.swift, replace the signIn method:
func signIn(email: String, password: String) async throws {
    // Remove this line:
    // let tokens = try await cognitoAuth.signIn(email: email, password: password)
    
    // Use only this:
    let loginResponse = try await apiClient.login(
        email: email,
        password: password,
        rememberMe: false
    )
    
    // Store tokens
    await TokenManager.shared.store(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
        expiresIn: loginResponse.expiresIn
    )
    
    // Update state
    self.currentUser = loginResponse.user
    self.isAuthenticated = true
}
```

### 3. Update APIClient Login Method
```swift
func login(email: String, password: String, rememberMe: Bool) async throws -> LoginResponse {
    let endpoint = "/api/v1/auth/login"
    
    let deviceInfo = DeviceInfoHelper.getCurrentDeviceInfo()
    
    let payload = [
        "email": email,
        "password": password,
        "remember_me": rememberMe,
        "device_info": deviceInfo
    ] as [String: Any]
    
    // Make request and decode response
    let response: LoginResponse = try await request(
        endpoint: endpoint,
        method: .post,
        body: payload
    )
    
    return response
}
```

### 4. Add Authorization Header Interceptor
```swift
// In APIClient, update the request builder to include auth token:
private func addAuthorizationHeader(to request: inout URLRequest) async {
    if let token = await TokenManager.shared.getAccessToken() {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}
```

### 5. Implement Token Refresh
```swift
// Add to AuthService:
func refreshTokenIfNeeded() async throws {
    let expiresIn = await TokenManager.shared.getTokenExpiryTime()
    
    if expiresIn <= 60 { // Less than 60 seconds remaining
        guard let refreshToken = await TokenManager.shared.getRefreshToken() else {
            throw AuthError.notAuthenticated
        }
        
        let response = try await apiClient.refreshToken(refreshToken: refreshToken)
        
        await TokenManager.shared.store(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn
        )
    }
}
```

### 6. Clean Up Info.plist
Remove these keys:
```xml
<!-- DELETE THESE -->
<key>CognitoUserPoolId</key>
<string>us-east-1_efXaR5EcP</string>
<key>CognitoClientId</key>
<string>7sm7ckrkovg78b03n1595euc71</string>
<key>CognitoRegion</key>
<string>us-east-1</string>
```

### 7. Update Response Models
```swift
struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: User?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}
```

### 8. Update Unit Tests
```swift
func testBackendLogin() async throws {
    // Mock the backend response, not Cognito
    let mockResponse = LoginResponse(
        accessToken: "mock_access_token",
        refreshToken: "mock_refresh_token",
        expiresIn: 3600,
        user: User(id: "123", email: "test@example.com")
    )
    
    // Test login through APIClient
    mockAPIClient.loginResponse = mockResponse
    
    try await authService.signIn(email: "test@example.com", password: "password")
    
    XCTAssertTrue(authService.isAuthenticated)
    XCTAssertNotNil(authService.currentUser)
}
```

## 🧪 Test Plan

1. **Manual Testing**
   - Build and run the app
   - Enter valid credentials
   - Verify login succeeds
   - Check network tab to confirm requests go to backend, not Cognito
   - Verify Bearer token is sent with subsequent API calls

2. **Automated Testing**
   - All auth unit tests pass
   - Integration tests work with mock backend responses
   - No references to Cognito in test code

## ⚠️ Common Pitfalls to Avoid

1. **Don't forget to remove ALL Cognito imports**
   ```swift
   // DELETE THESE:
   import AWSCognitoIdentityProvider
   import AWSCore
   ```

2. **Ensure APIClient base URL is correct**
   ```swift
   // Should be your backend, not Cognito:
   let baseURL = "http://clarity-alb-1762715656.us-east-1.elb.amazonaws.com"
   ```

3. **Handle token expiry properly**
   - Check before each API call
   - Refresh proactively (not reactively)

## 📋 Definition of Done

- [ ] Zero direct Cognito calls in codebase
- [ ] Login works through `/api/v1/auth/login` only
- [ ] Tokens stored securely in Keychain
- [ ] Authorization header on all API requests
- [ ] Silent token refresh working
- [ ] No AWS/Cognito secrets in app bundle
- [ ] All tests updated and passing
- [ ] Successfully tested on device

## 🚀 Quick Test Command

After implementation, test with:
```bash
# From terminal, verify backend is working:
curl -X POST "http://clarity-alb-1762715656.us-east-1.elb.amazonaws.com/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Passw0rd!",
    "remember_me": false,
    "device_info": {
      "device_id": "test-123",
      "platform": "iOS",
      "os_version": "18.0",
      "app_version": "1.0.0",
      "model": "iPhone",
      "name": "Test Device"
    }
  }'
```

If this returns tokens, your backend is ready!

---

**Remember: The backend already handles all Cognito complexity. We just need to use it!** 🎯