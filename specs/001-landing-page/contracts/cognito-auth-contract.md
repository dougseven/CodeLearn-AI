# API Contract: AWS Cognito Authentication

**Feature**: 001-landing-page  
**Version**: 1.0.0  
**Date**: 2025-11-23

## Overview

This contract defines the integration between the landing page and **AWS Cognito OAuth 2.0** for user authentication. The landing page acts as a pure OAuth client with no backend authentication logic.

## Authentication Flow

### Login Flow (Authorization Code Grant)

**Trigger**: User clicks "Login" button (User Story 4)

**Steps**:

1. **Initiate OAuth Flow**
   - Redirect to Cognito hosted UI:
     ```
     https://{cognito-domain}.auth.us-east-1.amazoncognito.com/oauth2/authorize
     ```
   - Query Parameters:
     - `response_type=code`
     - `client_id={app-client-id}`
     - `redirect_uri={landing-page-url}/callback`
     - `scope=openid email profile`
     - `state={random-csrf-token}` (generated client-side, stored in sessionStorage)

2. **User Authentication**
   - User completes Google OAuth consent on Cognito UI
   - Cognito redirects back to: `{landing-page-url}/callback?code={auth-code}&state={csrf-token}`

3. **Token Exchange**
   - Landing page validates `state` matches stored CSRF token
   - JavaScript calls backend `/auth/token` endpoint (future implementation) to exchange `code` for tokens
   - Backend returns:
     ```json
     {
       "access_token": "eyJhbGciOi...",
       "id_token": "eyJhbGciOi...",
       "refresh_token": "eyJhbGciOi...",
       "expires_in": 3600,
       "token_type": "Bearer"
     }
     ```

4. **Session Establishment**
   - Store `access_token`, `id_token`, `expires_in` in `sessionStorage`
   - Calculate `tokenExpiry = Date.now() + (expires_in * 1000)`
   - Redirect to original destination or dashboard

### Logout Flow

**Trigger**: User clicks "Logout" link

**Steps**:

1. **Clear Session**
   - Remove all tokens from `sessionStorage`
   - Set `isAuthenticated = false`

2. **Cognito Logout**
   - Redirect to:
     ```
     https://{cognito-domain}.auth.us-east-1.amazoncognito.com/logout
     ```
   - Query Parameters:
     - `client_id={app-client-id}`
     - `logout_uri={landing-page-url}`

## Token Structure

### ID Token (JWT)

**Purpose**: Contains user identity claims

**Header**:
```json
{
  "alg": "RS256",
  "kid": "abc123xyz..."
}
```

**Payload**:
```json
{
  "sub": "a1b2c3d4-5678-90ef-ghij-klmnopqrstuv",
  "email": "user@example.com",
  "email_verified": true,
  "cognito:username": "google_123456789",
  "iss": "https://cognito-idp.us-east-1.amazonaws.com/{user-pool-id}",
  "aud": "{app-client-id}",
  "token_use": "id",
  "auth_time": 1700000000,
  "exp": 1700003600,
  "iat": 1700000000
}
```

**Validation (Client-Side)**:
- Verify `exp` > current timestamp (token not expired)
- Verify `iss` matches expected Cognito domain
- Verify `aud` matches app client ID

### Access Token (Opaque)

**Purpose**: Authorization for API calls (future use)

**Format**: JWT with minimal claims
**Lifetime**: 1 hour (3600 seconds)
**Usage**: Include in `Authorization: Bearer {access_token}` header for backend API calls

## Error Responses

### OAuth Errors (Query Parameters)

**Invalid State Token**:
```
{landing-page-url}/callback?error=invalid_request&error_description=State+mismatch
```
**Handling**: Clear session, redirect to `/` with error banner: "Authentication failed. Please try again."

**User Cancelled Login**:
```
{landing-page-url}/callback?error=access_denied&error_description=User+cancelled
```
**Handling**: Redirect to `/` with info banner: "Login cancelled."

**Expired Authorization Code**:
```
{landing-page-url}/callback?code={expired-code}&state={valid-state}
```
**Handling**: Backend returns 400 error during token exchange, show error banner: "Session expired. Please log in again."

### Token Exchange Errors (Backend Response)

**Backend API Contract** (for future `/auth/token` endpoint):

**Request**:
```http
POST /auth/token
Content-Type: application/json

{
  "code": "abc123...",
  "redirect_uri": "https://codelearn.ai/callback"
}
```

**Success Response** (200 OK):
```json
{
  "access_token": "eyJhbGciOi...",
  "id_token": "eyJhbGciOi...",
  "expires_in": 3600
}
```

**Error Responses**:

- **400 Bad Request** (invalid/expired code):
  ```json
  {
    "error": "invalid_grant",
    "message": "Authorization code expired or invalid"
  }
  ```

- **401 Unauthorized** (invalid client credentials):
  ```json
  {
    "error": "invalid_client",
    "message": "Client authentication failed"
  }
  ```

- **500 Internal Server Error**:
  ```json
  {
    "error": "server_error",
    "message": "Failed to exchange authorization code"
  }
  ```

## Security Requirements

1. **CSRF Protection**: 
   - Generate cryptographically random `state` parameter (32+ bytes)
   - Verify `state` matches on callback before processing `code`

2. **Token Storage**:
   - Use `sessionStorage` (cleared on tab close)
   - Never use `localStorage` (persists across sessions)
   - Never log tokens to console

3. **HTTPS Only**:
   - All OAuth redirects must use HTTPS
   - Development: Use `localhost` (exempted by OAuth 2.0 spec)

4. **Token Validation**:
   - Check `exp` claim before using ID token
   - Clear session immediately on expired tokens

## Configuration

**Environment Variables** (embedded in HTML or loaded from config):

```javascript
const AUTH_CONFIG = {
  cognitoDomain: "codelearn.auth.us-east-1.amazoncognito.com",
  clientId: "7a8b9c0d1e2f3g4h5i6j7k8l9m",
  redirectUri: window.location.origin + "/callback",
  scopes: ["openid", "email", "profile"],
  region: "us-east-1",
  userPoolId: "us-east-1_Abc123Xyz"
};
```

## Testing Requirements

1. **Happy Path**: User completes login and returns to landing page
2. **State Mismatch**: Attacker modifies `state` parameter → Error banner shown
3. **User Cancels**: User closes Cognito UI → Info banner shown
4. **Token Expiry**: User stays on page for 1+ hour → Auto-logout to anonymous state
5. **Cross-Browser**: Test OAuth flow in Chrome, Safari, Firefox, Edge

## Future Enhancements

- **Silent Refresh**: Use `refresh_token` to extend session without re-login (Phase 2)
- **Remember Me**: Option to use `localStorage` for persistent sessions (Phase 3)
- **MFA Support**: Handle Cognito MFA challenges if enabled (Phase 4)
