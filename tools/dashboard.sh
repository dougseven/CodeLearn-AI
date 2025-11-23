#!/bin/bash
# CodeLearn Platform - Dashboard
# Real-time platform metrics and status display

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Load configuration
if [ -f "config/dev-config.sh" ]; then
    source config/dev-config.sh
else
    echo -e "${RED}❌ Configuration not found: config/dev-config.sh${NC}"
    exit 1
fi

# Clear screen and show header
clear

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║   ____          _      _                           ____               ║
║  / ___|___   __| | ___| |    ___  __ _ _ __ _ __  |  _ \  _____   __ ║
║ | |   / _ \ / _` |/ _ \ |   / _ \/ _` | '__| '_ \ | | | |/ _ \ \ / / ║
║ | |__| (_) | (_| |  __/ |__|  __/ (_| | |  | | | || |_| |  __/\ V /  ║
║  \____\___/ \__,_|\___|_____\___|\__,_|_|  |_| |_||____/ \___| \_/   ║
║                                                                       ║
║                        Platform Dashboard                            ║
╚═══════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${WHITE}Last Updated: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${WHITE}AWS Account: ${AWS_ACCOUNT_ID} | Region: ${AWS_REGION}${NC}"
echo ""

# ============================================================================
# SECTION 1: System Status
# ============================================================================
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ 📊 SYSTEM STATUS                                                      ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Lambda Function Status
echo -e "${BLUE}Lambda Functions:${NC}"
LAMBDA_HEALTHY=0
LAMBDA_TOTAL=0

for FUNC in CodeLearn-Lesson CodeLearn-Validation CodeLearn-User CodeLearn-Auth; do
    ((LAMBDA_TOTAL++))
    if aws lambda get-function --function-name $FUNC --region $AWS_REGION > /dev/null 2>&1; then
        # Get state
        STATE=$(aws lambda get-function --function-name $FUNC --region $AWS_REGION \
            --query 'Configuration.State' --output text 2>/dev/null)
        
        if [ "$STATE" = "Active" ]; then
            echo -e "  ${GREEN}●${NC} $FUNC - Active"
            ((LAMBDA_HEALTHY++))
        else
            echo -e "  ${YELLOW}●${NC} $FUNC - $STATE"
        fi
    else
        echo -e "  ${RED}●${NC} $FUNC - Not Found"
    fi
done
echo ""

# DynamoDB Status
echo -e "${BLUE}DynamoDB Tables:${NC}"
DB_HEALTHY=0
DB_TOTAL=0

for TABLE in "$USERS_TABLE" "$PROGRESS_TABLE" "$LESSON_CACHE_TABLE" "$SESSIONS_TABLE"; do
    ((DB_TOTAL++))
    TABLE_NAME=$(basename "$TABLE")
    
    if [ -z "$TABLE" ]; then
        echo -e "  ${YELLOW}●${NC} $TABLE_NAME - Not Configured"
        continue
    fi
    
    if aws dynamodb describe-table --table-name $TABLE --region $AWS_REGION > /dev/null 2>&1; then
        STATUS=$(aws dynamodb describe-table --table-name $TABLE --region $AWS_REGION \
            --query 'Table.TableStatus' --output text 2>/dev/null)
        
        if [ "$STATUS" = "ACTIVE" ]; then
            echo -e "  ${GREEN}●${NC} $TABLE_NAME - Active"
            ((DB_HEALTHY++))
        else
            echo -e "  ${YELLOW}●${NC} $TABLE_NAME - $STATUS"
        fi
    else
        echo -e "  ${RED}●${NC} $TABLE_NAME - Not Found"
    fi
done
echo ""

# Overall Health
TOTAL_RESOURCES=$((LAMBDA_TOTAL + DB_TOTAL))
HEALTHY_RESOURCES=$((LAMBDA_HEALTHY + DB_HEALTHY))
HEALTH_PERCENT=$((HEALTHY_RESOURCES * 100 / TOTAL_RESOURCES))

echo -e "${BLUE}Overall Health:${NC}"
if [ $HEALTH_PERCENT -eq 100 ]; then
    echo -e "  ${GREEN}✅ All Systems Operational${NC} ($HEALTHY_RESOURCES/$TOTAL_RESOURCES resources healthy)"
elif [ $HEALTH_PERCENT -ge 75 ]; then
    echo -e "  ${YELLOW}⚠️  Mostly Operational${NC} ($HEALTHY_RESOURCES/$TOTAL_RESOURCES resources healthy)"
else
    echo -e "  ${RED}❌ System Degraded${NC} ($HEALTHY_RESOURCES/$TOTAL_RESOURCES resources healthy)"
fi
echo ""

# ============================================================================
# SECTION 2: Usage Statistics (Last 24 Hours)
# ============================================================================
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ 📈 USAGE STATISTICS (Last 24 Hours)                                   ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Lambda Invocations
echo -e "${BLUE}Lambda Invocations:${NC}"

START_TIME=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S)
END_TIME=$(date -u +%Y-%m-%dT%H:%M:%S)

for FUNC in CodeLearn-Lesson CodeLearn-Validation CodeLearn-User CodeLearn-Auth; do
    INVOCATIONS=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/Lambda \
        --metric-name Invocations \
        --dimensions Name=FunctionName,Value=$FUNC \
        --start-time $START_TIME \
        --end-time $END_TIME \
        --period 86400 \
        --statistics Sum \
        --region $AWS_REGION \
        --query 'Datapoints[0].Sum' \
        --output text 2>/dev/null)
    
    if [ "$INVOCATIONS" = "None" ] || [ -z "$INVOCATIONS" ]; then
        INVOCATIONS="0"
    fi
    
    # Get errors
    ERRORS=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/Lambda \
        --metric-name Errors \
        --dimensions Name=FunctionName,Value=$FUNC \
        --start-time $START_TIME \
        --end-time $END_TIME \
        --period 86400 \
        --statistics Sum \
        --region $AWS_REGION \
        --query 'Datapoints[0].Sum' \
        --output text 2>/dev/null)
    
    if [ "$ERRORS" = "None" ] || [ -z "$ERRORS" ]; then
        ERRORS="0"
    fi
    
    # Format with commas
    INVOCATIONS_FORMATTED=$(printf "%'d" ${INVOCATIONS%.*})
    
    if [ "${ERRORS%.*}" -gt 0 ]; then
        echo -e "  ${YELLOW}$FUNC:${NC} $INVOCATIONS_FORMATTED invocations (${ERRORS%.*} errors)"
    else
        echo -e "  $FUNC: $INVOCATIONS_FORMATTED invocations"
    fi
