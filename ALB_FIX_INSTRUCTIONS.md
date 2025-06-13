# 🚨 ALB ROUTING FIX INSTRUCTIONS

## The Problem
Your ALB is routing `/api/v1/auth/login` directly to AWS Cognito instead of to your FastAPI backend.

## Quick Fix Steps

1. **Open AWS Console**
   - Go to EC2 → Load Balancers
   - Find `clarity-alb-1762715656`

2. **Check Listener Rules**
   - Click on the ALB
   - Go to "Listeners" tab
   - Click "View/edit rules" on your HTTP/HTTPS listener

3. **Find the Problematic Rule**
   Look for a rule that matches:
   - Path: `/api/*` or `/api/v1/auth/*` or `/api/v1/auth/login`
   - Action: `Authenticate with Cognito` ❌ (THIS IS THE PROBLEM)

4. **Fix the Rule**
   Change it to:
   - Path: `/api/*` 
   - Action: `Forward to` → Your FastAPI target group ✅

5. **Rule Structure Should Be:**
   ```
   IF Path is /api/*
   THEN Forward to → fastapi-target-group
   
   IF Path is /* (catch all)
   THEN Authenticate with Cognito (optional) → Forward to → web-ui-target-group
   ```

## Why This Happened
- Cognito authentication on ALB is meant for web UIs, not API endpoints
- Your FastAPI backend handles its own authentication
- The ALB shouldn't do Cognito auth for API paths

## Verification
After fixing:
```bash
# Test directly from terminal
curl -X POST http://clarity-alb-1762715656.us-east-1.elb.amazonaws.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!","remember_me":true}'
```

Should return a FastAPI response (either success or a proper API error), NOT the Cognito "server did not understand" error.