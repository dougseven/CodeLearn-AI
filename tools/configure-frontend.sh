#!/bin/bash

source config/dev-config.sh

echo "🔧 Configuring Frontend"
echo "======================="
echo ""

# Backup original
cp frontend/index.html frontend/index.html.backup

# Replace placeholders
sed -i.bak "s|YOUR_API_ENDPOINT_HERE|https://locbhxu5i5.execute-api.us-east-1.amazonaws.com/prod|g" frontend/index.html
sed -i.bak "s|YOUR_COGNITO_DOMAIN_HERE|codelearn-224157924354.auth.us-east-1.amazoncognito.com|g" frontend/index.html  
sed -i.bak "s|YOUR_APP_CLIENT_ID_HERE|5d79u7rce8b9ks156lgemd9rd7|g" frontend/index.html

# Clean up backup files
rm frontend/index.html.bak

echo "✅ Frontend configured with:"
echo "  API Endpoint: https://locbhxu5i5.execute-api.us-east-1.amazonaws.com/prod"
echo "  Cognito Domain: codelearn-224157924354.auth.us-east-1.amazoncognito.com"
echo "  App Client ID: 5d79u7rce8b9ks156lgemd9rd7"
