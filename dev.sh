#!/bin/bash
# Development Workflow Script
# Quick commands for daily development tasks

source config/dev-config.sh

# Safety check for deployment
check_deployment_target() {
    if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$AWS_REGION" ]; then
        echo -e "${RED}❌ Configuration not loaded${NC}"
        echo "Run: source config/dev-config.sh"
        return 1
    fi
    
    echo -e "${YELLOW}Deployment Target:${NC}"
    echo "  Account: $AWS_ACCOUNT_ID"
    echo "  Region: $AWS_REGION"
    echo ""
}

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_usage() {
    echo "Development Workflow Commands"
    echo "=============================="
    echo ""
    echo "QUICK DEPLOY:"
    echo "  ./dev.sh deploy           - Deploy everything"
    echo "  ./dev.sh deploy-fe        - Deploy frontend only"
    echo "  ./dev.sh deploy-lambda    - Deploy all Lambdas"
    echo "  ./dev.sh deploy-lesson    - Deploy lesson Lambda only"
    echo ""
    echo "TESTING:"
    echo "  ./dev.sh test             - Run all tests"
    echo "  ./dev.sh test-api         - Test API endpoints"
    echo "  ./dev.sh test-lesson      - Test lesson generation"
    echo "  ./dev.sh test-validate    - Test code validation"
    echo ""
    echo "MONITORING:"
    echo "  ./dev.sh logs             - View live logs (lesson Lambda)"
    echo "  ./dev.sh logs-validation  - View validation Lambda logs"
    echo "  ./dev.sh errors           - Show recent errors"
    echo "  ./dev.sh stats            - Show Lambda statistics"
    echo ""
    echo "DEVELOPMENT:"
    echo "  ./dev.sh new-lesson       - Create new static lesson"
    echo "  ./dev.sh validate-lessons - Validate all lessons"
    echo "  ./dev.sh sync-lessons     - Upload lessons to S3"
    echo ""
    echo "UTILITIES:"
    echo "  ./dev.sh cost             - Check current costs"
    echo "  ./dev.sh urls             - Show all URLs"
    echo "  ./dev.sh backup           - Quick backup"
    echo "  ./dev.sh clean            - Clean temp files"
    echo ""
    echo "DEBUGGING:"
    echo "  ./dev.sh invoke-lesson    - Test lesson Lambda locally"
    echo "  ./dev.sh invoke-validate  - Test validation Lambda locally"
    echo "  ./dev.sh check-config     - Verify configuration"
    echo ""
    echo "Example: ./dev.sh deploy-lesson"
}

# Quick deploy functions
deploy() {
    echo -e "${BLUE}Deploying all components...${NC}"
    
    # Verify configuration is loaded
    if [ -z "$STATIC_LESSONS_BUCKET" ] || [ -z "$FRONTEND_BUCKET" ]; then
        echo -e "${RED}❌ Configuration not loaded!${NC}"
        echo "Run: source config/dev-config.sh"
        return 1
    fi
    
    # Show where we're deploying to
    echo "Deploying to:"
    echo "  Region: $AWS_REGION"
    echo "  Account: $AWS_ACCOUNT_ID"
    echo "  Static Lessons: s3://$STATIC_LESSONS_BUCKET"
    echo "  Frontend: s3://$FRONTEND_BUCKET"
    echo ""
    read -p "Continue? (y/n): " confirm
    
    if [ "$confirm" != "y" ]; then
        echo "Cancelled"
        return 0
    fi
    
    ./tools/update-lambda.sh all
    aws s3 sync static_lessons/ s3://$STATIC_LESSONS_BUCKET/static/ --delete --quiet
    aws s3 sync frontend/ s3://$FRONTEND_BUCKET/ --delete --quiet
    aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod > /dev/null
    echo -e "${GREEN}✅ Deploy complete${NC}"
}

deploy_frontend() {
    echo -e "${BLUE}Deploying frontend...${NC}"
    ./tools/configure-frontend.sh > /dev/null
    aws s3 sync frontend/ s3://$FRONTEND_BUCKET/ --delete --quiet
    echo -e "${GREEN}✅ Frontend deployed${NC}"
    echo "URL: $FRONTEND_URL"
}

deploy_lambda() {
    echo -e "${BLUE}Deploying all Lambda functions...${NC}"
    ./tools/update-lambda.sh all
}

