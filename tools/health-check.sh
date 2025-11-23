#!/bin/bash
# CodeLearn Platform - Health Check Script
# Comprehensive system health verification

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load configuration
if [ -f "config/dev-config.sh" ]; then
    source config/dev-config.sh
else
    echo -e "${RED}❌ Configuration not found: config/dev-config.sh${NC}"
    exit 1
fi

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║          CodeLearn Platform - Health Check            ║"
echo "╔════════════════════════════════════════════════════════╗"
echo -e "${NC}"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

print_check() {
    local status=$1
    local message=$2
    
    case $status in
        "PASS")
            echo -e "  ${GREEN}✅ PASS${NC} - $message"
            ((CHECKS_PASSED++))
            ;;
        "FAIL")
            echo -e "  ${RED}❌ FAIL${NC} - $message"
            ((CHECKS_FAILED++))
            ;;
        "WARN")
            echo -e "  ${YELLOW}⚠️  WARN${NC} - $message"
            ((CHECKS_WARNING++))
            ;;
        "INFO")
            echo -e "  ${BLUE}ℹ️  INFO${NC} - $message"
            ;;
    esac
}

# ============================================================================
# 1. AWS Connectivity Check
# ============================================================================
echo -e "${BLUE}1. AWS Connectivity${NC}"
echo "   Checking AWS access and credentials..."

if aws sts get-caller-identity > /dev/null 2>&1; then
    ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    print_check "PASS" "AWS credentials valid (Account: $ACCOUNT)"
else
    print_check "FAIL" "Cannot authenticate with AWS"
fi

echo ""

# ============================================================================
# 2. Lambda Functions Check
# ============================================================================
echo -e "${BLUE}2. Lambda Functions${NC}"
echo "   Checking Lambda function status..."

LAMBDA_FUNCTIONS=("CodeLearn-Lesson" "CodeLearn-Validation" "CodeLearn-User" "CodeLearn-Auth")

for FUNC in "${LAMBDA_FUNCTIONS[@]}"; do
    if aws lambda get-function --function-name $FUNC --region $AWS_REGION > /dev/null 2>&1; then
        # Get last modified date
        LAST_MODIFIED=$(aws lambda get-function --function-name $FUNC --region $AWS_REGION \
            --query 'Configuration.LastModified' --output text 2>/dev/null)
        print_check "PASS" "$FUNC exists (Last updated: $LAST_MODIFIED)"
        
        # Check if function has been invoked recently
        ERRORS=$(aws cloudwatch get-metric-statistics \
            --namespace AWS/Lambda \
            --metric-name Errors \
            --dimensions Name=FunctionName,Value=$FUNC \
            --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
            --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
            --period 3600 \
            --statistics Sum \
            --region $AWS_REGION \
            --query 'Datapoints[0].Sum' --output text 2>/dev/null)
        
        if [ "$ERRORS" != "None" ] && [ "$ERRORS" != "0.0" ] && [ -n "$ERRORS" ]; then
            print_check "WARN" "$FUNC has $ERRORS errors in the last hour"
        fi
    else
        print_check "FAIL" "$FUNC not found"
    fi
done

echo ""

# ============================================================================
# 3. DynamoDB Tables Check
# ============================================================================
echo -e "${BLUE}3. DynamoDB Tables${NC}"
echo "   Checking DynamoDB table status..."

TABLES=("$USERS_TABLE" "$PROGRESS_TABLE" "$LESSON_CACHE_TABLE" "$SESSIONS_TABLE")
TABLE_NAMES=("Users" "Progress" "Lesson Cache" "Sessions")

for i in "${!TABLES[@]}"; do
    TABLE="${TABLES[$i]}"
    NAME="${TABLE_NAMES[$i]}"
    
    if [ -z "$TABLE" ]; then
        print_check "WARN" "$NAME table name not configured"
        continue
    fi
    
    if aws dynamodb describe-table --table-name $TABLE --region $AWS_REGION > /dev/null 2>&1; then
        # Get item count
        ITEM_COUNT=$(aws dynamodb describe-table --table-name $TABLE --region $AWS_REGION \
            --query 'Table.ItemCount' --output text 2>/dev/null)
        
        # Get table size
        SIZE_BYTES=$(aws dynamodb describe-table --table-name $TABLE --region $AWS_REGION \
            --query 'Table.TableSizeBytes' --output text 2>/dev/null)
        SIZE_MB=$((SIZE_BYTES / 1024 / 1024))
        
        print_check "PASS" "$NAME table exists ($ITEM_COUNT items, ${SIZE_MB}MB)"
    else
        print_check "FAIL" "$NAME table not found"
    fi