done
echo ""

# Database Activity
echo -e "${BLUE}Database Activity:${NC}"

if [ -n "$USERS_TABLE" ]; then
    USER_COUNT=$(aws dynamodb describe-table --table-name $USERS_TABLE --region $AWS_REGION \
        --query 'Table.ItemCount' --output text 2>/dev/null)
    echo -e "  Total Users: ${USER_COUNT:-0}"
fi

if [ -n "$PROGRESS_TABLE" ]; then
    LESSONS_COMPLETED=$(aws dynamodb scan \
        --table-name $PROGRESS_TABLE \
        --filter-expression "completed = :true" \
        --expression-attribute-values '{":true":{"BOOL":true}}' \
        --select COUNT \
        --region $AWS_REGION \
        --query 'Count' \
        --output text 2>/dev/null)
    echo -e "  Lessons Completed: ${LESSONS_COMPLETED:-0}"
fi

if [ -n "$LESSON_CACHE_TABLE" ]; then
    CACHED_LESSONS=$(aws dynamodb describe-table --table-name $LESSON_CACHE_TABLE --region $AWS_REGION \
        --query 'Table.ItemCount' --output text 2>/dev/null)
    echo -e "  Cached Lessons: ${CACHED_LESSONS:-0}"
fi
echo ""

# ============================================================================
# SECTION 3: Performance Metrics
# ============================================================================
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ ⚡ PERFORMANCE METRICS                                                 ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}Lambda Performance (24h avg):${NC}"

for FUNC in CodeLearn-Lesson CodeLearn-Validation; do
    # Average Duration
    AVG_DURATION=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/Lambda \
        --metric-name Duration \
        --dimensions Name=FunctionName,Value=$FUNC \
        --start-time $START_TIME \
        --end-time $END_TIME \
        --period 86400 \
        --statistics Average \
        --region $AWS_REGION \
        --query 'Datapoints[0].Average' \
        --output text 2>/dev/null)
    
    if [ "$AVG_DURATION" != "None" ] && [ -n "$AVG_DURATION" ]; then
        AVG_MS=$(printf "%.0f" $AVG_DURATION)
        
        # Color based on performance
        if [ $AVG_MS -lt 1000 ]; then
            COLOR=$GREEN
        elif [ $AVG_MS -lt 3000 ]; then
            COLOR=$YELLOW
        else
            COLOR=$RED
        fi
        
        echo -e "  ${COLOR}$FUNC:${NC} ${AVG_MS}ms average"
    else
        echo -e "  $FUNC: No data"
    fi
