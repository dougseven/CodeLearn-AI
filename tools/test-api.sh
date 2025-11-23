#!/bin/bash
# CodeLearn Platform - API Testing Script
# Test all API endpoints

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load configuration
if [ -f "config/dev-config.sh" ]; then
    source config/dev-config.sh
elif [ -f "../config/dev-config.sh" ]; then
    source ../config/dev-config.sh
else
    echo -e "${RED}❌ Configuration not found: config/dev-config.sh${NC}"
    exit 1
fi

# Check if API endpoint is configured
if [ -z "$API_ENDPOINT" ]; then
    echo -e "${RED}❌ API_ENDPOINT not configured in config/dev-config.sh${NC}"
    exit 1
fi

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════╗
║                       API Endpoint Testing                            ║
╚═══════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}API Endpoint: $API_ENDPOINT${NC}"
echo -e "${BLUE}Region: $AWS_REGION${NC}"
echo ""

TESTS_PASSED=0
TESTS_FAILED=0

# Function to test an endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4
    local expected_status=$5
    
    echo -e "${CYAN}Testing: $description${NC}"
    echo "  Endpoint: $method $endpoint"
    
    # Make the request
    if [ -n "$data" ]; then
        RESPONSE=$(curl -s -w "\n%{http_code}" -X $method \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$API_ENDPOINT$endpoint" 2>&1)
    else
        RESPONSE=$(curl -s -w "\n%{http_code}" -X $method \
            "$API_ENDPOINT$endpoint" 2>&1)
    fi
    
    # Extract status code (last line)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    # Check status code
    if [ "$HTTP_CODE" = "$expected_status" ]; then
        echo -e "  ${GREEN}✅ Status: $HTTP_CODE (Expected: $expected_status)${NC}"
        
        # Try to parse JSON
        if echo "$BODY" | jq . > /dev/null 2>&1; then
            echo "  Response: Valid JSON"
            # Show first 100 chars of response
            PREVIEW=$(echo "$BODY" | jq -c . | head -c 100)
            echo "  Preview: $PREVIEW..."
        else
            echo "  Response: $BODY"
        fi
        
        ((TESTS_PASSED++))
        echo ""
        return 0
    else
        echo -e "  ${RED}❌ Status: $HTTP_CODE (Expected: $expected_status)${NC}"
        echo "  Response: $BODY"
        ((TESTS_FAILED++))
        echo ""
        return 1
    fi
}

# Function to test endpoint availability (no auth required)
test_endpoint_availability() {
    local endpoint=$1
    local description=$2
    
    echo -e "${CYAN}Testing: $description${NC}"
    echo "  Endpoint: GET $endpoint"
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_ENDPOINT$endpoint")
    
    # Accept various success codes
    if [[ "$HTTP_CODE" =~ ^(200|400|401|403)$ ]]; then
        echo -e "  ${GREEN}✅ Endpoint accessible (Status: $HTTP_CODE)${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}❌ Endpoint not accessible (Status: $HTTP_CODE)${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# ============================================================================
# TEST SUITE
# ============================================================================

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║ 1. API Gateway Connectivity                                           ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test if API Gateway is responding
echo -e "${CYAN}Testing: API Gateway Base${NC}"
BASE_RESPONSE=$(curl -s -w "\n%{http_code}" "$API_ENDPOINT/" 2>&1)
BASE_CODE=$(echo "$BASE_RESPONSE" | tail -n1)

if [[ "$BASE_CODE" =~ ^(200|403|404)$ ]]; then
    echo -e "  ${GREEN}✅ API Gateway is responding (Status: $BASE_CODE)${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ API Gateway not responding (Status: $BASE_CODE)${NC}"
    ((TESTS_FAILED++))
fi
echo ""

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║ 2. Health Check Endpoints                                             ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test health endpoint (if exists)
test_endpoint_availability "/health" "Health check endpoint"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║ 3. Lesson API Endpoints                                               ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test lesson endpoint (should fail without auth, but endpoint should exist)
test_endpoint_availability "/api/lesson" "Lesson API availability"

# Test with invalid data (should return 400 or 401)
test_endpoint "POST" "/api/lesson/get" "Lesson generation (no auth)" \
    '{"language":"python","level":"beginner"}' \
    "401"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║ 4. Code Validation Endpoints                                          ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test validation endpoint availability
test_endpoint_availability "/api/code/submit" "Code validation API availability"

# Test with invalid data (should return 400 or 401)
test_endpoint "POST" "/api/code/submit" "Code validation (no auth)" \
    '{"code":"print(1)","tests":[],"language":"python"}' \
    "401"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║ 5. User API Endpoints                                                 ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test user profile endpoint
test_endpoint_availability "/api/user/profile" "User profile API availability"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║ 6. CORS Configuration                                                 ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}Testing: CORS Headers${NC}"
CORS_RESPONSE=$(curl -s -I -X OPTIONS "$API_ENDPOINT/api/lesson/get" \
    -H "Origin: http://localhost:3000" \
    -H "Access-Control-Request-Method: POST" 2>&1)