deploy_lesson() {
    echo -e "${BLUE}Deploying lesson Lambda...${NC}"
    cd lesson_lambda
    rm -f function.zip
    pip3 install -r requirements.txt -t . -q
    zip -r function.zip . -q -x "*.pyc" -x "__pycache__/*"
    aws lambda update-function-code \
        --function-name CodeLearn-Lesson \
        --zip-file fileb://function.zip \
        --region $AWS_REGION > /dev/null
    cd ..
    echo -e "${GREEN}✅ Lesson Lambda deployed${NC}"
}

# Testing functions
test_all() {
    echo -e "${BLUE}Running all tests...${NC}"
    ./tools/e2e-test.sh
}

test_api() {
    echo -e "${BLUE}Testing API endpoints...${NC}"
    ./tools/test-api.sh
}

test_lesson() {
    echo -e "${BLUE}Testing lesson generation...${NC}"
    curl -s -X POST "${API_ENDPOINT}/api/lesson" \
        -H "Content-Type: application/json" \
        -d '{"language":"python","level":"beginner","topic":"variables and data types"}' \
        | python3 -m json.tool | head -30
}

test_validate() {
    echo -e "${BLUE}Testing code validation...${NC}"
    curl -s -X POST "${API_ENDPOINT}/api/validate" \
        -H "Content-Type: application/json" \
        -d '{
            "code": "x = 5\ny = 10\nz = x + y",
            "tests": ["def test_add():\n    assert z == 15"],
            "language": "python",
            "lessonId": "test"
        }' | python3 -m json.tool
}

# Monitoring functions
logs() {
    echo -e "${BLUE}Tailing lesson Lambda logs (Ctrl+C to stop)...${NC}"
    aws logs tail /aws/lambda/CodeLearn-Lesson --follow --format short
}

logs_validation() {
    echo -e "${BLUE}Tailing validation Lambda logs (Ctrl+C to stop)...${NC}"
    aws logs tail /aws/lambda/CodeLearn-Validation --follow --format short
}

show_errors() {
    echo -e "${BLUE}Recent errors (last 1 hour):${NC}"
    for FUNC in CodeLearn-Lesson CodeLearn-Validation CodeLearn-User; do
        echo ""
        echo "=== $FUNC ==="
        aws logs filter-log-events \
            --log-group-name /aws/lambda/$FUNC \
            --start-time $(($(date +%s) - 3600))000 \
            --filter-pattern "ERROR" \
            --query 'events[*].message' \
            --output text 2>/dev/null | head -5
    done
}

show_stats() {
    echo -e "${BLUE}Lambda statistics:${NC}"
    ./tools/lambda-stats.sh
}

# Development functions
new_lesson() {
    read -p "Language (python/java/rust): " lang
    read -p "Level (beginner/intermediate/advanced): " level
    read -p "Topic: " topic
    
    python3 tools/generate_lesson_template.py $lang $level "$topic"
    
    FILEPATH="static_lessons/${lang}/${level}/${topic// /_}.json"
    echo -e "${GREEN}Created: $FILEPATH${NC}"
    echo "Opening in editor..."
    code "$FILEPATH" 2>/dev/null || echo "Edit: $FILEPATH"
}

validate_lessons() {
    echo -e "${BLUE}Validating lessons...${NC}"
    python3 tools/validate_lessons.py
}