done
echo ""

# Cache Hit Rate
if [ -n "$LESSON_CACHE_TABLE" ]; then
    echo -e "${BLUE}Cache Performance:${NC}"
    
    TOTAL_CACHED=$(aws dynamodb scan \
        --table-name $LESSON_CACHE_TABLE \
        --select COUNT \
        --region $AWS_REGION \
        --query 'Count' \
        --output text 2>/dev/null)
    
    HIGH_USE_CACHE=$(aws dynamodb scan \
        --table-name $LESSON_CACHE_TABLE \
        --filter-expression "hitCount > :hits" \
        --expression-attribute-values '{":hits":{"N":"5"}}' \
        --select COUNT \
        --region $AWS_REGION \
        --query 'Count' \
        --output text 2>/dev/null)
    
    if [ -n "$TOTAL_CACHED" ] && [ "$TOTAL_CACHED" != "0" ]; then
        UTILIZATION=$((HIGH_USE_CACHE * 100 / TOTAL_CACHED))
        
        echo -e "  Total Cached: $TOTAL_CACHED lessons"
        echo -e "  Well-Used: $HIGH_USE_CACHE lessons (${UTILIZATION}%)"
        
        if [ $UTILIZATION -ge 70 ]; then
            echo -e "  ${GREEN}Status: Excellent cache utilization${NC}"
        elif [ $UTILIZATION -ge 40 ]; then
            echo -e "  ${YELLOW}Status: Good cache utilization${NC}"
        else
            echo -e "  ${RED}Status: Low cache utilization - consider static lessons${NC}"
        fi
    else
        echo -e "  ${YELLOW}No cached lessons yet${NC}"
    fi
    echo ""
fi

# ============================================================================
# SECTION 4: Cost Summary
# ============================================================================
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ 💰 COST SUMMARY                                                       ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Yesterday's cost
YESTERDAY=$(date -u -d '1 day ago' +%Y-%m-%d)
TODAY=$(date -u +%Y-%m-%d)

YESTERDAY_COST=$(aws ce get-cost-and-usage \
    --time-period Start=$YESTERDAY,End=$TODAY \
    --granularity DAILY \
    --metrics UnblendedCost \
    --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
    --output text 2>/dev/null)

if [ -n "$YESTERDAY_COST" ] && [ "$YESTERDAY_COST" != "None" ]; then
    YESTERDAY_ROUNDED=$(printf "%.2f" $YESTERDAY_COST)
    MONTHLY_PROJECTION=$(echo "$YESTERDAY_COST * 30" | bc)
    MONTHLY_ROUNDED=$(printf "%.2f" $MONTHLY_PROJECTION)
    
    echo -e "${BLUE}Current Spending:${NC}"
    echo -e "  Yesterday: \$$YESTERDAY_ROUNDED"
    echo -e "  Monthly Projection: \$$MONTHLY_ROUNDED"
    echo ""
    
    # Budget status
    echo -e "${BLUE}Budget Status:${NC}"
    BUDGET=25.00
    REMAINING=$(echo "$BUDGET - $MONTHLY_PROJECTION" | bc)
    PERCENT_USED=$(echo "scale=1; $MONTHLY_PROJECTION / $BUDGET * 100" | bc)
    
    if (( $(echo "$MONTHLY_PROJECTION <= $BUDGET" | bc -l) )); then
        echo -e "  ${GREEN}✅ Under Budget${NC}"
        echo -e "  Budget: \$$BUDGET/month"
        echo -e "  Remaining: \$$REMAINING (~${PERCENT_USED}% used)"
    else
        echo -e "  ${RED}⚠️  Over Budget!${NC}"
        echo -e "  Budget: \$$BUDGET/month"
        echo -e "  Over by: \$$REMAINING (~${PERCENT_USED}% used)"
    fi
    
    # Cost breakdown by service (last 7 days)
    echo ""
    echo -e "${BLUE}Top Services (Last 7 days):${NC}"
    
    WEEK_START=$(date -u -d '7 days ago' +%Y-%m-%d)
    
    aws ce get-cost-and-usage \
        --time-period Start=$WEEK_START,End=$TODAY \
        --granularity DAILY \
        --metrics UnblendedCost \
        --group-by Type=SERVICE \
        --query 'ResultsByTime[*].Groups[?Metrics.UnblendedCost.Amount>`0.01`].[Keys[0],Metrics.UnblendedCost.Amount]' \
        --output text 2>/dev/null | \
        awk '{service=$1; cost+=$2} END {for (s in cost) if (cost[s] > 0.01) printf "  %-30s $%.2f\n", s, cost[s]}' | \
        sort -k2 -rn | head -5
    
