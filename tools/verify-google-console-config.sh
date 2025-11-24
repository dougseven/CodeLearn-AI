#!/bin/bash

source config/dev-config.sh

echo "🔧 Google Cloud Console Configuration Guide"
echo "==========================================="
echo ""

# Get from environment or config file
: ${GOOGLE_CLIENT_ID:?Error: GOOGLE_CLIENT_ID environment variable not set}
GOOGLE_CONSOLE_URL="https://console.cloud.google.com/apis/credentials"

echo "📱 Google OAuth Client Configuration"
echo "-----------------------------------"
echo ""
echo "🔗 Google Console URL:"
echo "   $GOOGLE_CONSOLE_URL"
echo ""
echo "📋 Required Configuration:"
echo ""
echo "1. **Client ID**: $GOOGLE_CLIENT_ID"
echo "   ✅ Already configured in your project"
echo ""
echo "2. **Authorized redirect URIs** (CRITICAL):"
echo "   ✅ https://$COGNITO_DOMAIN/oauth2/idpresponse"
echo ""
echo "3. **Authorized JavaScript origins**:"
echo "   ✅ https://d26aeuhfo3vnoz.cloudfront.net"
if [[ -n "$FRONTEND_CUSTOM_URL" ]]; then
    echo "   ✅ $FRONTEND_CUSTOM_URL"
fi
echo ""

echo "🛠️  Step-by-Step Configuration:"
echo "1. Visit: $GOOGLE_CONSOLE_URL"
echo "2. Click 'Edit' or navigate to your OAuth client"
echo "3. In 'Authorized redirect URIs' section, ensure you have:"
echo "   https://$COGNITO_DOMAIN/oauth2/idpresponse"
echo "4. In 'Authorized JavaScript origins' section, ensure you have:"
echo "   https://d26aeuhfo3vnoz.cloudfront.net"
if [[ -n "$FRONTEND_CUSTOM_URL" ]]; then
    echo "   $FRONTEND_CUSTOM_URL"
fi
echo "5. Click 'Save'"
echo ""

echo "🧪 Testing Google OAuth Redirect"
echo "--------------------------------"
echo ""

# Test the Google OAuth redirect URI
COGNITO_REDIRECT="https://$COGNITO_DOMAIN/oauth2/idpresponse"
REDIRECT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$COGNITO_REDIRECT")

if [ "$REDIRECT_STATUS" = "400" ] || [ "$REDIRECT_STATUS" = "200" ]; then
    echo "✅ Cognito OAuth redirect endpoint is accessible (HTTP $REDIRECT_STATUS)"
else
    echo "⚠️  Cognito OAuth redirect endpoint returned HTTP $REDIRECT_STATUS"
fi

echo ""
echo "📋 Summary of Required URLs in Google Console:"
echo ""
echo "**Authorized redirect URIs:**"
echo "https://$COGNITO_DOMAIN/oauth2/idpresponse"
echo ""
echo "**Authorized JavaScript origins:**"
echo "https://d26aeuhfo3vnoz.cloudfront.net"
if [[ -n "$FRONTEND_CUSTOM_URL" ]]; then
    echo "$FRONTEND_CUSTOM_URL"
fi
echo ""

echo "🔄 After configuring Google Console, test the flow:"
echo "1. Visit: https://d26aeuhfo3vnoz.cloudfront.net"
echo "2. Click 'Get Started'"
echo "3. Click 'Continue with Google'"
echo "4. Complete Google OAuth"
echo "5. You should be redirected back to your app"
echo ""

echo "🚨 Common Issues:"
echo "- **Redirect URI mismatch**: Ensure the redirect URI in Google Console exactly matches:"
echo "  https://$COGNITO_DOMAIN/oauth2/idpresponse"
echo "- **Origin mismatch**: Ensure your domain is listed in Authorized JavaScript origins"
echo "- **OAuth scope errors**: The app requests 'openid email profile' which should be auto-approved"
echo ""

echo "✅ Your configuration should be:"
echo ""
cat << EOF
Google OAuth Client Configuration:
==================================

Client ID: $GOOGLE_CLIENT_ID
Client Secret: ${GOOGLE_CLIENT_SECRET:0:10}...

Authorized redirect URIs:
- https://$COGNITO_DOMAIN/oauth2/idpresponse

Authorized JavaScript origins:
- https://d26aeuhfo3vnoz.cloudfront.net
EOF

if [[ -n "$FRONTEND_CUSTOM_URL" ]]; then
    echo "- $FRONTEND_CUSTOM_URL"
fi

echo ""
echo "🎯 Next: Run './tools/test-google-oauth.sh' to verify everything works!"