done

echo ""

# ============================================================================
# 4. S3 Buckets Check
# ============================================================================
echo -e "${BLUE}4. S3 Buckets${NC}"
echo "   Checking S3 bucket status..."

# Static Lessons Bucket
if [ -n "$STATIC_LESSONS_BUCKET" ]; then
    if aws s3 ls s3://$STATIC_LESSONS_BUCKET > /dev/null 2>&1; then
        LESSON_COUNT=$(aws s3 ls s3://$STATIC_LESSONS_BUCKET/static/ --recursive 2>/dev/null | wc -l)
        print_check "PASS" "Static lessons bucket exists ($LESSON_COUNT files)"
    else
        print_check "FAIL" "Static lessons bucket not found"
    fi
else
    print_check "WARN" "Static lessons bucket name not configured"
fi

# Frontend Bucket
if [ -n "$FRONTEND_BUCKET" ]; then
    if aws s3 ls s3://$FRONTEND_BUCKET > /dev/null 2>&1; then
        FILE_COUNT=$(aws s3 ls s3://$FRONTEND_BUCKET --recursive 2>/dev/null | wc -l)
        print_check "PASS" "Frontend bucket exists ($FILE_COUNT files)"
        
        # Check if index.html exists
        if aws s3 ls s3://$FRONTEND_BUCKET/index.html > /dev/null 2>&1; then
            print_check "PASS" "Frontend index.html exists"
        else
            print_check "WARN" "Frontend index.html not found"
        fi
    else
        print_check "FAIL" "Frontend bucket not found"
    fi
else
    print_check "WARN" "Frontend bucket name not configured"
fi

echo ""

# ============================================================================
# 5. API Gateway Check
# ============================================================================
echo -e "${BLUE}5. API Gateway${NC}"
echo "   Checking API Gateway status..."

if [ -n "$API_ID" ]; then
    if aws apigateway get-rest-api --rest-api-id $API_ID --region $AWS_REGION > /dev/null 2>&1; then
        API_NAME=$(aws apigateway get-rest-api --rest-api-id $API_ID --region $AWS_REGION \
            --query 'name' --output text 2>/dev/null)
        print_check "PASS" "API Gateway exists ($API_NAME)"
        
        # Check deployment
        DEPLOYMENTS=$(aws apigateway get-deployments --rest-api-id $API_ID --region $AWS_REGION \
            --query 'items[0].createdDate' --output text 2>/dev/null)
        if [ -n "$DEPLOYMENTS" ] && [ "$DEPLOYMENTS" != "None" ]; then
            print_check "PASS" "API deployed (Last: $DEPLOYMENTS)"
        else
            print_check "WARN" "No API deployments found"
        fi
    else
        print_check "FAIL" "API Gateway not found"
    fi
else
    print_check "WARN" "API Gateway ID not configured"
fi

echo ""

# ============================================================================
# 6. Cognito User Pool Check
# ============================================================================
echo -e "${BLUE}6. Cognito User Pool${NC}"
echo "   Checking Cognito configuration..."

if [ -n "$USER_POOL_ID" ]; then
    if aws cognito-idp describe-user-pool --user-pool-id $USER_POOL_ID --region $AWS_REGION > /dev/null 2>&1; then
        USER_COUNT=$(aws cognito-idp list-users --user-pool-id $USER_POOL_ID --region $AWS_REGION \
            --query 'Users | length(@)' --output text 2>/dev/null)
        print_check "PASS" "User Pool exists ($USER_COUNT users)"
    else
        print_check "FAIL" "User Pool not found"
    fi
else
    print_check "WARN" "User Pool ID not configured"
fi

echo ""

# ============================================================================
# 7. Recent Errors Check
# ============================================================================
echo -e "${BLUE}7. Recent Errors${NC}"
echo "   Checking for errors in the last hour..."

ERROR_FOUND=false

for FUNC in CodeLearn-Lesson CodeLearn-Validation CodeLearn-User; do
    ERRORS=$(aws logs filter-log-events \
        --log-group-name /aws/lambda/$FUNC \
        --start-time $(($(date +%s) - 3600))000 \
        --filter-pattern "ERROR" \
        --query 'events | length(@)' \
        --output text 2>/dev/null)
    
    if [ -n "$ERRORS" ] && [ "$ERRORS" != "0" ] && [ "$ERRORS" != "None" ]; then
        print_check "WARN" "$FUNC has $ERRORS error(s) in last hour"
        ERROR_FOUND=true
    fi
done

if [ "$ERROR_FOUND" = false ]; then
    print_check "PASS" "No errors found in the last hour"
fi

echo ""

# ============================================================================
# 8. Cost Check
# ============================================================================
echo -e "${BLUE}8. Cost Check${NC}"
echo "   Checking current costs..."

YESTERDAY=$(date -u -d '1 day ago' +%Y-%m-%d)
TODAY=$(date -u +%Y-%m-%d)

COST=$(aws ce get-cost-and-usage \
    --time-period Start=$YESTERDAY,End=$TODAY \
    --granularity DAILY \
    --metrics UnblendedCost \
    --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
    --output text 2>/dev/null)

if [ -n "$COST" ] && [ "$COST" != "None" ]; then
    COST_ROUNDED=$(printf "%.2f" $COST)
    MONTHLY_PROJECTION=$(echo "$COST * 30" | bc)
    MONTHLY_ROUNDED=$(printf "%.2f" $MONTHLY_PROJECTION)
    
    if (( $(echo "$MONTHLY_PROJECTION > 25" | bc -l) )); then
        print_check "WARN" "Yesterday: \$$COST_ROUNDED, Monthly projection: \$$MONTHLY_ROUNDED (over \$25 budget!)"
    else
        print_check "PASS" "Yesterday: \$$COST_ROUNDED, Monthly projection: \$$MONTHLY_ROUNDED"
    fi
else
    print_check "INFO" "Cost data not available (may take 24 hours)"
fi

echo ""

# ============================================================================
# 9. Cache Performance Check
# ============================================================================
echo -e "${BLUE}9. Cache Performance${NC}"
echo "   Checking lesson cache hit rate..."

if [ -n "$LESSON_CACHE_TABLE" ]; then
    CACHE_ITEMS=$(aws dynamodb scan \
        --table-name $LESSON_CACHE_TABLE \
        --select COUNT \
        --region $AWS_REGION \
        --query 'Count' \
        --output text 2>/dev/null)
    
    if [ -n "$CACHE_ITEMS" ] && [ "$CACHE_ITEMS" != "0" ]; then
        print_check "PASS" "$CACHE_ITEMS lessons cached"
        
        # Get cache with high hit counts
        HIGH_HITS=$(aws dynamodb scan \
            --table-name $LESSON_CACHE_TABLE \
            --filter-expression "hitCount > :hits" \
            --expression-attribute-values '{":hits":{"N":"10"}}' \
            --select COUNT \
            --region $AWS_REGION \
            --query 'Count' \
            --output text 2>/dev/null)
        
        if [ -n "$HIGH_HITS" ] && [ "$HIGH_HITS" != "0" ]; then
            print_check "PASS" "$HIGH_HITS lessons with 10+ hits (good cache utilization)"
        fi
    else
        print_check "WARN" "No cached lessons found (consider creating static lessons)"
    fi
else
    print_check "WARN" "Cache table not configured"
fi

echo ""

# ============================================================================
# 10. Frontend Accessibility Check
# ============================================================================
echo -e "${BLUE}10. Frontend Accessibility${NC}"
echo "    Checking if frontend is accessible..."

if [ -n "$FRONTEND_URL" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL" 2>/dev/null)
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_check "PASS" "Frontend accessible (HTTP $HTTP_CODE)"
    elif [ "$HTTP_CODE" = "403" ]; then
        print_check "WARN" "Frontend returns 403 (check bucket permissions)"
    else
        print_check "WARN" "Frontend status: HTTP $HTTP_CODE"
    fi
else
    print_check "INFO" "Frontend URL not configured"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    Health Check Summary                 ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

TOTAL_CHECKS=$((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNING))

echo "  Total Checks: $TOTAL_CHECKS"
echo -e "  ${GREEN}Passed: $CHECKS_PASSED${NC}"
echo -e "  ${YELLOW}Warnings: $CHECKS_WARNING${NC}"
echo -e "  ${RED}Failed: $CHECKS_FAILED${NC}"
echo ""

# Overall status
if [ $CHECKS_FAILED -eq 0 ] && [ $CHECKS_WARNING -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ System Status: HEALTHY - All checks passed!        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    exit 0
elif [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ⚠️  System Status: OPERATIONAL with warnings          ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Recommended actions:"
    echo "  • Review warnings above"
    echo "  • Check AWS Cost Explorer"
    echo "  • Consider creating more static lessons"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ System Status: DEGRADED - Issues detected!          ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Recommended actions:"
    echo "  1. Review failed checks above"
    echo "  2. Run: ./dev.sh check-config"
    echo "  3. Run: ./quick-start-scripts.sh → Option 19 (Fix Common Issues)"
    echo "  4. Check: ./dev.sh errors"
    exit 1
fi