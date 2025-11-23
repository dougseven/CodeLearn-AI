#!/bin/bash

source config/dev-config.sh

echo "🔧 CodeLearn Troubleshooting"
echo "============================"
echo ""
echo "Select issue to fix:"
echo "  1. Frontend shows CORS errors"
echo "  2. API returns 5xx errors"
echo "  3. Lessons not caching"
echo "  4. Authentication not working"
echo "  5. Run full diagnostic"
echo ""
read -p "Choice (1-5): " CHOICE

case $CHOICE in
    1)
        echo "Fixing CORS..."
        ./tools/enable-cors.sh
        aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod
        echo "✅ CORS fixed and API redeployed"
        ;;
    2)
        echo "Checking Lambda permissions..."
        # Re-add Lambda permissions
        for FUNC in CodeLearn-Lesson CodeLearn-Validation CodeLearn-User; do
            aws lambda add-permission \
                --function-name $FUNC \
                --statement-id apigateway-invoke-$(date +%s) \
                --action lambda:InvokeFunction \
                --principal apigateway.amazonaws.com \
                --source-arn "arn:aws:execute-api:${AWS_REGION}:${AWS_ACCOUNT_ID}:${API_ID}/*" \
                2>/dev/null || echo "$FUNC permission already exists"
        done
        echo "✅ Lambda permissions refreshed"
        ;;
    3)
        echo "Checking cache configuration..."
        # Verify environment variables
        aws lambda get-function-configuration \
            --function-name CodeLearn-Lesson \
            --query 'Environment.Variables' \
            --output json
        echo "Verify LESSON_CACHE_TABLE and STATIC_LESSONS_BUCKET are set correctly"
        ;;
    4)
        echo "Testing Cognito..."
        aws cognito-idp describe-user-pool --user-pool-id $USER_POOL_ID
        echo "Check if User Pool is active and App Client is configured"
        ;;
    5)
        echo "Running full diagnostic..."
        ./tools/e2e-test.sh
        ./tools/dashboard.sh
        ;;
    *)
        echo "Invalid choice"
        ;;
esac
