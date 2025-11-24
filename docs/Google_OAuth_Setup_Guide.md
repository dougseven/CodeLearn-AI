# Google OAuth Setup Guide

## Overview

This guide covers how to enable Google authentication in your CodeLearn application using AWS Cognito and Google Cloud Console. Users will be able to sign in using their Google accounts seamlessly.

## Architecture

```
User clicks "Continue with Google"
    ↓
Frontend redirects to Cognito with identity_provider=Google
    ↓
Cognito redirects to Google OAuth
    ↓
User authenticates with Google
    ↓
Google redirects back to Cognito
    ↓
Cognito processes user info and redirects to your app
    ↓
User is logged into CodeLearn
```

## Prerequisites

- AWS Cognito User Pool and App Client already configured
- Google Cloud Platform account with OAuth client credentials
- CloudFront or HTTPS domain for your frontend

## Step 1: Google Cloud Console Setup

### 1.1 Create OAuth 2.0 Client

1. Visit [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Select your project or create a new one
3. Navigate to "Credentials" → "Create Credentials" → "OAuth client ID"
4. Choose "Web application"
5. Configure the client:

```
Application type: Web application
Name: CodeLearn OAuth Client

Authorized JavaScript origins:
- https://d26aeuhfo3vnoz.cloudfront.net
- https://codelearn.dougseven.com (if using custom domain)

Authorized redirect URIs:
- https://codelearn-224157924354.auth.us-east-1.amazoncognito.com/oauth2/idpresponse
```

### 1.2 Note Your Credentials

After creation, note down:
- **Client ID**: `YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com`
- **Client Secret**: `YOUR_GOOGLE_CLIENT_SECRET`

## Step 2: Configure Cognito Identity Provider

### 2.1 Create Google Identity Provider

```bash
aws cognito-idp create-identity-provider \
    --user-pool-id "us-east-1_UoB26Bz23" \
    --provider-name "Google" \
    --provider-type "Google" \
    --provider-details \
        client_id="$GOOGLE_CLIENT_ID",client_secret="$GOOGLE_CLIENT_SECRET",authorize_scopes="openid email profile" \
    --attribute-mapping \
        email=email,given_name=given_name,family_name=family_name,picture=picture,username=sub
```

### 2.2 Update App Client

```bash
aws cognito-idp update-user-pool-client \
    --user-pool-id "us-east-1_UoB26Bz23" \
    --client-id "5d79u7rce8b9ks156lgemd9rd7" \
    --supported-identity-providers "COGNITO" "Google" \
    --callback-urls \
        "https://d26aeuhfo3vnoz.cloudfront.net" \
        "https://d26aeuhfo3vnoz.cloudfront.net/auth/callback" \
        "https://codelearn.dougseven.com" \
        "https://codelearn.dougseven.com/auth/callback" \
        "http://localhost:3000/auth/callback" \
    --logout-urls \
        "https://d26aeuhfo3vnoz.cloudfront.net" \
        "https://codelearn.dougseven.com" \
        "http://localhost:3000" \
    --allowed-o-auth-flows "code" \
    --allowed-o-auth-scopes "openid" "email" "profile" \
    --allowed-o-auth-flows-user-pool-client
```

## Step 3: Frontend Integration

### 3.1 OAuth URL Configuration

The frontend creates two types of OAuth URLs:

**Standard Cognito Login (shows provider selection):**
```javascript
const authUrl = `https://${COGNITO_DOMAIN}/login?` +
    `client_id=${CLIENT_ID}&` +
    `response_type=code&` +
    `scope=openid+email+profile&` +
    `redirect_uri=${encodeURIComponent(REDIRECT_URI)}`;
```

**Direct Google OAuth:**
```javascript
const authUrl = `https://${COGNITO_DOMAIN}/oauth2/authorize?` +
    `client_id=${CLIENT_ID}&` +
    `response_type=code&` +
    `scope=openid+email+profile&` +
    `redirect_uri=${encodeURIComponent(REDIRECT_URI)}&` +
    `identity_provider=Google`;
```

### 3.2 Enhanced Login UI

The frontend now shows both authentication options:

```html
<!-- Google Sign In -->
<button class="btn" onclick="loginWithGoogle()" style="background: #4285f4;">
    <svg><!-- Google icon --></svg>
    Continue with Google
</button>

<!-- Cognito Sign In -->
<button class="btn" onclick="loginWithCognito()" style="background: #ff9500;">
    📧 Continue with Email
</button>
```

### 3.3 Authentication Flow

```javascript
function loginWithGoogle() {
    const authUrl = `https://${COGNITO_DOMAIN}/oauth2/authorize?` +
        `client_id=${CLIENT_ID}&` +
        `response_type=code&` +
        `scope=openid+email+profile&` +
        `redirect_uri=${encodeURIComponent(REDIRECT_URI)}&` +
        `identity_provider=Google`;
    
    window.location.href = authUrl;
}

// Handle OAuth callback (works for both Google and Cognito)
async function handleOAuthCallback(code) {
    const tokenUrl = `https://${COGNITO_DOMAIN}/oauth2/token`;
    
    const response = await fetch(tokenUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
            grant_type: 'authorization_code',
            client_id: CLIENT_ID,
            code: code,
            redirect_uri: REDIRECT_URI
        })
    });
    
    if (response.ok) {
        const tokens = await response.json();
        localStorage.setItem('accessToken', tokens.access_token);
        localStorage.setItem('idToken', tokens.id_token);
        
        // User is now authenticated
        showClassroom();
        loadLesson();
    }
}
```

## Step 4: User Attribute Mapping

Google user information is mapped to Cognito attributes:

| Google Attribute | Cognito Attribute | Description |
|------------------|-------------------|-------------|
| `sub` | `username` | Unique Google user ID |
| `email` | `email` | User's email address |
| `given_name` | `given_name` | First name |
| `family_name` | `family_name` | Last name |
| `picture` | `picture` | Profile picture URL |

## Step 5: Testing and Validation

### 5.1 Automated Testing

Run the provided test script:

```bash
./tools/test-google-oauth.sh
```

Expected output:
```
✅ Google Identity Provider is configured
✅ App Client supports Google authentication  
✅ OAuth login endpoint is accessible
✅ Google OAuth endpoint is working
✅ Frontend is accessible via CloudFront
✅ Frontend includes Google authentication code
```

### 5.2 Manual Testing

1. **Visit your application:**
   - Primary: https://d26aeuhfo3vnoz.cloudfront.net
   - Custom domain: https://codelearn.dougseven.com

2. **Test the flow:**
   - Click "Get Started"
   - You should see both "Continue with Google" and "Continue with Email"
   - Click "Continue with Google"
   - Complete Google authentication
   - Verify you're redirected back to the app and logged in

### 5.3 Test URLs

**Cognito Hosted UI:**
```
https://codelearn-224157924354.auth.us-east-1.amazoncognito.com/login?client_id=5d79u7rce8b9ks156lgemd9rd7&response_type=code&scope=openid+email+profile&redirect_uri=https://d26aeuhfo3vnoz.cloudfront.net
```

**Direct Google OAuth:**
```
https://codelearn-224157924354.auth.us-east-1.amazoncognito.com/oauth2/authorize?client_id=5d79u7rce8b9ks156lgemd9rd7&response_type=code&scope=openid+email+profile&redirect_uri=https://d26aeuhfo3vnoz.cloudfront.net&identity_provider=Google
```

## Step 6: User Management

### 6.1 User Creation

When a user signs in with Google for the first time:
- Cognito automatically creates a new user
- Username is set to the Google `sub` value
- User attributes are populated from Google profile
- User appears in the Cognito User Pool

### 6.2 Viewing Users

```bash
aws cognito-idp list-users --user-pool-id "us-east-1_UoB26Bz23"
```

### 6.3 User Attributes

Google users will have attributes like:
```json
{
    "Username": "Google_117284567890123456789",
    "Attributes": [
        {"Name": "email", "Value": "user@gmail.com"},
        {"Name": "given_name", "Value": "John"},
        {"Name": "family_name", "Value": "Doe"},
        {"Name": "picture", "Value": "https://lh3.googleusercontent.com/..."}
    ],
    "UserStatus": "EXTERNAL_PROVIDER"
}
```

## Troubleshooting

### Common Issues

#### 1. Redirect URI Mismatch

**Error:** `redirect_uri_mismatch`

**Solution:** Ensure Google Console has exact redirect URI:
```
https://codelearn-224157924354.auth.us-east-1.amazoncognito.com/oauth2/idpresponse
```

#### 2. Origin Not Allowed

**Error:** Origin not allowed by Access-Control-Allow-Origin

**Solution:** Add your domain to Google Console Authorized JavaScript origins:
```
https://d26aeuhfo3vnoz.cloudfront.net
https://codelearn.dougseven.com
```

#### 3. Provider Not Configured

**Error:** Identity provider not found

**Solution:** Verify Google provider exists:
```bash
aws cognito-idp describe-identity-provider \
    --user-pool-id "us-east-1_UoB26Bz23" \
    --provider-name "Google"
