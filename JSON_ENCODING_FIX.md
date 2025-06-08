# JSON Encoding Fix for Insight Generation

## Issue
The chat/insights feature was failing because the iOS app was sending JSON with camelCase property names while the backend API expects snake_case property names.

### Example of the mismatch:
- iOS was sending: `{"analysisResults": {...}, "insightType": "chat_response", ...}`
- Backend expects: `{"analysis_results": {...}, "insight_type": "chat_response", ...}`

## Root Cause
The `JSONEncoder` and `JSONDecoder` in `APIClient.swift` were not configured to convert between Swift's camelCase conventions and the API's snake_case conventions.

## Solution
Updated the JSON encoder/decoder configuration in the following files:

### 1. APIClient.swift
Added key encoding/decoding strategies:
```swift
decoder.keyDecodingStrategy = .convertFromSnakeCase
encoder.keyEncodingStrategy = .convertToSnakeCase
```

### 2. OfflineQueueManager.swift
Updated the encoder/decoder instances used for queuing offline requests to use the same snake_case conversion.

## Testing
Created `JSONEncodingTests.swift` to verify that:
- Request DTOs are properly encoded with snake_case keys
- Response DTOs are properly decoded from snake_case keys

## Impact
This fix ensures all API communication uses the correct JSON key format, resolving the insight generation failures and any other potential API mismatches.

## Verification
After this fix:
1. The chat feature should work correctly
2. All API requests will have properly formatted JSON
3. No changes needed to the Swift DTOs - they can remain in idiomatic camelCase

The beauty of this solution is that it maintains Swift naming conventions in the codebase while ensuring API compatibility.