else
    echo -e "${YELLOW}Cost data not available yet (may take 24 hours)${NC}"
fi
echo ""

# ============================================================================
# SECTION 5: Recent Activity
# ============================================================================
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ 🔔 RECENT ACTIVITY                                                    ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}Recent Errors (Last Hour):${NC}"
ERROR_COUNT=0

for FUNC in CodeLearn-Lesson CodeLearn-Validation CodeLearn-User; do
    RECENT_ERRORS=$(aws logs filter-log-events \
        --log-group-name /aws/lambda/$FUNC \
        --start-time $(($(date +%s) - 3600))000 \
        --filter-pattern "ERROR" \
        --query 'events | length(@)' \
        --output text 2>/dev/null)
    
    if [ -n "$RECENT_ERRORS" ] && [ "$RECENT_ERRORS" != "0" ] && [ "$RECENT_ERRORS" != "None" ]; then
        echo -e "  ${RED}⚠️  $FUNC: $RECENT_ERRORS errors${NC}"
        ((ERROR_COUNT += RECENT_ERRORS))
    fi
done

if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "  ${GREEN}✅ No errors in the last hour${NC}"
fi
echo ""

# Recent deployments
echo -e "${BLUE}Recent Deployments:${NC}"

if [ -n "$API_ID" ]; then
    LAST_DEPLOYMENT=$(aws apigateway get-deployments \
        --rest-api-id $API_ID \
        --region $AWS_REGION \
        --query 'items[0].createdDate' \
        --output text 2>/dev/null)
    
    if [ -n "$LAST_DEPLOYMENT" ] && [ "$LAST_DEPLOYMENT" != "None" ]; then
        echo -e "  API Gateway: $LAST_DEPLOYMENT"
    fi
fi

# Most recent Lambda update
LATEST_LAMBDA=""
LATEST_TIME=""

for FUNC in CodeLearn-Lesson CodeLearn-Validation CodeLearn-User CodeLearn-Auth; do
    MODIFIED=$(aws lambda get-function --function-name $FUNC --region $AWS_REGION \
        --query 'Configuration.LastModified' --output text 2>/dev/null)
    
    if [ -n "$MODIFIED" ]; then
        if [ -z "$LATEST_TIME" ] || [[ "$MODIFIED" > "$LATEST_TIME" ]]; then
            LATEST_TIME=$MODIFIED
            LATEST_LAMBDA=$FUNC
        fi
    fi
done

if [ -n "$LATEST_LAMBDA" ]; then
    echo -e "  Lambda ($LATEST_LAMBDA): $LATEST_TIME"
fi
echo ""

# ============================================================================
# SECTION 6: Quick Actions
# ============================================================================
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ 🚀 QUICK ACTIONS                                                      ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "  ${BLUE}Common Commands:${NC}"
echo "    ./dev.sh deploy         Deploy changes"
echo "    ./dev.sh test          Run tests"
echo "    ./dev.sh logs          View live logs"
echo "    ./dev.sh cost          Detailed cost check"
echo ""
echo "  ${BLUE}Maintenance:${NC}"
echo "    ./tools/health-check.sh        Full health check"
echo "    ./quick-start-scripts.sh       Interactive menu"
echo ""

# ============================================================================
# Footer
# ============================================================================
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}Dashboard refreshed at $(date '+%H:%M:%S') | Press Ctrl+C to exit${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

# Auto-refresh option (commented out by default)
# Uncomment to enable auto-refresh every 60 seconds
# sleep 60
# exec $0