```

#### 4. App Client Not Updated

**Error:** Client doesn't support Google

**Solution:** Check supported identity providers:
```bash
aws cognito-idp describe-user-pool-client \
    --user-pool-id "us-east-1_UoB26Bz23" \
    --client-id "5d79u7rce8b9ks156lgemd9rd7" \
    --query 'UserPoolClient.SupportedIdentityProviders'
```

### Debug Steps

1. **Check browser console** for JavaScript errors
2. **Verify network requests** in browser DevTools
3. **Test OAuth URLs directly** in browser
4. **Check Cognito logs** in CloudWatch
5. **Validate Google Console configuration**

## Security Considerations

### 1. Scope Limitation

Only request necessary Google scopes:
```
openid email profile
```

### 2. Token Security

- Store tokens securely (localStorage for demo, secure httpOnly cookies for production)
- Implement token refresh logic
- Use HTTPS everywhere

### 3. User Data

- Google profile data is cached in Cognito
- Users can update their Google profile independently
- Implement data synchronization if needed

### 4. Rate Limiting

- Google has OAuth rate limits
- Cognito has built-in protection
- Monitor usage in both consoles

## Monitoring and Analytics

### 1. Cognito Metrics

Monitor in CloudWatch:
- Sign-in success/failure rates
- User pool growth
- Token usage

### 2. Google Analytics

Track in Google Console:
- OAuth request volume
- Error rates
- Geographic distribution

### 3. Application Metrics

Log in your application:
- Authentication method preferences
- User conversion rates
- Session lengths

## Cost Impact

### Google Cloud Platform

- OAuth requests: **Free** (within generous limits)
- No additional costs for basic authentication

### AWS Cognito

- Monthly Active Users (MAU) pricing applies
- Google users count as MAU
- External provider users have same pricing

### Estimated Costs

For typical usage (< 1000 MAU):
- **Google OAuth**: Free
- **Cognito with Google**: ~$5/month
- **Total additional cost**: $0 (Google OAuth is free)

## Conclusion

Google OAuth integration provides:

✅ **Seamless user experience** - one-click sign-in  
✅ **Reduced friction** - no password creation needed  
✅ **Trusted authentication** - users trust Google  
✅ **Auto-populated profiles** - name and email from Google  
✅ **Mobile-friendly** - works great on mobile devices  
✅ **Enterprise ready** - supports Google Workspace accounts  

The integration is production-ready and provides a professional authentication experience for your CodeLearn application.

## Scripts Reference

All setup and testing is automated with these scripts:

- `./tools/setup-google-oauth.sh` - Configure Google OAuth in Cognito
- `./tools/test-google-oauth.sh` - Test OAuth configuration  
- `./tools/verify-google-console-config.sh` - Guide for Google Console setup
- `./tools/e2e-test.sh` - End-to-end platform testing

These scripts ensure reliable, repeatable setup and provide comprehensive validation of the Google OAuth implementation.