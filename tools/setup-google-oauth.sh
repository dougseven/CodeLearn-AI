#!/bin/bash

source config/dev-config.sh

echo "🔐 Setting up Google OAuth for CodeLearn"
echo "========================================"
echo ""

# Google OAuth Configuration - Set these environment variables or add to config/dev-config.sh
: ${GOOGLE_CLIENT_ID:?"Error: GOOGLE_CLIENT_ID not set"}
: ${GOOGLE_CLIENT_SECRET:?"Error: GOOGLE_CLIENT_SECRET not set"}

echo "📋 Configuration Summary:"
echo "   User Pool ID: $USER_POOL_ID"
echo "   App Client ID: $APP_CLIENT_ID"
echo "   Google Client ID: $GOOGLE_CLIENT_ID"
echo "   Cognito Domain: $COGNITO_DOMAIN"
echo ""

echo "🔗 Step 1: Creating Google Identity Provider in Cognito..."

# Create Google identity provider
GOOGLE_IDP_RESULT=$(aws cognito-idp create-identity-provider \
    --user-pool-id "$USER_POOL_ID" \
    --provider-name "Google" \
    --provider-type "Google" \
    --provider-details \
        client_id="$GOOGLE_CLIENT_ID",client_secret="$GOOGLE_CLIENT_SECRET",authorize_scopes="openid email profile" \
    --attribute-mapping \
        email=email,given_name=given_name,family_name=family_name,picture=picture,username=sub 2>&1)

if echo "$GOOGLE_IDP_RESULT" | grep -q "ProviderName"; then
    echo "✅ Google identity provider created successfully"
elif echo "$GOOGLE_IDP_RESULT" | grep -q "ResourceExistsException"; then
    echo "ℹ️  Google identity provider already exists"
    
    # Update existing provider
    echo "🔄 Updating existing Google identity provider..."
    aws cognito-idp update-identity-provider \
        --user-pool-id "$USER_POOL_ID" \
        --provider-name "Google" \
        --provider-details \
            client_id="$GOOGLE_CLIENT_ID",client_secret="$GOOGLE_CLIENT_SECRET",authorize_scopes="openid email profile" \
        --attribute-mapping \
            email=email,given_name=given_name,family_name=family_name,picture=picture,username=sub
    
    echo "✅ Google identity provider updated"
else
    echo "❌ Failed to create Google identity provider:"
    echo "$GOOGLE_IDP_RESULT"
    exit 1
fi

echo ""
echo "🔧 Step 2: Updating Cognito App Client to support Google..."

# Update app client to include Google as supported identity provider
aws cognito-idp update-user-pool-client \
    --user-pool-id "$USER_POOL_ID" \
    --client-id "$APP_CLIENT_ID" \
    --supported-identity-providers "COGNITO" "Google" \
    --callback-urls \
        "https://codelearn.dougseven.com" \
        "https://codelearn.dougseven.com/auth/callback" \
        "https://d26aeuhfo3vnoz.cloudfront.net" \
        "https://d26aeuhfo3vnoz.cloudfront.net/auth/callback" \
        "http://localhost:3000/auth/callback" \
        "http://localhost:8080/auth/callback" \
    --logout-urls \
        "https://codelearn.dougseven.com" \
        "https://d26aeuhfo3vnoz.cloudfront.net" \
        "http://localhost:3000" \
        "http://localhost:8080" \
    --allowed-o-auth-flows "code" \
    --allowed-o-auth-scopes "openid" "email" "profile" \
    --allowed-o-auth-flows-user-pool-client

if [ $? -eq 0 ]; then
    echo "✅ App client updated to support Google OAuth"
else
    echo "❌ Failed to update app client"
    exit 1
fi

echo ""
echo "📱 Step 3: Configuring User Pool Domain for OAuth..."

# Check if domain already exists
DOMAIN_STATUS=$(aws cognito-idp describe-user-pool-domain \
    --domain "$COGNITO_DOMAIN" \
    --query 'DomainDescription.Status' \
    --output text 2>/dev/null)

if [ "$DOMAIN_STATUS" = "ACTIVE" ]; then
    echo "✅ Cognito domain is already active: $COGNITO_DOMAIN"
else
    echo "⚠️  Cognito domain not found or not active"
    echo "   Domain should be: $COGNITO_DOMAIN"
fi

echo ""
echo "🌐 Step 4: Testing OAuth URLs..."

# Test URLs
PRIMARY_OAUTH_URL="https://$COGNITO_DOMAIN/login?client_id=$APP_CLIENT_ID&response_type=code&scope=openid+email+profile&redirect_uri=https://d26aeuhfo3vnoz.cloudfront.net"
GOOGLE_OAUTH_URL="https://$COGNITO_DOMAIN/oauth2/authorize?client_id=$APP_CLIENT_ID&response_type=code&scope=openid+email+profile&redirect_uri=https://d26aeuhfo3vnoz.cloudfront.net&identity_provider=Google"

echo "📋 OAuth URLs:"
echo "   Cognito Login: $PRIMARY_OAUTH_URL"
echo "   Direct Google: $GOOGLE_OAUTH_URL"

# Test if URLs are accessible
echo ""
echo "🧪 Testing OAuth endpoint accessibility..."

OAUTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$PRIMARY_OAUTH_URL")
if [ "$OAUTH_STATUS" = "200" ]; then
    echo "✅ OAuth endpoint is accessible"
else
    echo "⚠️  OAuth endpoint returned HTTP $OAUTH_STATUS"
fi

echo ""
echo "🎉 Google OAuth Setup Complete!"
echo "=============================="
echo ""
echo "📋 Summary:"
echo "   ✅ Google identity provider configured in Cognito"
echo "   ✅ App client updated to support Google OAuth"
echo "   ✅ OAuth URLs generated and tested"
echo ""
echo "🌐 OAuth URLs:"
echo "   Primary Login: $PRIMARY_OAUTH_URL"
echo "   Google Direct: $GOOGLE_OAUTH_URL"
echo ""
echo "🔄 Next Steps:"
echo "1. Update your frontend to include Google sign-in button"
echo "2. Test the OAuth flow end-to-end"
echo "3. Verify user creation in Cognito User Pool"
echo ""
echo "⚠️  Important Notes:"
echo "- Users signing in with Google will be automatically created in your User Pool"
echo "- Google profile information (name, email, picture) will be mapped to user attributes"
echo "- The 'sub' field from Google will be used as the username in Cognito"
echo ""
echo "📱 Google Cloud Console Configuration:"
echo "Ensure your Google OAuth client at:"
echo "https://console.cloud.google.com/apis/credentials"
echo ""
echo "Has these authorized redirect URIs:"
echo "- https://$COGNITO_DOMAIN/oauth2/idpresponse"
echo ""
echo "And authorized origins:"
echo "- https://d26aeuhfo3vnoz.cloudfront.net"
echo "- https://codelearn.dougseven.com"