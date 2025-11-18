#!/bin/bash

source config/dev-config.sh

echo "🧪 Testing DynamoDB Access"
echo "=========================="
echo ""

# Test 1: Write to Lesson Cache
echo "Test 1: Writing test item to lesson cache..."
aws dynamodb put-item \
    --table-name $LESSON_CACHE_TABLE \
    --item '{
        "lessonKey": {"S": "test_python_beginner_variables"},
        "content": {"S": "Test lesson content"},
        "createdAt": {"N": "1700000000"},
        "ttl": {"N": "1800000000"}
    }' \
    --return-consumed-capacity TOTAL

if [ $? -eq 0 ]; then
    echo "✅ Write successful"
else
    echo "❌ Write failed"
    exit 1
fi

echo ""

# Test 2: Read from Lesson Cache
echo "Test 2: Reading test item from lesson cache..."
RESULT=$(aws dynamodb get-item \
    --table-name $LESSON_CACHE_TABLE \
    --key '{"lessonKey": {"S": "test_python_beginner_variables"}}' \
    --query 'Item.content.S' \
    --output text)

if [ "$RESULT" = "Test lesson content" ]; then
    echo "✅ Read successful: $RESULT"
else
    echo "❌ Read failed"
    exit 1
fi

echo ""

# Test 3: Delete test item
echo "Test 3: Cleaning up test item..."
aws dynamodb delete-item \
    --table-name $LESSON_CACHE_TABLE \
    --key '{"lessonKey": {"S": "test_python_beginner_variables"}}'

if [ $? -eq 0 ]; then
    echo "✅ Delete successful"
else
    echo "❌ Delete failed"
fi

echo ""
echo "✅ All DynamoDB tests passed!"