sync_lessons() {
    echo -e "${BLUE}Syncing lessons to S3...${NC}"
    aws s3 sync static_lessons/ s3://$STATIC_LESSONS_BUCKET/static/ --delete
    COUNT=$(aws s3 ls s3://$STATIC_LESSONS_BUCKET/static/ --recursive | wc -l)
    echo -e "${GREEN}✅ Synced $COUNT files${NC}"
}

# Utility functions
check_cost() {
    echo -e "${BLUE}Current costs:${NC}"
    ./check-costs.sh
}

show_urls() {
    echo -e "${BLUE}Platform URLs:${NC}"
    echo "Frontend: $FRONTEND_URL"
    echo "API: $API_ENDPOINT"
    echo "Cognito: https://$COGNITO_DOMAIN"
}

quick_backup() {
    echo -e "${BLUE}Creating quick backup...${NC}"
    BACKUP_DIR="quick-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p $BACKUP_DIR
    
    cp -r lesson_lambda validation_lambda user_lambda auth_lambda $BACKUP_DIR/
    cp -r frontend $BACKUP_DIR/
    cp config/dev-config.sh $BACKUP_DIR/
    
    tar -czf ${BACKUP_DIR}.tar.gz $BACKUP_DIR
    rm -rf $BACKUP_DIR
    
    echo -e "${GREEN}✅ Backup created: ${BACKUP_DIR}.tar.gz${NC}"
}

clean_temp() {
    echo -e "${BLUE}Cleaning temporary files...${NC}"
    find . -name "function.zip" -delete
    find . -name "*.pyc" -delete
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
    echo -e "${GREEN}✅ Cleaned${NC}"
}

# Debugging functions
invoke_lesson() {
    echo -e "${BLUE}Invoking lesson Lambda locally...${NC}"
    cat > /tmp/test-event.json << 'EOF'
{
  "body": "{\"language\":\"python\",\"level\":\"beginner\",\"topic\":\"variables and data types\"}"
}
EOF
    
    aws lambda invoke \
        --function-name CodeLearn-Lesson \
        --payload file:///tmp/test-event.json \
        /tmp/response.json
    
    echo ""
    cat /tmp/response.json | python3 -m json.tool | head -40
}

invoke_validate() {
    echo -e "${BLUE}Invoking validation Lambda locally...${NC}"
    cat > /tmp/test-event.json << 'EOF'
{
  "body": "{\"code\":\"x=5\\ny=10\\nz=x+y\",\"tests\":[\"def test_add():\\n    assert z==15\"],\"language\":\"python\",\"lessonId\":\"test\"}"
}
EOF
    
    aws lambda invoke \
        --function-name CodeLearn-Validation \
        --payload file:///tmp/test-event.json \
        /tmp/response.json
    
    echo ""
    cat /tmp/response.json | python3 -m json.tool
}

check_config() {
    echo -e "${BLUE}Verifying configuration...${NC}"
    echo "AWS Account: $AWS_ACCOUNT_ID"
    echo "Region: $AWS_REGION"
    echo "API ID: $API_ID"
    echo "User Pool: $USER_POOL_ID"
    echo ""
    
    echo "Checking resources..."
    
    # Check Lambda functions
    for FUNC in CodeLearn-Lesson CodeLearn-Validation CodeLearn-User; do
        if aws lambda get-function --function-name $FUNC > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $FUNC${NC}"
        else
            echo -e "${YELLOW}⚠️  $FUNC not found${NC}"
        fi
    done
    
    # Check DynamoDB tables
    for TABLE in $USERS_TABLE $PROGRESS_TABLE $LESSON_CACHE_TABLE; do
        if aws dynamodb describe-table --table-name $TABLE > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $TABLE${NC}"
        else
            echo -e "${YELLOW}⚠️  $TABLE not found${NC}"
        fi
    done
    
    # Check S3 buckets
    for BUCKET in $STATIC_LESSONS_BUCKET $FRONTEND_BUCKET; do
        if aws s3 ls s3://$BUCKET > /dev/null 2>&1; then
            echo -e "${GREEN}✅ s3://$BUCKET${NC}"
        else
            echo -e "${YELLOW}⚠️  s3://$BUCKET not found${NC}"
        fi
    done
}

# Main command router
case "$1" in
    # Deploy commands
    deploy) deploy ;;
    deploy-fe) deploy_frontend ;;
    deploy-lambda) deploy_lambda ;;
    deploy-lesson) deploy_lesson ;;
    
    # Test commands
    test) test_all ;;
    test-api) test_api ;;
    test-lesson) test_lesson ;;
    test-validate) test_validate ;;
    
    # Monitoring commands
    logs) logs ;;
    logs-validation) logs_validation ;;
    errors) show_errors ;;
    stats) show_stats ;;
    
    # Development commands
    new-lesson) new_lesson ;;
    validate-lessons) validate_lessons ;;
    sync-lessons) sync_lessons ;;
    
    # Utility commands
    cost) check_cost ;;
    urls) show_urls ;;
    backup) quick_backup ;;
    clean) clean_temp ;;
    
    # Debugging commands
    invoke-lesson) invoke_lesson ;;
    invoke-validate) invoke_validate ;;
    check-config) check_config ;;
    
    # Default
    *) print_usage ;;
esac
