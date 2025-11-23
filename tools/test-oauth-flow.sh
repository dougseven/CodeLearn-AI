#!/bin/bash

source config/dev-config.sh

echo "🔗 OAuth Login Flow Testing"
echo "==========================="
echo ""

# Create OAuth login URL for localhost
REDIRECT_URI="http://localhost:3000/auth/callback"
LOGIN_URL="https://$COGNITO_DOMAIN/login?client_id=$APP_CLIENT_ID&response_type=code&scope=openid+email+profile&redirect_uri=$REDIRECT_URI"

echo "OAuth Configuration:"
echo "  User Pool ID: $USER_POOL_ID"
echo "  App Client ID: $APP_CLIENT_ID"
echo "  Cognito Domain: $COGNITO_DOMAIN"
echo "  Redirect URI: $REDIRECT_URI"
echo ""

echo "🌐 OAuth Login URL:"
echo "$LOGIN_URL"
echo ""

echo "📋 Testing Instructions:"
echo "1. Copy the URL above and paste it in your browser"
echo "2. Sign in with: test@example.com / TestPassword123!"
echo "3. After successful login, you'll be redirected to localhost:3000"
echo "4. Copy the 'code' parameter from the URL"
echo "5. Use the code to exchange for tokens (see below)"
echo ""

echo "💡 To exchange authorization code for tokens:"
echo "curl -X POST https://$COGNITO_DOMAIN/oauth2/token \\"
echo "  -H \"Content-Type: application/x-www-form-urlencoded\" \\"
echo "  -d \"grant_type=authorization_code&client_id=$APP_CLIENT_ID&code=YOUR_CODE&redirect_uri=$REDIRECT_URI\""
echo ""

echo "📖 Alternative: Use the direct authentication we already tested:"
echo "./tools/test-auth.sh"