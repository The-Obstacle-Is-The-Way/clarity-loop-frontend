#!/bin/bash

# Test script for CLARITY API authentication
# You need to get a valid Firebase ID token first

# Step 1: Run the app and use the Debug tab to get your token
# Step 2: Replace YOUR_TOKEN_HERE with the actual token

TOKEN="YOUR_TOKEN_HERE"
BASE_URL="http://clarity-alb-1762715656.us-east-1.elb.amazonaws.com"

echo "Testing health endpoint (no auth required)..."
curl -X GET "$BASE_URL/api/v1/health-data/health"
echo -e "\n"

echo "Testing insights status (no auth required)..."
curl -X GET "$BASE_URL/api/v1/insights/status"
echo -e "\n"

echo "Testing generate insight (auth required)..."
curl -X POST "$BASE_URL/api/v1/insights/generate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "analysis_results": {"test": "data"},
    "context": "Test from curl",
    "insight_type": "chat_response",
    "include_recommendations": false,
    "language": "en"
  }'
echo -e "\n"