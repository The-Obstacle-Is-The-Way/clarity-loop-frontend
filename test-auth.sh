#!/bin/bash

# Test script for CLARITY AWS Production Backend
# Region: us-east-1 (Virginia)
# All endpoints unified in us-east-1

TOKEN="YOUR_TOKEN_HERE"
API_BASE="http://clarity-alb-1762715656.us-east-1.elb.amazonaws.com"

echo "🚀 TESTING CLARITY AWS BACKEND (us-east-1)"
echo "==========================================="

echo "1. Testing /health endpoint (no auth)..."
curl -s -X GET "$API_BASE/health" | jq . || curl -s -X GET "$API_BASE/health"
echo -e "\n"

echo "2. Testing /api/v1/ endpoint (no auth)..."
curl -s -X GET "$API_BASE/api/v1/" | jq . || curl -s -X GET "$API_BASE/api/v1/"
echo -e "\n"

echo "3. Testing /api/v1/auth/health (no auth)..."
curl -s -X GET "$API_BASE/api/v1/auth/health" | jq . || curl -s -X GET "$API_BASE/api/v1/auth/health"
echo -e "\n"

echo "4. Testing insights status (no auth)..."
curl -s -X GET "$API_BASE/api/v1/insights/status" | jq . || curl -s -X GET "$API_BASE/api/v1/insights/status"
echo -e "\n"

echo "5. Testing generate insight (AUTH REQUIRED)..."
if [ "$TOKEN" != "YOUR_TOKEN_HERE" ]; then
    curl -X POST "$API_BASE/api/v1/insights/generate" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "analysis_results": {"test": "data"},
        "context": "Test from production backend",
        "insight_type": "chat_response",
        "include_recommendations": false,
        "language": "en"
      }' | jq . || echo "Request sent (check for JSON response)"
else
    echo "⚠️  Set TOKEN variable to test authenticated endpoints"
fi
echo -e "\n"

echo "✅ AWS us-east-1 Backend Test Complete!"
echo "Backend: $API_BASE"
echo "Cognito: us-east-1_1G5jYI8FO"