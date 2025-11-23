#!/bin/bash

source config/dev-config.sh

echo "🧪 Testing API Endpoints"
echo "========================"
echo ""
echo "API Endpoint: $API_ENDPOINT"
echo ""

# Test 1: Lesson endpoint
echo "Test 1: POST /api/lesson"
echo "------------------------"
RESPONSE=$(curl -s -X POST "${API_ENDPOINT}/api/lesson" \
    -H "Content-Type: application/json" \
    -d '{
        "language": "python",
        "level": "beginner",
        "topic": "variables and data types"
    }')

if echo "$RESPONSE" | grep -q "lessonId"; then
    echo "✅ Lesson endpoint working"
    echo "Response preview:"
    echo "$RESPONSE" | python3 -m json.tool | head -20
else
    echo "❌ Lesson endpoint failed"
    echo "$RESPONSE"
fi
echo ""

# Test 2: Validation endpoint
echo "Test 2: POST /api/validate"
echo "--------------------------"
RESPONSE=$(curl -s -X POST "${API_ENDPOINT}/api/validate" \
    -H "Content-Type: application/json" \
    -d '{
        "code": "x = 5\ny = 10\nz = x + y",
        "tests": ["def test_add():\n    assert z == 15"],
        "language": "python",
        "lessonId": "test123"
    }')

if echo "$RESPONSE" | grep -q "passed"; then
    echo "✅ Validation endpoint working"
    echo "Response:"
    echo "$RESPONSE" | python3 -m json.tool
else
    echo "❌ Validation endpoint failed"
    echo "$RESPONSE"
fi
echo ""

# Test 3: CORS headers
echo "Test 3: CORS Headers"
echo "-------------------"
HEADERS=$(curl -s -I -X OPTIONS "${API_ENDPOINT}/api/lesson")

if echo "$HEADERS" | grep -qi "access-control-allow-origin"; then
    echo "✅ CORS enabled"
else
    echo "❌ CORS not enabled"
fi
echo ""

echo "================================"
echo "API Testing Complete"
