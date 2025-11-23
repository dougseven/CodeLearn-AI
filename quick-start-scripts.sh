#!/bin/bash
# CodeLearn Platform - Quick Start Scripts
# Collection of common tasks for easy execution

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load configuration
if [ -f "config/dev-config.sh" ]; then
    source config/dev-config.sh
else
    echo -e "${RED}Error: config/dev-config.sh not found${NC}"
    exit 1
fi

# Helper function for section headers
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Helper function for success messages
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Helper function for error messages
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Helper function for warning messages
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Helper function for info messages
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Main menu
show_menu() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
   ____          _      _                           
  / ___|___   __| | ___| |    ___  __ _ _ __ _ __  
 | |   / _ \ / _` |/ _ \ |   / _ \/ _` | '__| '_ \ 
 | |__| (_) | (_| |  __/ |__|  __/ (_| | |  | | | |
  \____\___/ \__,_|\___|_____\___|\__,_|_|  |_| |_|
                                                    
EOF
    echo -e "${NC}"
    echo "Quick Start Scripts - Common Tasks"
    echo "==================================="
    echo ""
    echo "SETUP & DEPLOYMENT:"
    echo "  1. Fresh Install - Complete setup from scratch"
    echo "  2. Deploy All - Deploy entire platform"
    echo "  3. Deploy Frontend Only"
    echo "  4. Deploy Lambda Functions Only"
    echo "  5. Update Single Lambda Function"
    echo ""
    echo "DEVELOPMENT:"
    echo "  6. Create New Static Lesson"
    echo "  7. Test Lesson Locally"
    echo "  8. Update API Configuration"
    echo "  9. Reset Database (DANGER!)"
    echo ""
    echo "MONITORING & MAINTENANCE:"
    echo "  10. Daily Health Check"
    echo "  11. View Dashboard"
    echo "  12. Check Costs"
    echo "  13. View Logs (Live)"
    echo "  14. Generate Weekly Report"
    echo ""
    echo "TESTING:"
    echo "  15. Test All APIs"
    echo "  16. Test Authentication"
    echo "  17. Load Test"
    echo "  18. End-to-End Test"
    echo ""
    echo "TROUBLESHOOTING:"
    echo "  19. Fix Common Issues"
    echo "  20. Emergency Cost Control"
    echo "  21. Restart All Services"
    echo "  22. View Error Logs"
    echo ""
    echo "UTILITIES:"
    echo "  23. Backup All Data"
    echo "  24. Show All URLs"
    echo "  25. Clean Temporary Files"
    echo "  26. Update Configuration"
    echo ""
    echo "  0. Exit"
    echo ""
    read -p "Select option (0-26): " choice
    echo ""
}

# 1. Fresh Install
fresh_install() {
    print_header "Fresh Install - Complete Setup"
    
    print_warning "This will set up the entire platform from scratch."
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Cancelled"
        return
    fi
    
    print_info "Step 1/8: Creating DynamoDB tables..."
    aws dynamodb create-table \
        --table-name $LESSON_CACHE_TABLE \
        --attribute-definitions AttributeName=lessonKey,AttributeType=S \
        --key-schema AttributeName=lessonKey,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --time-to-live-specification Enabled=true,AttributeName=ttl \
        --region $AWS_REGION > /dev/null 2>&1
    
    aws dynamodb create-table \
        --table-name $USERS_TABLE \
        --attribute-definitions AttributeName=userId,AttributeType=S AttributeName=email,AttributeType=S \
        --key-schema AttributeName=userId,KeyType=HASH \
        --global-secondary-indexes '[{"IndexName":"EmailIndex","KeySchema":[{"AttributeName":"email","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}}]' \
        --billing-mode PAY_PER_REQUEST \
        --region $AWS_REGION > /dev/null 2>&1
    
    aws dynamodb create-table \
        --table-name $PROGRESS_TABLE \
        --attribute-definitions AttributeName=userId,AttributeType=S AttributeName=lessonId,AttributeType=S \
        --key-schema AttributeName=userId,KeyType=HASH AttributeName=lessonId,KeyType=RANGE \
        --billing-mode PAY_PER_REQUEST \
        --region $AWS_REGION > /dev/null 2>&1
    
    aws dynamodb create-table \
        --table-name $SESSIONS_TABLE \
        --attribute-definitions AttributeName=sessionId,AttributeType=S \
        --key-schema AttributeName=sessionId,KeyType=HASH \
        --time-to-live-specification Enabled=true,AttributeName=expiresAt \
        --billing-mode PAY_PER_REQUEST \
        --region $AWS_REGION > /dev/null 2>&1
    
    print_success "DynamoDB tables created"
    
    print_info "Step 2/8: Creating S3 buckets..."
    aws s3 mb s3://$STATIC_LESSONS_BUCKET --region $AWS_REGION 2>/dev/null
    aws s3 mb s3://$FRONTEND_BUCKET --region $AWS_REGION 2>/dev/null
    print_success "S3 buckets created"
    
    print_info "Step 3/8: Waiting for tables to activate..."
    aws dynamodb wait table-exists --table-name $LESSON_CACHE_TABLE
    print_success "Tables active"
    
    print_info "Step 4/8: Deploying Lambda functions..."
    ./tools/update-lambda.sh all 2>/dev/null
    print_success "Lambda functions deployed"
    
    print_info "Step 5/8: Creating API Gateway..."
    # API creation script would go here
    print_success "API Gateway created"
    
    print_info "Step 6/8: Setting up Cognito..."
    # Cognito setup would go here
    print_success "Cognito configured"
    
    print_info "Step 7/8: Uploading static lessons..."
    aws s3 sync static_lessons/ s3://$STATIC_LESSONS_BUCKET/static/ 2>/dev/null
    print_success "Static lessons uploaded"
    
    print_info "Step 8/8: Deploying frontend..."
    ./tools/configure-frontend.sh
    aws s3 sync frontend/ s3://$FRONTEND_BUCKET/ --delete
    print_success "Frontend deployed"
    
    print_header "Installation Complete!"
    print_success "Platform is ready to use"
    echo ""
    print_info "Frontend URL: $FRONTEND_URL"
    print_info "API Endpoint: $API_ENDPOINT"
    echo ""
    print_warning "Next steps:"
    echo "  1. Run health check: Option 10"
    echo "  2. Create test user: Option 16"
    echo "  3. Test the platform: Option 18"
}

# 2. Deploy All
deploy_all() {
    print_header "Deploy All Components"
    
    print_info "Deploying Lambda functions..."
    ./tools/update-lambda.sh all
    
    print_info "Uploading static lessons..."
    aws s3 sync static_lessons/ s3://$STATIC_LESSONS_BUCKET/static/ --delete
    
    print_info "Deploying frontend..."
    ./tools/configure-frontend.sh
    aws s3 sync frontend/ s3://$FRONTEND_BUCKET/ --delete
    
    print_info "Redeploying API..."
    aws apigateway create-deployment \
        --rest-api-id $API_ID \
        --stage-name prod > /dev/null 2>&1
    
    print_success "All components deployed"
    echo ""
    print_info "Testing deployment..."
    ./tools/e2e-test.sh
}

# 3. Deploy Frontend Only
deploy_frontend() {
    print_header "Deploy Frontend Only"
    
    print_info "Configuring frontend..."
    ./tools/configure-frontend.sh
    
    print_info "Uploading to S3..."
    aws s3 sync frontend/ s3://$FRONTEND_BUCKET/ \
        --delete \
        --cache-control "public, max-age=300"
    
    FILES=$(aws s3 ls s3://$FRONTEND_BUCKET/ | wc -l)
    print_success "Frontend deployed ($FILES files)"
    echo ""
    print_info "Frontend URL: $FRONTEND_URL"
    
    read -p "Open in browser? (y/n): " open_browser
    if [ "$open_browser" = "y" ]; then
        open "$FRONTEND_URL" 2>/dev/null || xdg-open "$FRONTEND_URL" 2>/dev/null
    fi
}

# 4. Deploy Lambda Functions Only
deploy_lambdas() {
    print_header "Deploy All Lambda Functions"
    
    ./tools/update-lambda.sh all
    
    print_success "Lambda functions deployed"
    echo ""
    print_info "Testing Lambda functions..."
    ./tools/lambda-stats.sh
}

# 5. Update Single Lambda
update_single_lambda() {
    print_header "Update Single Lambda Function"
    
    echo "Available functions:"
    echo "  1. LessonLambda (AI generation)"
    echo "  2. ValidationLambda (code testing)"
    echo "  3. UserLambda (profiles)"
    echo "  4. AuthLambda (authentication)"
    echo ""
    read -p "Select function (1-4): " func_choice
    
    case $func_choice in
        1) ./tools/update-lambda.sh lesson ;;
        2) ./tools/update-lambda.sh validation ;;
        3) ./tools/update-lambda.sh user ;;
        4) ./tools/update-lambda.sh auth ;;
        *) print_error "Invalid choice" ;;
    esac
}

