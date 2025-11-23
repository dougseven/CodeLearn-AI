#!/bin/bash

source config/dev-config.sh

echo "💰 Cost Optimization Check"
echo "=========================="
echo ""

# Get current month costs
MONTH_COST=$(aws ce get-cost-and-usage \
    --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
    --granularity MONTHLY \
    --metrics UnblendedCost \
    --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
    --output text)

echo "Current month cost: \$$MONTH_COST"

# Check if over budget
if (( $(echo "$MONTH_COST > 25" | bc -l) )); then
    echo "⚠️  OVER BUDGET!"
    echo "Taking optimization actions..."
    
    # Action 1: Check cache hit rate
    CACHE_ITEMS=$(aws dynamodb scan \
        --table-name $LESSON_CACHE_TABLE \
        --select COUNT \
        --query 'Count' \
        --output text)
    
    echo "Cached lessons: $CACHE_ITEMS"
    
    if [ $CACHE_ITEMS -lt 20 ]; then
        echo "⚠️  Low cache count - generate more static lessons!"
    fi
    
    # Action 2: Check for high-cost Lambda invocations
    echo "Checking for expensive operations..."
    aws logs filter-log-events \
        --log-group-name /aws/lambda/CodeLearn-Lesson \
        --start-time $(($(date +%s) - 86400))000 \
        --filter-pattern "Bedrock cost" \
        --query 'events[*].message' \
        | grep "cost" | sort -t'$' -k2 -nr | head -5
else
    echo "✅ Within budget"
fi

# Recommendations
echo ""
echo "Optimization Recommendations:"
echo "-----------------------------"

# Check static lesson coverage
STATIC_COUNT=$(aws s3 ls s3://$STATIC_LESSONS_BUCKET/static/ --recursive | wc -l)
echo "- Static lessons: $STATIC_COUNT (target: 30+)"

# Check cache hit rate (approximate)
echo "- Cache hit rate: Check with ./tools/dashboard.sh"

# Check Lambda memory usage
echo "- Lambda optimization: Run ./tools/lambda-stats.sh"
