#!/bin/bash

source config/dev-config.sh

echo "🧪 Testing Google OAuth Configuration"
echo "===================================="
echo ""

echo "📋 Configuration Summary:"
echo "   User Pool ID: $USER_POOL_ID"
echo "   App Client ID: $APP_CLIENT_ID"
echo "   Cognito Domain: $COGNITO_DOMAIN"
echo "   CloudFront URL: $FRONTEND_HTTPS_URL"
echo ""

echo "🔍 Step 1: Verifying Google Identity Provider..."

# Check Google identity provider
GOOGLE_IDP=$(aws cognito-idp describe-identity-provider \
    --user-pool-id "$USER_POOL_ID" \
    --provider-name "Google" \
    --query 'IdentityProvider.{ProviderName:ProviderName,ProviderType:ProviderType,AttributeMapping:AttributeMapping}' \
    --output json 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✅ Google Identity Provider is configured"
    echo "   Provider Details: $(echo "$GOOGLE_IDP" | jq -r '.ProviderName + " (" + .ProviderType + ")"')"
else
    echo "❌ Google Identity Provider not found"
    exit 1
fi

echo ""
echo "🔍 Step 2: Verifying App Client Configuration..."

# Check app client supports Google
SUPPORTED_PROVIDERS=$(aws cognito-idp describe-user-pool-client \
    --user-pool-id "$USER_POOL_ID" \
    --client-id "$APP_CLIENT_ID" \
    --query 'UserPoolClient.SupportedIdentityProviders[]' \
    --output text)

if echo "$SUPPORTED_PROVIDERS" | grep -q "Google"; then
    echo "✅ App Client supports Google authentication"
    echo "   Supported Providers: $SUPPORTED_PROVIDERS"
else
    echo "❌ App Client does not support Google authentication"
    echo "   Current Providers: $SUPPORTED_PROVIDERS"
    exit 1
fi

echo ""
echo "🔍 Step 3: Testing OAuth Endpoints..."

# Test Cognito domain
DOMAIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$COGNITO_DOMAIN/.well-known/jwks.json")
if [ "$DOMAIN_STATUS" = "200" ]; then
    echo "✅ Cognito domain is accessible"
else
    echo "⚠️  Cognito domain returned HTTP $DOMAIN_STATUS"
fi

# Test OAuth login endpoint
LOGIN_URL="https://$COGNITO_DOMAIN/login?client_id=$APP_CLIENT_ID&response_type=code&scope=openid+email+profile&redirect_uri=https://d26aeuhfo3vnoz.cloudfront.net"
LOGIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$LOGIN_URL")
if [ "$LOGIN_STATUS" = "200" ]; then
    echo "✅ OAuth login endpoint is accessible"
else
    echo "⚠️  OAuth login endpoint returned HTTP $LOGIN_STATUS"
fi

# Test Google OAuth endpoint  
GOOGLE_URL="https://$COGNITO_DOMAIN/oauth2/authorize?client_id=$APP_CLIENT_ID&response_type=code&scope=openid+email+profile&redirect_uri=https://d26aeuhfo3vnoz.cloudfront.net&identity_provider=Google"
GOOGLE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$GOOGLE_URL")
if [ "$GOOGLE_STATUS" = "302" ] || [ "$GOOGLE_STATUS" = "200" ]; then
    echo "✅ Google OAuth endpoint is working (HTTP $GOOGLE_STATUS)"
else
    echo "⚠️  Google OAuth endpoint returned HTTP $GOOGLE_STATUS"
fi

echo ""
echo "🔍 Step 4: Testing Frontend Deployment..."

FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_HTTPS_URL")
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo "✅ Frontend is accessible via CloudFront"
else
    echo "❌ Frontend returned HTTP $FRONTEND_STATUS"
fi

# Check if frontend has Google authentication
FRONTEND_CONTENT=$(curl -s "$FRONTEND_HTTPS_URL")
if echo "$FRONTEND_CONTENT" | grep -q "loginWithGoogle"; then
    echo "✅ Frontend includes Google authentication code"
else
    echo "⚠️  Frontend may not include Google authentication code"
fi

echo ""
echo "🎉 Google OAuth Test Results"
echo "============================"
echo ""
echo "📋 URLs for Testing:"
echo "   Frontend: $FRONTEND_HTTPS_URL"
if [[ -n "$FRONTEND_CUSTOM_URL" ]]; then
    echo "   Custom Domain: $FRONTEND_CUSTOM_URL"
fi
echo ""
echo "   Cognito Login: $LOGIN_URL"
echo ""
echo "   Google Direct: $GOOGLE_URL"
echo ""
echo "🔄 Manual Testing Steps:"
echo "1. Visit: $FRONTEND_HTTPS_URL"
echo "2. Click 'Get Started'"
echo "3. You should see both 'Continue with Google' and 'Continue with Email' options"
echo "4. Try 'Continue with Google' - it should redirect to Google OAuth"
echo "5. After Google sign-in, you should be redirected back to your app"
echo ""
echo "📱 Google Console Configuration Required:"
echo "   URL: https://console.cloud.google.com/apis/credentials"
echo "   Client ID: 737420187518-s5nouucdui8koghqv1roqbkjlethhpnj.apps.googleusercontent.com"
echo ""
echo "   Required Authorized Redirect URIs:"
echo "   - https://$COGNITO_DOMAIN/oauth2/idpresponse"
echo ""
echo "   Required Authorized Origins:"
echo "   - https://d26aeuhfo3vnoz.cloudfront.net"
if [[ -n "$FRONTEND_CUSTOM_URL" ]]; then
    echo "   - $FRONTEND_CUSTOM_URL"
fi