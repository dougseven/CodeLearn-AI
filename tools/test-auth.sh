#!/bin/bash

source config/dev-config.sh

echo "🔐 Testing Cognito Authentication"
echo "================================="
echo ""

# Prompt for credentials
echo -n "Email: "
read EMAIL
echo -n "Password: "
read -s PASSWORD
echo ""

# Debug: Check if variables are set
if [[ -z "$EMAIL" || -z "$PASSWORD" ]]; then
    echo "❌ Error: Email or password not provided"
    echo "Email length: ${#EMAIL}"
    exit 1
fi

echo "Testing authentication for: $EMAIL"

# Initiate auth
RESPONSE=$(aws cognito-idp initiate-auth \
    --auth-flow USER_PASSWORD_AUTH \
    --client-id $APP_CLIENT_ID \
    --auth-parameters USERNAME=$EMAIL,PASSWORD=$PASSWORD \
    --query 'AuthenticationResult' \
    --output json 2>&1)

if echo "$RESPONSE" | grep -q "AccessToken"; then
    echo "✅ Authentication successful!"
    echo ""
    
    # Extract tokens
    ACCESS_TOKEN=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['AccessToken'])")
    ID_TOKEN=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['IdToken'])")
    
    # Decode ID token to show user info
    echo "User Info:"
    TOKEN_PAYLOAD=$(echo "$ID_TOKEN" | cut -d. -f2)
    # Add padding if needed for base64 decoding
    case $((${#TOKEN_PAYLOAD} % 4)) in
        2) TOKEN_PAYLOAD="${TOKEN_PAYLOAD}==";;
        3) TOKEN_PAYLOAD="${TOKEN_PAYLOAD}=";;
    esac
    echo "$TOKEN_PAYLOAD" | base64 -d 2>/dev/null | python3 -m json.tool | grep -E '"email"|"name"|"sub"'
    
    echo ""
    echo "Access Token (first 50 chars):"
    echo "${ACCESS_TOKEN:0:50}..."
    
    # Save for later use
    echo "$ACCESS_TOKEN" > /tmp/codelearn-token.txt
    echo ""
    echo "💾 Token saved to /tmp/codelearn-token.txt"
    
else
    echo "❌ Authentication failed"
    echo "$RESPONSE"
fi
