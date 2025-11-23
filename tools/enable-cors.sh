#!/bin/bash

source config/dev-config.sh

echo "🌐 Enabling CORS for API Gateway"
echo "================================="

# Function to enable CORS on a resource
enable_cors() {
    local RESOURCE_ID=$1
    local RESOURCE_NAME=$2
    
    echo "Enabling CORS on $RESOURCE_NAME..."
    
    # Create OPTIONS method
    aws apigateway put-method \
        --rest-api-id $API_ID \
        --resource-id $RESOURCE_ID \
        --http-method OPTIONS \
        --authorization-type NONE \
        --region $AWS_REGION > /dev/null 2>&1
    
    # Set up mock integration for OPTIONS
    aws apigateway put-integration \
        --rest-api-id $API_ID \
        --resource-id $RESOURCE_ID \
        --http-method OPTIONS \
        --type MOCK \
        --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
        --region $AWS_REGION > /dev/null 2>&1
    
    # Set up integration response
    aws apigateway put-integration-response \
        --rest-api-id $API_ID \
        --resource-id $RESOURCE_ID \
        --http-method OPTIONS \
        --status-code 200 \
        --response-parameters '{
            "method.response.header.Access-Control-Allow-Headers": "'"'"'Content-Type,Authorization'"'"'",
            "method.response.header.Access-Control-Allow-Methods": "'"'"'GET,POST,PUT,DELETE,OPTIONS'"'"'",
            "method.response.header.Access-Control-Allow-Origin": "'"'"'*'"'"'"
        }' \
        --region $AWS_REGION > /dev/null 2>&1
    
    # Set up method response
    aws apigateway put-method-response \
        --rest-api-id $API_ID \
        --resource-id $RESOURCE_ID \
        --http-method OPTIONS \
        --status-code 200 \
        --response-parameters '{
            "method.response.header.Access-Control-Allow-Headers": true,
            "method.response.header.Access-Control-Allow-Methods": true,
            "method.response.header.Access-Control-Allow-Origin": true
        }' \
        --region $AWS_REGION > /dev/null 2>&1
    
    echo "  ✅ CORS enabled on $RESOURCE_NAME"
}

# Get resource IDs
LESSON_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --query 'items[?path==`/api/lesson`].id' \
    --output text)

VALIDATE_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --query 'items[?path==`/api/validate`].id' \
    --output text)

PROFILE_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --query 'items[?path==`/api/user/profile`].id' \
    --output text)

# Enable CORS
enable_cors "$LESSON_RESOURCE_ID" "/api/lesson"
enable_cors "$VALIDATE_RESOURCE_ID" "/api/validate"
enable_cors "$PROFILE_RESOURCE_ID" "/api/user/profile"

echo ""
echo "🚀 Deploying API changes..."

# Deploy the API to make CORS changes active
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --region $AWS_REGION

echo "✅ CORS enabled and deployed on all endpoints"
