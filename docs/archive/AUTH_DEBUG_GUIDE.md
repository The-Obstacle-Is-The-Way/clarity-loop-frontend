# Authentication Debug Guide

## What We've Done

### 1. Enhanced Logging
- Added comprehensive logging to `AuthService.getCurrentUserToken()` that shows:
  - User existence and UID
  - Email and verification status
  - Token claims including `aud` and `iss` fields
  - Token length and preview

- Enhanced `APIClient` logging to show:
  - Token retrieval process
  - Warning if "test-token-123" is detected
  - Full request headers being sent
  - Authorization header construction

- Enhanced app initialization token provider with detailed logging

### 2. Created Debug Tools
- **TokenDebugView**: A new debug view that:
  - Shows complete token information and claims
  - Displays critical `aud` and `iss` fields for Firebase project verification
  - Tests the backend `/api/v1/debug/auth-check` endpoint
  - Copies token to clipboard for manual testing

- **Enhanced DebugAPIView**: Now includes token display and clipboard functionality

### 3. Added Debug Tab
- The Debug tab in MainTabView now includes a link to TokenDebugView
- Easy access to token information and backend testing

## How to Debug the 401 Issue

### Step 1: Run the App and Check Token Info
1. Build and run the app in Xcode
2. Sign in with a test account
3. Go to the Debug tab
4. Tap "Token Debug Info"
5. Tap "Get Current Token Info"

### Step 2: Verify Firebase Project Configuration
Look for these critical fields in the token info:
```
- aud (audience): Should be "clarity-loop-backend"
- iss (issuer): Should be "https://securetoken.google.com/clarity-loop-backend"
```

**If these don't match "clarity-loop-backend"**, then your iOS app is using a different Firebase project than your backend!

### Step 3: Test Backend Authentication
1. In TokenDebugView, tap "Test Backend Auth Check"
2. This will send your token to the backend's debug endpoint
3. Check the response - it should show why authentication is failing

### Step 4: Manual Token Test
1. The token is automatically copied to clipboard
2. Use the test script:
```bash
# Replace the token with the one from clipboard
TOKEN="paste-your-token-here"
curl -i \
  -H "Authorization: Bearer $TOKEN" \
  https://crave-trinity-prod--clarity-backend-fastapi-app.modal.run/api/v1/debug/auth-check
```

### Step 5: Check Console Logs
Run the app with Xcode console open and look for:
- `🔍 AUTH:` logs from AuthService
- `🔍 APP:` logs from app initialization
- `🚀 APIClient:` logs showing request flow
- `⚠️ WARNING:` if "test-token-123" is detected

## Common Issues to Check

### 1. Wrong Firebase Project
- iOS GoogleService-Info.plist might be from a different project
- Backend might be configured with different Firebase credentials
- Token `aud` and `iss` fields will reveal the mismatch

### 2. Token Not Being Sent
- Check console for "Authorization header set" messages
- Verify token provider is being called
- Ensure user is actually signed in

### 3. Backend Issue
- The backend logs show "test-token-123" which suggests:
  - Either a debug endpoint is being called with a hardcoded test token
  - Or the backend has fallback logic that uses test tokens
  - This needs to be investigated on the backend side

## Next Steps

1. **Run the app** and use TokenDebugView to get the actual token claims
2. **Compare** the `aud` field with what the backend expects
3. **Test manually** with curl using the real token
4. **Check backend code** for any "test-token-123" references or debug fallbacks

The 401 error will be resolved once:
- The iOS app sends tokens from the correct Firebase project
- The backend accepts tokens from that same project
- No test tokens are being used in production calls