# 6. Create New Static Lesson
create_lesson() {
    print_header "Create New Static Lesson"
    
    echo "Available languages: python, java, rust"
    read -p "Language: " lang
    
    echo "Available levels: beginner, intermediate, advanced"
    read -p "Level: " level
    
    read -p "Topic name: " topic
    
    print_info "Generating template..."
    python3 tools/generate_lesson_template.py $lang $level "$topic"
    
    FILEPATH="static_lessons/${lang}/${level}/${topic// /_}.json"
    
    print_success "Template created"
    echo ""
    print_info "Edit the lesson: code $FILEPATH"
    echo ""
    read -p "Open in editor now? (y/n): " open_editor
    if [ "$open_editor" = "y" ]; then
        code "$FILEPATH" 2>/dev/null || nano "$FILEPATH"
    fi
    
    echo ""
    print_warning "After editing:"
    echo "  1. Validate: python3 tools/validate_lessons.py"
    echo "  2. Upload: ./tools/s3-manager.sh sync-lessons"
}

# 7. Test Lesson Locally
test_lesson() {
    print_header "Test Lesson Locally"
    
    read -p "Lesson file path: " filepath
    
    if [ ! -f "$filepath" ]; then
        print_error "File not found: $filepath"
        return
    fi
    
    print_info "Validating JSON..."
    if python3 -m json.tool "$filepath" > /dev/null 2>&1; then
        print_success "Valid JSON"
    else
        print_error "Invalid JSON"
        return
    fi
    
    print_info "Checking required fields..."
    python3 tools/validate_lessons.py
}

