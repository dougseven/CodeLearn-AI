#!/bin/bash

source config/dev-config.sh

echo "🏥 CodeLearn Health Check"
echo "========================="
echo "$(date)"
echo ""

# Check all critical endpoints
check_endpoint() {
    local NAME=$1
    local URL=$2
    local METHOD=${3:-GET}
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X $METHOD "$URL" \
        -H "Content-Type: application/json" \
        -d '{"language":"python","level":"beginner"}' 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ $NAME - OK"
        return 0
    else
        echo "❌ $NAME - HTTP $HTTP_CODE"
        return 1
    fi
}

# Run checks
FAILURES=0

check_endpoint "Frontend" "$FRONTEND_URL" || FAILURES=$((FAILURES + 1))
check_endpoint "Lesson API" "${API_ENDPOINT}/api/lesson" "POST" || FAILURES=$((FAILURES + 1))
check_endpoint "Validation API" "${API_ENDPOINT}/api/validate" "POST" || FAILURES=$((FAILURES + 1))

echo ""
if [ $FAILURES -eq 0 ]; then
    echo "✅ All systems operational"
    exit 0
else
    echo "⚠️  $FAILURES checks failed"
    exit 1
fi
