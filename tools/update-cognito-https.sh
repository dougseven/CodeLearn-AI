#!/bin/bash

source config/dev-config.sh

echo "🔐 Updating Cognito with HTTPS Redirect URLs"
echo "============================================"
echo ""

if [[ -z "$FRONTEND_HTTPS_URL" ]]; then
    echo "❌ FRONTEND_HTTPS_URL not found in configuration"
    echo "Please run the CloudFront setup first"
    exit 1
fi

echo "Configuring Cognito with:"
echo "  HTTPS Frontend URL: $FRONTEND_HTTPS_URL"
echo "  User Pool ID: $USER_POOL_ID"
echo "  App Client ID: $APP_CLIENT_ID"
echo ""

# Update Cognito app client with HTTPS URLs
echo "Updating Cognito app client configuration..."

aws cognito-idp update-user-pool-client \
    --user-pool-id $USER_POOL_ID \
    --client-id $APP_CLIENT_ID \
    --explicit-auth-flows "ALLOW_USER_PASSWORD_AUTH" "ALLOW_USER_SRP_AUTH" "ALLOW_REFRESH_TOKEN_AUTH" \
    --callback-urls "${FRONTEND_HTTPS_URL}" "${FRONTEND_HTTPS_URL}/auth/callback" "http://localhost:3000/auth/callback" "http://localhost:8080/auth/callback" \
    --logout-urls "${FRONTEND_HTTPS_URL}" "http://localhost:3000" "http://localhost:8080" \
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
    echo "    - ${FRONTEND_HTTPS_URL}"
    echo "    - ${FRONTEND_HTTPS_URL}/auth/callback"
    echo "    - http://localhost:3000/auth/callback (for local testing)"
    echo "    - http://localhost:8080/auth/callback (for local testing)"
    echo ""
    echo "  Logout URLs:"
    echo "    - ${FRONTEND_HTTPS_URL}"
    echo "    - http://localhost:3000 (for local testing)"
    echo "    - http://localhost:8080 (for local testing)"
    echo ""
    echo "🌐 OAuth Login URL (for testing):"
    echo "https://$COGNITO_DOMAIN/login?client_id=$APP_CLIENT_ID&response_type=code&scope=openid+email+profile&redirect_uri=$(echo "$FRONTEND_HTTPS_URL" | sed 's/+/%2B/g')"
    echo ""
    echo "🔄 Next steps:"
    echo "1. Wait for CloudFront distribution to deploy (check: https://console.aws.amazon.com/cloudfront/)"
    echo "2. Update frontend configuration with HTTPS URL"
    echo "3. Test OAuth flow with HTTPS"
else
    echo "❌ Failed to update Cognito configuration"
    exit 1
fi