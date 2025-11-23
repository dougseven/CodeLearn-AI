#!/bin/bash

source config/dev-config.sh

echo "🧪 Testing HTTPS Frontend"
echo "========================="
echo ""

if [[ -z "$FRONTEND_HTTPS_URL" ]]; then
    echo "❌ FRONTEND_HTTPS_URL not configured"
    exit 1
fi

echo "📋 Configuration Summary:"
echo "  HTTPS Frontend URL: $FRONTEND_HTTPS_URL"
echo "  CloudFront Distribution: $CLOUDFRONT_DISTRIBUTION_ID"
echo "  S3 Bucket: $FRONTEND_BUCKET"
echo ""

# Check CloudFront status
echo "🔍 Checking CloudFront deployment status..."
STATUS=$(aws cloudfront get-distribution --id $CLOUDFRONT_DISTRIBUTION_ID --query 'Distribution.Status' --output text)
echo "  CloudFront Status: $STATUS"

if [[ "$STATUS" == "Deployed" ]]; then
    echo "  ✅ CloudFront is fully deployed"
elif [[ "$STATUS" == "InProgress" ]]; then
    echo "  ⏳ CloudFront is still deploying (this can take 10-15 minutes)"
    echo "  Check status: https://console.aws.amazon.com/cloudfront/"
else
    echo "  ❓ CloudFront status: $STATUS"
fi

echo ""

# Test the frontend URL
echo "🌐 Testing HTTPS Frontend..."
echo "  URL: $FRONTEND_HTTPS_URL"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_HTTPS_URL" || echo "000")

if [[ "$HTTP_STATUS" == "200" ]]; then
    echo "  ✅ Frontend is accessible via HTTPS"
elif [[ "$HTTP_STATUS" == "000" ]]; then
    echo "  ❌ Frontend not accessible (DNS/network issue)"
elif [[ "$HTTP_STATUS" == "403" ]]; then
    echo "  ⏳ Frontend returns 403 (CloudFront may still be deploying)"
else
    echo "  ❓ Frontend returned HTTP $HTTP_STATUS"
fi

echo ""

# OAuth Login URLs
echo "🔗 OAuth Login URLs:"
echo ""
echo "Direct Cognito OAuth URL:"
echo "https://$COGNITO_DOMAIN/login?client_id=$APP_CLIENT_ID&response_type=code&scope=openid+email+profile&redirect_uri=$(echo "$FRONTEND_HTTPS_URL" | sed 's/+/%2B/g')"
echo ""

echo "📝 Test Instructions:"
echo "1. Wait for CloudFront to be fully deployed (Status: Deployed)"
echo "2. Open the HTTPS frontend URL in your browser"
echo "3. Click 'Get Started' - should redirect to Cognito login"
echo "4. Login with: test@example.com / TestPassword123!"
echo "5. Should redirect back and show the classroom"
echo ""

if [[ "$STATUS" == "InProgress" ]]; then
    echo "⚠️  CloudFront is still deploying. Please wait and try again in a few minutes."
    echo "   You can check the status in the AWS CloudFront console."
elif [[ "$STATUS" == "Deployed" && "$HTTP_STATUS" == "200" ]]; then
    echo "🎉 HTTPS Frontend is ready for testing!"
    echo "   Open: $FRONTEND_HTTPS_URL"
else
    echo "⚠️  Please check the CloudFront console and try again."
fi