#!/bin/bash

source config/dev-config.sh

echo "🔐 Updating Cognito with Custom Domain"
echo "======================================"
echo ""

if [[ -z "$CUSTOM_DOMAIN" ]]; then
    echo "❌ Custom domain not configured"
    echo "Please run ./tools/setup-custom-domain.sh first"
    exit 1
fi

CUSTOM_URL="https://$CUSTOM_DOMAIN"

echo "Updating Cognito app client with:"
echo "  Custom Domain URL: $CUSTOM_URL"
echo "  CloudFront URL: $FRONTEND_HTTPS_URL"
echo "  User Pool ID: $USER_POOL_ID"
echo "  App Client ID: $APP_CLIENT_ID"
echo ""

# Update Cognito app client with custom domain URLs
aws cognito-idp update-user-pool-client \
    --user-pool-id $USER_POOL_ID \
    --client-id $APP_CLIENT_ID \
    --explicit-auth-flows "ALLOW_USER_PASSWORD_AUTH" "ALLOW_USER_SRP_AUTH" "ALLOW_REFRESH_TOKEN_AUTH" \
    --callback-urls "$CUSTOM_URL" "${CUSTOM_URL}/auth/callback" "$FRONTEND_HTTPS_URL" "${FRONTEND_HTTPS_URL}/auth/callback" "http://localhost:3000/auth/callback" "http://localhost:8080/auth/callback" \
    --logout-urls "$CUSTOM_URL" "$FRONTEND_HTTPS_URL" "http://localhost:3000" "http://localhost:8080" \
    --supported-identity-providers "COGNITO" \
    --allowed-o-auth-flows "code" \
    --allowed-o-auth-scopes "openid" "email" "profile" \
    --allowed-o-auth-flows-user-pool-client

if [[ $? -eq 0 ]]; then
    echo ""
    echo "✅ Cognito configuration updated successfully!"
    echo ""
    echo "📋 OAuth URLs configured:"
    echo "  Callback URLs:"
    echo "    - $CUSTOM_URL"
    echo "    - ${CUSTOM_URL}/auth/callback"
    echo "    - $FRONTEND_HTTPS_URL"
    echo "    - ${FRONTEND_HTTPS_URL}/auth/callback"
    echo "    - http://localhost:3000/auth/callback (for local testing)"
    echo "    - http://localhost:8080/auth/callback (for local testing)"
    echo ""
    echo "  Logout URLs:"
    echo "    - $CUSTOM_URL"
    echo "    - $FRONTEND_HTTPS_URL"
    echo "    - http://localhost:3000 (for local testing)"
    echo "    - http://localhost:8080 (for local testing)"
    echo ""
    echo "🌐 OAuth Login URLs:"
    echo ""
    echo "Custom Domain:"
    echo "https://$COGNITO_DOMAIN/login?client_id=$APP_CLIENT_ID&response_type=code&scope=openid+email+profile&redirect_uri=$(echo "$CUSTOM_URL" | sed 's/+/%2B/g')"
    echo ""
    echo "CloudFront Domain:"
    echo "https://$COGNITO_DOMAIN/login?client_id=$APP_CLIENT_ID&response_type=code&scope=openid+email+profile&redirect_uri=$(echo "$FRONTEND_HTTPS_URL" | sed 's/+/%2B/g')"
    echo ""
    echo "🎉 Your custom domain setup is complete!"
    echo "   Primary URL: $CUSTOM_URL"
    echo ""
    echo "🔧 Test your setup:"
    echo "   1. Check DNS: dig $CUSTOM_DOMAIN"
    echo "   2. Test HTTPS: curl -I $CUSTOM_URL"
    echo "   3. Test OAuth: Open $CUSTOM_URL and click 'Get Started'"
else
    echo "❌ Failed to update Cognito configuration"
    exit 1
fi