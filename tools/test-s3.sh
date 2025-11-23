#!/bin/bash

source config/dev-config.sh

echo "🧪 Testing S3 Access"
echo "==================="
echo ""

# Test 1: Upload a test file
echo "Test 1: Uploading test file..."
echo "Test content" > /tmp/test-lesson.json
aws s3 cp /tmp/test-lesson.json s3://$STATIC_LESSONS_BUCKET/static/test/test-lesson.json

if [ $? -eq 0 ]; then
    echo "✅ Upload successful"
else
    echo "❌ Upload failed"
    exit 1
fi

echo ""

# Test 2: Download the file
echo "Test 2: Downloading test file..."
aws s3 cp s3://$STATIC_LESSONS_BUCKET/static/test/test-lesson.json /tmp/downloaded-lesson.json

CONTENT=$(cat /tmp/downloaded-lesson.json)
if [ "$CONTENT" = "Test content" ]; then
    echo "✅ Download successful: $CONTENT"
else
    echo "❌ Download failed or content mismatch"
    exit 1
fi

echo ""

# Test 3: List files
echo "Test 3: Listing files..."
COUNT=$(aws s3 ls s3://$STATIC_LESSONS_BUCKET/static/ --recursive | wc -l)
echo "✅ Found $COUNT files in bucket"

echo ""

# Test 4: Delete test file
echo "Test 4: Cleaning up..."
aws s3 rm s3://$STATIC_LESSONS_BUCKET/static/test/test-lesson.json
rm /tmp/test-lesson.json /tmp/downloaded-lesson.json

echo "✅ Cleanup successful"
echo ""
echo "✅ All S3 tests passed!"
