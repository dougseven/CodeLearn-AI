#!/bin/bash

source config/dev-config.sh

echo "📊 CodeLearn Platform Dashboard"
echo "================================"
echo ""

# System Status
echo "🟢 System Status"
echo "----------------"
echo "API Endpoint: $API_ENDPOINT"
echo "Frontend: $FRONTEND_URL"
echo "Region: $AWS_REGION"
echo ""

# Lambda Stats (last 24 hours)
echo "⚡ Lambda Invocations (24h)"
echo "--------------------------"
./tools/lambda-stats.sh
echo ""

# Database Stats
echo "💾 Database Size"
echo "----------------"
for TABLE in $USERS_TABLE $PROGRESS_TABLE $LESSON_CACHE_TABLE; do
    SIZE=$(aws dynamodb describe-table --table-name $TABLE --query 'Table.TableSizeBytes' --output text)
    ITEMS=$(aws dynamodb describe-table --table-name $TABLE --query 'Table.ItemCount' --output text)
    SIZE_MB=$(( SIZE / 1024 / 1024 ))
    echo "$TABLE: ${ITEMS} items, ${SIZE_MB} MB"
done
echo ""

# Cache Performance
echo "📈 Cache Performance"
echo "-------------------"
CACHED=$(aws dynamodb scan --table-name $LESSON_CACHE_TABLE --select COUNT --query 'Count' --output text)
echo "Cached lessons: $CACHED"
echo "Hit rate target: 90%+"
echo ""

# Costs
echo "💰 Cost Summary"
echo "---------------"
./check-costs.sh | grep -A 3 "This Month So Far"
echo ""

# Recent Errors
echo "🚨 Recent Errors (1 hour)"
echo "------------------------"
ERROR_COUNT=0
for FUNC in CodeLearn-Lesson CodeLearn-Validation CodeLearn-User; do
    ERRORS=$(aws logs filter-log-events \
        --log-group-name /aws/lambda/$FUNC \
        --start-time $(($(date +%s) - 3600))000 \
        --filter-pattern "ERROR" \
        --query 'events' \
        --output json | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
    
    ERROR_COUNT=$(( ERROR_COUNT + ERRORS ))
done

if [ $ERROR_COUNT -eq 0 ]; then
    echo "✅ No errors in the last hour"
else
    echo "⚠️  $ERROR_COUNT errors found"
    echo "   Run: aws logs tail /aws/lambda/CodeLearn-Lesson --follow"
fi
