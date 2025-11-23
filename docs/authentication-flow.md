# Authentication Flow

## Overview

CodeLearn uses AWS Cognito for authentication with support for:
- Email/Password (Cognito native)
- Google OAuth
- Facebook OAuth (can be added)
- Apple OAuth (can be added)
- Microsoft OAuth (can be added)

## Configuration

**User Pool ID:** `<from config>`  
**App Client ID:** `<from config>`  
**Cognito Domain:** `<from config>`  
**Callback URL:** `<frontend URL>`

## Authentication Flow

### 1. User Initiates Login

Frontend redirects to Cognito hosted UI:
```
https://<cognito-domain>/oauth2/authorize?
  client_id=<app-client-id>&
  response_type=code&
  scope=openid+email+profile&
  redirect_uri=<callback-url>&
  identity_provider=Google  // or COGNITO for email/password
```

### 2. User Authenticates

- **Google OAuth:** User signs in with Google account
- **Email/Password:** User enters credentials in Cognito UI

### 3. Cognito Redirects Back

Cognito redirects to your callback URL with authorization code:
```
https://your-frontend.com/callback?code=<auth-code>
```

### 4. Exchange Code for Tokens

Frontend exchanges code for JWT tokens:
```bash
POST https://<cognito-domain>/oauth2/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&
client_id=<app-client-id>&
code=<auth-code>&
redirect_uri=<callback-url>
```

Response:
```json
{
  "id_token": "<jwt-token>",
  "access_token": "<access-token>",
  "refresh_token": "<refresh-token>",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

### 5. Create Application Session

Frontend calls AuthLambda with ID token to create app session:
```bash
POST /api/auth/callback
Authorization: Bearer <id-token>
```

Response:
```json
{
  "sessionId": "session-id",
  "token": "session-token",
  "userId": "user-uuid",
  "email": "user@example.com",
  "name": "User Name"
}
```

### 6. Use Session Token

Frontend includes session token in all API calls:
```bash
POST /api/lesson
Authorization: Bearer <session-token>
```

## Token Lifetimes

- **ID Token:** 1 hour
- **Access Token:** 1 hour  
- **Refresh Token:** 30 days
- **Session Token:** 24 hours

## Testing Authentication

### Test with CLI:
```bash
./tools/test-auth.sh
```

### Test with Hosted UI:
```
https://<cognito-domain>/login?
  client_id=<app-client-id>&
  response_type=code&
  scope=openid+email+profile&
  redirect_uri=<callback-url>
```

## Adding More OAuth Providers

### Facebook
1. Create Facebook App at developers.facebook.com
2. Get App ID and App Secret
3. Add identity provider:
```bash
aws cognito-idp create-identity-provider \
    --user-pool-id $USER_POOL_ID \
    --provider-name Facebook \
    --provider-type Facebook \
    --provider-details client_id=<app-id>,client_secret=<app-secret>,authorize_scopes="public_profile,email"
```

### Apple
1. Create Apple Service ID
2. Configure redirect URIs
3. Add identity provider with OIDC

## Security Notes

- Always use HTTPS for callbacks
- Store tokens securely (httpOnly cookies recommended)
- Refresh tokens before expiry
- Implement proper logout (clear tokens + Cognito signout)

## Troubleshooting

**"Invalid redirect URI"**
- Check callback URLs in App Client settings
- Must be exact match (including http/https)

**"User does not exist"**
- User must sign up first
- Or use admin-create-user for testing

**"Invalid client"**
- Check App Client ID is correct
- Check User Pool ID is correct