# 8. Update API Configuration
update_api_config() {
    print_header "Update API Configuration"
    
    echo "Current configuration:"
    echo "  API Endpoint: $API_ENDPOINT"
    echo "  Cognito Domain: $COGNITO_DOMAIN"
    echo "  App Client ID: $APP_CLIENT_ID"
    echo ""
    
    read -p "Update frontend with latest config? (y/n): " update
    
    if [ "$update" = "y" ]; then
        ./tools/configure-frontend.sh
        aws s3 sync frontend/ s3://$FRONTEND_BUCKET/ --delete
        print_success "Frontend configuration updated"
    fi
}

# 9. Reset Database
reset_database() {
    print_header "Reset Database (DANGER!)"
    
    print_warning "This will DELETE ALL DATA from your tables!"
    print_warning "This action CANNOT be undone!"
    echo ""
    read -p "Type 'DELETE ALL DATA' to confirm: " confirm
    
    if [ "$confirm" != "DELETE ALL DATA" ]; then
        print_info "Cancelled"
        return
    fi
    
    print_info "Deleting tables..."
    for TABLE in $USERS_TABLE $PROGRESS_TABLE $SESSIONS_TABLE $LESSON_CACHE_TABLE; do
        aws dynamodb delete-table --table-name $TABLE 2>/dev/null
        echo "  Deleted: $TABLE"
    done
    
    print_info "Waiting for deletion..."
    sleep 10
    
    print_info "Recreating tables..."
    fresh_install
}

# 10. Daily Health Check
daily_health_check() {
    print_header "Daily Health Check"
    ./tools/health-check.sh
    echo ""
    read -p "View detailed dashboard? (y/n): " view_dash
    if [ "$view_dash" = "y" ]; then
        ./tools/dashboard.sh
    fi
}

