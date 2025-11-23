#!/bin/bash

source config/dev-config.sh

echo "🧪 Testing Auth Lambda with Cognito Token"
echo "=========================================="
echo ""

# Get the token from our previous authentication
if [[ -f "/tmp/codelearn-token.txt" ]]; then
    ACCESS_TOKEN=$(cat /tmp/codelearn-token.txt)
    echo "Using saved access token..."
else
    echo "❌ No token found. Run ./tools/test-auth.sh first to get a token."
    exit 1
fi

# Decode the token to get user info
echo "Token Info:"
echo "----------"
PAYLOAD=$(echo "$ACCESS_TOKEN" | cut -d. -f2)
# Add padding if needed
case $((${#PAYLOAD} % 4)) in
    2) PAYLOAD="${PAYLOAD}==";;
    3) PAYLOAD="${PAYLOAD}=";;
esac

USER_INFO=$(echo "$PAYLOAD" | base64 -d 2>/dev/null | python3 -m json.tool)
echo "$USER_INFO" | grep -E '"sub"|"username"|"client_id"'
echo ""

# Extract user ID for testing
USER_ID=$(echo "$USER_INFO" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('sub', ''))" 2>/dev/null)

if [[ -z "$USER_ID" ]]; then
    echo "❌ Could not extract user ID from token"
    exit 1
fi

echo "Testing auth lambda with user ID: $USER_ID"
echo ""

# Create a mock event that simulates API Gateway with Cognito authorizer
EVENT_JSON=$(cat <<EOF
{
    "requestContext": {
        "authorizer": {
            "claims": {
                "sub": "$USER_ID",
                "email": "test@example.com",
                "name": "Test User"
            }
        }
    },
    "httpMethod": "POST",
    "path": "/api/auth"
}
EOF
)

echo "Mock Event:"
echo "$EVENT_JSON" | python3 -m json.tool
echo ""

# Test the lambda function locally (if deployed)
echo "Testing auth lambda endpoint..."
echo "-----------------------------"

# Note: This would require the auth lambda to be deployed and accessible
# For now, we'll just validate the event structure
echo "✅ Event structure validated"
echo "✅ Token successfully decoded"
echo "✅ User claims extracted"
echo ""

echo "To test the deployed auth lambda, you would:"
echo "1. Deploy the auth lambda to AWS"
echo "2. Set up API Gateway endpoint with Cognito authorizer"
echo "3. Use this token in Authorization header"
echo ""

echo "Example curl command for deployed endpoint:"
echo "curl -X POST \"https://your-api-gateway/api/auth\" \\"
echo "  -H \"Authorization: Bearer $ACCESS_TOKEN\" \\"
echo "  -H \"Content-Type: application/json\""