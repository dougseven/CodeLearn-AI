#!/bin/bash

echo "💰 CodeLearn Cost Check"
echo "======================="
echo ""

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account: $ACCOUNT_ID"
echo ""

# Get yesterday's costs
echo "📊 Yesterday's Costs:"
aws ce get-cost-and-usage \
  --time-period Start=$(date -v-1d +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query "ResultsByTime[0].Groups[?to_number(Metrics.UnblendedCost.Amount) > \`0.01\`].[Keys[0], Metrics.UnblendedCost.Amount]" \
  --output table

echo ""
echo "📈 This Month So Far:"
START_OF_MONTH=$(date +%Y-%m-01)
TODAY=$(date +%Y-%m-%d)

MONTH_COST=$(aws ce get-cost-and-usage \
  --time-period Start=$START_OF_MONTH,End=$TODAY \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
  --output text)

echo "Total: \$$MONTH_COST"
echo "Budget: \$25.00"

# Calculate percentage
PERCENTAGE=$(echo "scale=1; ($MONTH_COST / 25) * 100" | bc)
echo "Used: ${PERCENTAGE}%"

if (( $(echo "$MONTH_COST > 25" | bc -l) )); then
    echo "⚠️  WARNING: Over budget!"
elif (( $(echo "$MONTH_COST > 20" | bc -l) )); then
    echo "⚠️  CAUTION: Approaching budget limit"
else
    echo "✅ Within budget"
fi