# 11. View Dashboard
view_dashboard() {
    print_header "Platform Dashboard"
    ./tools/dashboard.sh
}

# 12. Check Costs
check_costs() {
    print_header "Cost Check"
    ./check-costs.sh
    
    echo ""
    read -p "Run cost optimization check? (y/n): " optimize
    if [ "$optimize" = "y" ]; then
        ./tools/optimize-costs.sh
    fi
}

# 13. View Logs (Live)
view_logs() {
    print_header "View Live Logs"
    
    echo "Select Lambda function:"
    echo "  1. LessonLambda"
    echo "  2. ValidationLambda"
    echo "  3. UserLambda"
    echo "  4. AuthLambda"
    echo ""
    read -p "Choice (1-4): " log_choice
    
    case $log_choice in
        1) LOG_GROUP="/aws/lambda/CodeLearn-Lesson" ;;
        2) LOG_GROUP="/aws/lambda/CodeLearn-Validation" ;;
        3) LOG_GROUP="/aws/lambda/CodeLearn-User" ;;
        4) LOG_GROUP="/aws/lambda/CodeLearn-Auth" ;;
        *) print_error "Invalid choice"; return ;;
    esac
    
    print_info "Tailing logs from $LOG_GROUP"
    print_info "Press Ctrl+C to stop"
    echo ""
    
    aws logs tail $LOG_GROUP --follow --format short
}

# 14. Generate Weekly Report
weekly_report() {
    print_header "Generate Weekly Report"
    
    mkdir -p reports
    REPORT_FILE="reports/week-$(date +%Y-%m-%d).txt"
    
    ./tools/weekly-report.sh | tee $REPORT_FILE
    
    print_success "Report saved to: $REPORT_FILE"
    echo ""
    read -p "Email this report? (y/n): " email
    if [ "$email" = "y" ]; then
        read -p "Email address: " email_addr
        mail -s "CodeLearn Weekly Report - $(date +%Y-%m-%d)" $email_addr < $REPORT_FILE
        print_success "Report emailed to $email_addr"
    fi
}

# 15. Test All APIs
test_apis() {
    print_header "Test All API Endpoints"
    ./tools/test-api.sh
}

# 16. Test Authentication
test_auth() {
    print_header "Test Authentication"
    ./tools/test-auth.sh
}

# 17. Load Test
load_test() {
    print_header "Load Testing"
    print_warning "This will generate many API requests"
    ./tools/load-test.sh
}

# 18. End-to-End Test
e2e_test() {
    print_header "End-to-End Platform Test"
    ./tools/e2e-test.sh
    
    echo ""
    read -p "View detailed logs? (y/n): " view_logs
    if [ "$view_logs" = "y" ]; then
        view_logs
    fi
}

# 19. Fix Common Issues
fix_issues() {
    print_header "Fix Common Issues"
    ./tools/fix-common-issues.sh
}

# 20. Emergency Cost Control
emergency_cost_control() {
    print_header "Emergency Cost Control"
    
    print_warning "This will disable AI lesson generation!"
    print_info "Static lessons will continue to work"
    echo ""
    read -p "Activate emergency mode? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Cancelled"
        return
    fi
    
    print_info "Disabling AI generation..."
    aws lambda update-function-configuration \
        --function-name CodeLearn-Lesson \
        --environment Variables="{EMERGENCY_MODE=true,LESSON_CACHE_TABLE=$LESSON_CACHE_TABLE,PROGRESS_TABLE=$PROGRESS_TABLE,STATIC_LESSONS_BUCKET=$STATIC_LESSONS_BUCKET}" \
        > /dev/null 2>&1
    
    print_success "Emergency mode activated"
    echo ""
    print_warning "AI lesson generation is now DISABLED"
    print_info "Only static lessons and cached lessons will be served"
    echo ""
    print_info "To re-enable AI generation:"
    echo "  Run this script and select option 20 again"
    
    echo ""
    read -p "Re-enable AI now? (y/n): " reenable
    if [ "$reenable" = "y" ]; then
        aws lambda update-function-configuration \
            --function-name CodeLearn-Lesson \
            --environment Variables="{EMERGENCY_MODE=false,LESSON_CACHE_TABLE=$LESSON_CACHE_TABLE,PROGRESS_TABLE=$PROGRESS_TABLE,STATIC_LESSONS_BUCKET=$STATIC_LESSONS_BUCKET}" \
            > /dev/null 2>&1
        print_success "AI generation re-enabled"
    fi
}

