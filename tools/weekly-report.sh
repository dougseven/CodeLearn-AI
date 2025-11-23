#!/bin/bash

source config/dev-config.sh

echo "📊 CodeLearn Weekly Report"
echo "=========================="
echo "Week ending: $(date)"
echo ""

# User Growth
echo "👥 User Activity"
echo "----------------"
USER_COUNT=$(aws dynamodb scan --table-name $USERS_TABLE --select COUNT --query 'Count' --output text)
echo "Total users: $USER_COUNT"

LESSON_COUNT=$(aws dynamodb scan --table-name $PROGRESS_TABLE --select COUNT --query 'Count' --output text)
echo "Lessons attempted: $LESSON_COUNT"
echo ""

# Cost Summary
echo "💰 Cost Summary"
echo "---------------"
WEEK_START=$(date -v-7d +%Y-%m-%d)
WEEK_END=$(date +%Y-%m-%d)

WEEK_COST=$(aws ce get-cost-and-usage \
    --time-period Start=$WEEK_START,End=$WEEK_END \
    --granularity DAILY \
    --metrics UnblendedCost \
    --query 'ResultsByTime[*].Total.UnblendedCost.Amount' \
    --output text | awk '{s+=$1} END {print s}')

echo "This week: \$$WEEK_COST"
echo "Monthly projection: \$$(echo "$WEEK_COST * 4" | bc)"
echo ""

# Performance
echo "⚡ Performance"
echo "-------------"
./tools/lambda-stats.sh | grep -A 3 "Invocations"
echo ""

# Top Issues
echo "🔍 Issues This Week"
echo "-------------------"
for FUNC in CodeLearn-Lesson CodeLearn-Validation; do
    ERROR_COUNT=$(aws logs filter-log-events \
        --log-group-name /aws/lambda/$FUNC \
        --start-time $(($(date +%s) - 604800))000 \
        --filter-pattern "ERROR" \
        --query 'events' \
        --output json | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
    
    if [ $ERROR_COUNT -gt 0 ]; then
        echo "⚠️  $FUNC: $ERROR_COUNT errors"
    fi
done

echo ""
echo "📈 Next Steps:"
echo "- Review cost breakdown: ./check-costs.sh"
echo "- Check dashboard: ./tools/dashboard.sh"
echo "- Optimize if needed: ./tools/optimize-costs.sh"
