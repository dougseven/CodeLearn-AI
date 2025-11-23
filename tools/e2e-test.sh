#!/bin/bash

source config/dev-config.sh

echo "🧪 End-to-End Platform Test"
echo "==========================="
echo ""

# Test 1: API Health Check
echo "Test 1: API Health Check"
echo "------------------------"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${API_ENDPOINT}/api/lesson" \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{"language":"python","level":"beginner"}')

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ API is responding"
else
    echo "❌ API returned HTTP $HTTP_CODE"
fi
echo ""

# Test 2: Lesson Generation
echo "Test 2: Lesson Generation"
echo "-------------------------"
LESSON_RESPONSE=$(curl -s "${API_ENDPOINT}/api/lesson" \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{
        "language": "python",
        "level": "beginner",
        "topic": "variables and data types"
    }')

if echo "$LESSON_RESPONSE" | grep -q "lessonId"; then
    echo "✅ Lesson generated successfully"
    LESSON_ID=$(echo "$LESSON_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['lessonId'])")
    echo "   Lesson ID: $LESSON_ID"
    
    # Check if it was cached
    if echo "$LESSON_RESPONSE" | grep -q '"cached":true'; then
        echo "   💾 Served from cache (cost: $0)"
    else
        echo "   🤖 Generated with AI (cost: ~$0.05)"
    fi
else
    echo "❌ Lesson generation failed"
    echo "$LESSON_RESPONSE"
fi
echo ""

# Test 3: Code Validation
echo "Test 3: Code Validation"
echo "-----------------------"
VALIDATION_RESPONSE=$(curl -s "${API_ENDPOINT}/api/validate" \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{
        "code": "name = \"Alice\"\nage = 25\nheight = 5.7\nis_student = True",
        "tests": ["def test_vars():\n    assert \"name\" in globals()"],
        "language": "python",
        "lessonId": "test"
    }')

if echo "$VALIDATION_RESPONSE" | grep -q "passed"; then
    PASSED=$(echo "$VALIDATION_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['passed'])")
    if [ "$PASSED" = "True" ]; then
        echo "✅ Code validation working (tests passed)"
    else
        echo "⚠️  Code validation working (tests failed as expected)"
    fi
else
    echo "❌ Code validation failed"
fi
echo ""

# Test 4: Static Lesson Serving
echo "Test 4: Static Lesson Serving"
echo "-----------------------------"
aws s3 ls s3://$STATIC_LESSONS_BUCKET/static/python/beginner/ | grep -q "variables_and_data_types.json"

if [ $? -eq 0 ]; then
    echo "✅ Static lessons are uploaded"
else
    echo "❌ Static lessons not found"
fi
echo ""

# Test 5: Frontend Accessibility
echo "Test 5: Frontend Accessibility"
echo "------------------------------"
# Test CloudFront HTTPS URL (primary)
FRONTEND_HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_HTTPS_URL")

if [ "$FRONTEND_HTTP" = "200" ]; then
    echo "✅ Frontend is accessible via CloudFront"
    echo "   HTTPS URL: $FRONTEND_HTTPS_URL"
    
    # Also test custom domain if configured
    if [[ -n "$FRONTEND_CUSTOM_URL" ]]; then
        CUSTOM_HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_CUSTOM_URL")
        if [ "$CUSTOM_HTTP" = "200" ]; then
            echo "✅ Custom domain is accessible"
            echo "   Custom URL: $FRONTEND_CUSTOM_URL"
        else
            echo "⚠️  Custom domain returned HTTP $CUSTOM_HTTP"
            echo "   Custom URL: $FRONTEND_CUSTOM_URL"
        fi
    fi
else
    echo "❌ Frontend returned HTTP $FRONTEND_HTTP"
    echo "   HTTPS URL: $FRONTEND_HTTPS_URL"
    
    # Fallback test S3 static website
    S3_HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL")
    if [ "$S3_HTTP" = "200" ]; then
        echo "✅ S3 static website accessible (fallback)"
        echo "   S3 URL: $FRONTEND_URL"
    else
        echo "❌ S3 static website also failed: HTTP $S3_HTTP"
    fi
fi
echo ""

# Test 6: DynamoDB Tables
echo "Test 6: Database Tables"
echo "----------------------"
for TABLE in $USERS_TABLE $PROGRESS_TABLE $SESSIONS_TABLE $LESSON_CACHE_TABLE; do
    STATUS=$(aws dynamodb describe-table --table-name $TABLE --query 'Table.TableStatus' --output text 2>&1)
    if [ "$STATUS" = "ACTIVE" ]; then
        echo "✅ $TABLE"
    else
        echo "❌ $TABLE - $STATUS"
    fi
done
echo ""

# Test 7: Lambda Functions
echo "Test 7: Lambda Functions"
echo "-----------------------"
for FUNC in CodeLearn-Lesson CodeLearn-Validation CodeLearn-User CodeLearn-Auth; do
    STATE=$(aws lambda get-function --function-name $FUNC --query 'Configuration.State' --output text 2>&1)
    if [ "$STATE" = "Active" ]; then
        echo "✅ $FUNC"
    else
        echo "❌ $FUNC - $STATE"
    fi
done
echo ""

# Test 8: Cost Check
echo "Test 8: Current Costs"
echo "--------------------"
./check-costs.sh | grep -A 5 "This Month So Far"
echo ""

# Summary
echo "==========================="
echo "End-to-End Test Complete"
echo "==========================="
echo ""
echo "🌐 Access your platform at:"
echo "   Primary (HTTPS): $FRONTEND_HTTPS_URL"
if [[ -n "$FRONTEND_CUSTOM_URL" ]]; then
    echo "   Custom Domain: $FRONTEND_CUSTOM_URL"
fi
echo "   Fallback (HTTP): $FRONTEND_URL"
echo "📚 API Documentation: docs/api-documentation.md"
echo "💰 Check costs: ./check-costs.sh"