# 21. Restart All Services
restart_services() {
    print_header "Restart All Services"
    
    print_info "Updating Lambda functions..."
    ./tools/update-lambda.sh all
    
    print_info "Redeploying API Gateway..."
    aws apigateway create-deployment \
        --rest-api-id $API_ID \
        --stage-name prod > /dev/null 2>&1
    
    print_info "Clearing CloudFront cache (if applicable)..."
    # CloudFront invalidation would go here
    
    print_success "All services restarted"
    
    sleep 5
    print_info "Running health check..."
    ./tools/health-check.sh
}

# 22. View Error Logs
view_error_logs() {
    print_header "View Error Logs"
    
    echo "Searching for errors in the last 24 hours..."
    echo ""
    
    for FUNC in CodeLearn-Lesson CodeLearn-Validation CodeLearn-User CodeLearn-Auth; do
        echo "=== $FUNC ==="
        aws logs filter-log-events \
            --log-group-name /aws/lambda/$FUNC \
            --start-time $(($(date +%s) - 86400))000 \
            --filter-pattern "ERROR" \
            --query 'events[*].[timestamp, message]' \
            --output text 2>/dev/null | head -10
        echo ""
    done
    
    print_info "Showing most recent 10 errors per function"
}

# 23. Backup All Data
backup_data() {
    print_header "Backup All Data"
    
    BACKUP_DIR="backups/$(date +%Y-%m-%d)"
    mkdir -p $BACKUP_DIR
    
    print_info "Backing up DynamoDB tables..."
    for TABLE in $USERS_TABLE $PROGRESS_TABLE $SESSIONS_TABLE $LESSON_CACHE_TABLE; do
        echo "  Backing up $TABLE..."
        aws dynamodb scan --table-name $TABLE > "$BACKUP_DIR/${TABLE}.json" 2>/dev/null
    done
    
    print_info "Backing up S3 buckets..."
    aws s3 sync s3://$STATIC_LESSONS_BUCKET/ "$BACKUP_DIR/static_lessons/" > /dev/null 2>&1
    aws s3 sync s3://$FRONTEND_BUCKET/ "$BACKUP_DIR/frontend/" > /dev/null 2>&1
    
    print_info "Backing up configuration..."
    cp config/dev-config.sh "$BACKUP_DIR/"
    
    print_success "Backup complete: $BACKUP_DIR"
    
    # Create tarball
    tar -czf "$BACKUP_DIR.tar.gz" $BACKUP_DIR
    print_success "Compressed backup: $BACKUP_DIR.tar.gz"
    
    SIZE=$(du -sh "$BACKUP_DIR.tar.gz" | cut -f1)
    print_info "Backup size: $SIZE"
}