if echo "$CORS_RESPONSE" | grep -qi "Access-Control-Allow-Origin"; then
    ALLOW_ORIGIN=$(echo "$CORS_RESPONSE" | grep -i "Access-Control-Allow-Origin" | cut -d: -f2- | tr -d '[:space:]')
    echo -e "  ${GREEN}✅ CORS configured${NC}"
    echo "  Allow-Origin: $ALLOW_ORIGIN"
    ((TESTS_PASSED++))
else
    echo -e "  ${YELLOW}⚠️  CORS headers not found${NC}"
    echo "  This may cause issues with frontend"
    ((TESTS_FAILED++))
fi
echo ""

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║ 7. Response Time Check                                                ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}Testing: API Response Times${NC}"

# Test response time for base endpoint
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" "$API_ENDPOINT/")
RESPONSE_MS=$(echo "$RESPONSE_TIME * 1000" | bc | cut -d. -f1)

echo "  Base endpoint: ${RESPONSE_MS}ms"

if [ $RESPONSE_MS -lt 1000 ]; then
    echo -e "  ${GREEN}✅ Excellent response time (<1s)${NC}"
    ((TESTS_PASSED++))
elif [ $RESPONSE_MS -lt 3000 ]; then
    echo -e "  ${YELLOW}⚠️  Acceptable response time (1-3s)${NC}"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ Slow response time (>3s)${NC}"
    ((TESTS_FAILED++))
fi
echo ""

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║ 8. Lambda Function Status                                             ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}Testing: Lambda Functions Behind API${NC}"

# Check if Lambda functions exist
for FUNC in CodeLearn-Lesson CodeLearn-Validation CodeLearn-User CodeLearn-Auth; do
    if aws lambda get-function --function-name $FUNC --region $AWS_REGION > /dev/null 2>&1; then
        STATE=$(aws lambda get-function --function-name $FUNC --region $AWS_REGION \
            --query 'Configuration.State' --output text 2>/dev/null)
        
        if [ "$STATE" = "Active" ]; then
            echo -e "  ${GREEN}✅ $FUNC - Active${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "  ${YELLOW}⚠️  $FUNC - $STATE${NC}"
            ((TESTS_FAILED++))
        fi
    else
        echo -e "  ${RED}❌ $FUNC - Not Found${NC}"
        ((TESTS_FAILED++))
    fi
done
echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                            Test Summary                               ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))

echo "  Total Tests: $TOTAL_TESTS"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
echo ""

# Calculate success rate
if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))
    echo "  Success Rate: $SUCCESS_RATE%"
    echo ""
fi

# Overall result
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ All API tests passed!                                             ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    exit 0
elif [ $SUCCESS_RATE -ge 75 ]; then
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ⚠️  Most tests passed, but some issues detected                      ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Recommendations:"
    echo "  • Review failed tests above"
    echo "  • Check Lambda function logs: ./dev.sh logs"
    echo "  • Verify API Gateway configuration"
    exit 0
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ Multiple API tests failed!                                         ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Troubleshooting steps:"
    echo "  1. Check if API Gateway is deployed: ./dev.sh check-config"
    echo "  2. Verify Lambda functions exist: aws lambda list-functions"
    echo "  3. Check API Gateway stages: aws apigateway get-stages --rest-api-id \$API_ID"
    echo "  4. Review Lambda logs: ./dev.sh logs"
    echo "  5. Try redeploying: ./dev.sh deploy"
    exit 1
fi