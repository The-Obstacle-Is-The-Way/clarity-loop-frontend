# JSON Payload Audit Report - CLARITY Frontend/Backend Mismatch Analysis

## Executive Summary

After thorough analysis of both the iOS frontend and Python backend codebases, I've identified the **root cause** of the 422 validation errors: **JSON key naming convention mismatch**. The iOS app sends JSON with camelCase keys (Swift convention) while the backend expects snake_case keys (Python convention).

## Critical Issue: Snake_Case vs CamelCase

### Problem
- **Frontend (Swift)**: Uses camelCase for all property names (e.g., `userId`, `analysisResults`, `includeRecommendations`)
- **Backend (Python/FastAPI)**: Expects snake_case for all field names (e.g., `user_id`, `analysis_results`, `include_recommendations`)

### Solution Applied
Updated `APIClient.swift` and `OfflineQueueManager.swift` to use:
```swift
encoder.keyEncodingStrategy = .convertToSnakeCase
decoder.keyDecodingStrategy = .convertFromSnakeCase
```

## Detailed Payload Mismatches

### 1. Health Data Upload

**Endpoint**: `POST /api/v1/health-data/upload`

**Frontend Sends** (HealthKitUploadRequestDTO):
```json
{
    "userId": "user-123",
    "samples": [...],
    "deviceInfo": {...},
    "timestamp": "2025-06-08T12:00:00Z"
}
```

**Backend Expects** (HealthDataUpload):
```json
{
    "user_id": "user-123",
    "metrics": [...],  // Note: different field name!
    "upload_source": "apple_health",
    "client_timestamp": "2025-06-08T12:00:00Z",
    "sync_token": null
}
```

**Issues**:
- Field name mismatch: `samples` → `metrics`
- Missing required field: `upload_source`
- Field name mismatch: `timestamp` → `client_timestamp`
- Structure mismatch: Backend `metrics` expects `HealthMetric` objects with specific structure

### 2. Gemini Insights Generation

**Endpoint**: `POST /api/v1/insights/generate`

**Frontend Sends** (InsightGenerationRequestDTO):
```json
{
    "analysisResults": {"sleep_score": 85},
    "context": "User context",
    "insightType": "comprehensive",
    "includeRecommendations": true,
    "language": "en"
}
```

**Backend Expects** (InsightGenerationRequest):
```json
{
    "analysis_results": {"sleep_score": 85},
    "context": "User context",
    "insight_type": "comprehensive",
    "include_recommendations": true,
    "language": "en"
}
```

**Issues**: All field names need snake_case conversion (now fixed with encoding strategy)

### 3. API Contract vs Implementation Discrepancies

The `API_CONTRACT.md` document shows different endpoints than what's actually implemented:

**Contract Says**: `/healthkit/upload`
**Actual Implementation**: `/health-data/upload`

**Contract Structure**:
```json
{
    "user_id": "firebase-user-id-123",
    "quantity_samples": [...],
    "category_samples": [],
    "workouts": [],
    "correlation_samples": []
}
```

**Actual Expected Structure**: Completely different (uses `metrics` array)

## Impact on Features

### 1. Health Data Visualization Not Working
- The dashboard can't display health data because uploads fail with 422 errors
- The `metrics` field structure mismatch prevents data from being accepted

### 2. Gemini Chat Feature Not Working
- Chat messages fail because of camelCase/snake_case mismatch
- The insights generation endpoint rejects requests due to field naming

## Fixes Applied

### 1. APIClient.swift
```swift
private lazy var jsonEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase  // Added
    encoder.dateEncodingStrategy = .iso8601
    return encoder
}()

private lazy var jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase  // Added
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}()
```

### 2. Test Coverage
Created `JSONEncodingTests.swift` to verify proper encoding/decoding

## Remaining Issues to Address

### 1. Health Data Upload Structure
The frontend needs to restructure health data to match backend expectations:
- Convert `samples` array to `metrics` array with proper `HealthMetric` structure
- Add required `upload_source` field
- Ensure proper metric types and data structure

### 2. API Endpoint Alignment
- Frontend uses `/health-data/upload` (correct)
- API contract documentation needs updating to reflect actual implementation

### 3. Backend Compatibility
Consider adding middleware to the backend to accept both camelCase and snake_case for backwards compatibility during transition

## Recommendations

1. **Immediate**: The snake_case encoding fix will resolve most 422 errors
2. **Short-term**: Update health data upload structure to match backend expectations
3. **Medium-term**: Add comprehensive integration tests between frontend and backend
4. **Long-term**: Consider using OpenAPI/Swagger for automatic client generation to prevent future mismatches

## Testing Checklist

- [x] JSON encoding/decoding with snake_case conversion
- [ ] Health data upload with correct metric structure
- [ ] Gemini insights generation
- [ ] Authentication endpoints
- [ ] PAT analysis endpoints
- [ ] Error response handling

## Conclusion

The primary issue causing 422 errors was the JSON key naming convention mismatch. The fix applied to `APIClient.swift` will resolve most issues. However, the health data upload structure still needs adjustment to match the backend's expected `HealthMetric` format rather than the current `HealthKitSampleDTO` format.