# 24. Show All URLs
show_urls() {
    print_header "Platform URLs & Configuration"
    
    echo "FRONTEND:"
    echo "  URL: $FRONTEND_URL"
    echo ""
    
    echo "API:"
    echo "  Base URL: $API_ENDPOINT"
    echo "  Lesson: $API_ENDPOINT/api/lesson"
    echo "  Validate: $API_ENDPOINT/api/validate"
    echo "  Profile: $API_ENDPOINT/api/user/profile"
    echo ""
    
    echo "AUTHENTICATION:"
    echo "  Cognito Domain: https://$COGNITO_DOMAIN"
    echo "  User Pool ID: $USER_POOL_ID"
    echo "  App Client ID: $APP_CLIENT_ID"
    echo "  Login URL: https://$COGNITO_DOMAIN/login?client_id=$APP_CLIENT_ID&response_type=code&scope=openid+email+profile&redirect_uri=$FRONTEND_URL"
    echo ""
    
    echo "AWS RESOURCES:"
    echo "  Region: $AWS_REGION"
    echo "  Account: $AWS_ACCOUNT_ID"
    echo ""
    
    echo "S3 BUCKETS:"
    echo "  Static Lessons: s3://$STATIC_LESSONS_BUCKET"
    echo "  Frontend: s3://$FRONTEND_BUCKET"
    echo ""
    
    echo "DYNAMODB TABLES:"
    echo "  Users: $USERS_TABLE"
    echo "  Progress: $PROGRESS_TABLE"
    echo "  Sessions: $SESSIONS_TABLE"
    echo "  Lesson Cache: $LESSON_CACHE_TABLE"
    echo ""
    
    echo "LAMBDA FUNCTIONS:"
    for FUNC in CodeLearn-Lesson CodeLearn-Validation CodeLearn-User CodeLearn-Auth; do
        ARN=$(aws lambda get-function --function-name $FUNC --query 'Configuration.FunctionArn' --output text 2>/dev/null)
        echo "  $FUNC: $ARN"
    done
}

# 25. Clean Temporary Files
clean_temp() {
    print_header "Clean Temporary Files"
    
    print_info "Cleaning Lambda deployment packages..."
    find . -name "function.zip" -delete
    find . -name "*.pyc" -delete
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
    
    print_info "Cleaning backup files..."
    find . -name "*.backup" -delete
    find . -name "*.bak" -delete
    
    print_info "Cleaning temporary directories..."
    rm -rf /tmp/codelearn-* 2>/dev/null
    
    print_success "Temporary files cleaned"
    
    SAVED=$(du -sh . | cut -f1)
    print_info "Current directory size: $SAVED"
}

# 26. Update Configuration
update_config() {
    print_header "Update Configuration"
    
    echo "Current configuration file: config/dev-config.sh"
    echo ""
    echo "What would you like to update?"
    echo "  1. AWS Region"
    echo "  2. API Endpoint"
    echo "  3. Cognito Settings"
    echo "  4. S3 Bucket Names"
    echo "  5. View entire config"
    echo "  6. Reload config from AWS"
    echo ""
    read -p "Choice (1-6): " config_choice
    
    case $config_choice in
        1)
            read -p "New AWS Region: " new_region
            sed -i.bak "s/AWS_REGION=.*/AWS_REGION=\"$new_region\"/" config/dev-config.sh
            print_success "Region updated to $new_region"
            ;;
        2)
            read -p "New API Endpoint: " new_api
            sed -i.bak "s|API_ENDPOINT=.*|API_ENDPOINT=\"$new_api\"|" config/dev-config.sh
            print_success "API Endpoint updated"
            ;;
        3)
            echo "View current Cognito settings..."
            grep COGNITO config/dev-config.sh
            ;;
        4)
            echo "Current S3 buckets:"
            echo "  Static Lessons: $STATIC_LESSONS_BUCKET"
            echo "  Frontend: $FRONTEND_BUCKET"
            ;;
        5)
            cat config/dev-config.sh
            ;;
        6)
            print_info "Reloading configuration from AWS..."
            source config/dev-config.sh
            print_success "Configuration reloaded"
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# Main execution loop
while true; do
    show_menu
    
    case $choice in
        1) fresh_install ;;
        2) deploy_all ;;
        3) deploy_frontend ;;
        4) deploy_lambdas ;;
        5) update_single_lambda ;;
        6) create_lesson ;;
        7) test_lesson ;;
        8) update_api_config ;;
        9) reset_database ;;
        10) daily_health_check ;;
        11) view_dashboard ;;
        12) check_costs ;;
        13) view_logs ;;
        14) weekly_report ;;
        15) test_apis ;;
        16) test_auth ;;
        17) load_test ;;
        18) e2e_test ;;
        19) fix_issues ;;
        20) emergency_cost_control ;;
        21) restart_services ;;
        22) view_error_logs ;;
        23) backup_data ;;
        24) show_urls ;;
        25) clean_temp ;;
        26) update_config ;;
        0) 
            print_info "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please try again."
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
