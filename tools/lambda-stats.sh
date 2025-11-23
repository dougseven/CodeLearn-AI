#!/bin/bash

source config/dev-config.sh

echo "📊 Lambda Function Statistics"
echo "=============================="
echo ""

for FUNC in CodeLearn-Lesson CodeLearn-Validation CodeLearn-User; do
    echo "Function: $FUNC"
    
    # Get invocation count (last 24 hours)
    INVOCATIONS=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/Lambda \
        --metric-name Invocations \
        --dimensions Name=FunctionName,Value=$FUNC \
        --start-time $(date -u -v-24H +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 86400 \
        --statistics Sum \
        --query 'Datapoints[0].Sum' \
        --output text)
    
    # Get error count
    ERRORS=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/Lambda \
        --metric-name Errors \
        --dimensions Name=FunctionName,Value=$FUNC \
        --start-time $(date -u -v-24H +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 86400 \
        --statistics Sum \
        --query 'Datapoints[0].Sum' \
        --output text)
    
    # Get average duration
    DURATION=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/Lambda \
        --metric-name Duration \
        --dimensions Name=FunctionName,Value=$FUNC \
        --start-time $(date -u -v-24H +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 86400 \
        --statistics Average \
        --query 'Datapoints[0].Average' \
        --output text)
    
    echo "  Invocations: ${INVOCATIONS:-0}"
    echo "  Errors: ${ERRORS:-0}"
    echo "  Avg Duration: ${DURATION:-0} ms"
    echo ""
done