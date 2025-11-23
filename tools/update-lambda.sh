#!/bin/bash
# CodeLearn Platform - Update Lambda Functions
# Deploy Lambda functions to AWS

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Function to update a Lambda function
update_lambda() {
    local lambda_name=$1
    local lambda_dir=$2
    local function_name=$3
    
    echo -e "${BLUE}Updating $lambda_name...${NC}"
    
    # Check if directory exists
    if [ ! -d "$lambda_dir" ]; then
        echo -e "${RED}❌ Directory not found: $lambda_dir${NC}"
        return 1
    fi
    
    # Navigate to Lambda directory
    cd "$lambda_dir"
    
    # Clean up old package
    rm -f function.zip
    
    # Install dependencies if requirements.txt exists
    if [ -f "requirements.txt" ]; then
        echo "  Installing dependencies..."
        pip3 install -r requirements.txt -t . --upgrade --quiet --disable-pip-version-check 2>/dev/null
        
        if [ $? -ne 0 ]; then
            echo -e "${YELLOW}  ⚠️  Warning: Some dependencies may not have installed correctly${NC}"
        fi
    fi
    
    # Create deployment package
    echo "  Creating deployment package..."
    zip -r function.zip . -q \
        -x "*.pyc" \
        -x "__pycache__/*" \
        -x "*.git/*" \
        -x "*.vscode/*" \
        -x "*.DS_Store" \
        -x "*.pytest_cache/*" \
        -x "tests/*" \
        -x "*.md"
    
    if [ ! -f "function.zip" ]; then
        echo -e "${RED}❌ Failed to create deployment package${NC}"
        cd ..
        return 1
    fi
    
    # Get package size
    SIZE=$(du -h function.zip | cut -f1)
    echo "  Package size: $SIZE"
    
    # Check if function exists
    if aws lambda get-function --function-name $function_name --region $AWS_REGION > /dev/null 2>&1; then
        # Update existing function
        echo "  Uploading to AWS..."
        
        UPDATE_OUTPUT=$(aws lambda update-function-code \
            --function-name $function_name \
            --zip-file fileb://function.zip \
            --region $AWS_REGION \
            2>&1)
        
        if [ $? -eq 0 ]; then
            # Wait for update to complete
            echo "  Waiting for update to complete..."
            aws lambda wait function-updated \
                --function-name $function_name \
                --region $AWS_REGION 2>/dev/null
            
            # Get version info
            LAST_MODIFIED=$(aws lambda get-function \
                --function-name $function_name \
                --region $AWS_REGION \
                --query 'Configuration.LastModified' \
                --output text 2>/dev/null)
            
            echo -e "${GREEN}✅ $lambda_name updated successfully${NC}"
            echo "  Last modified: $LAST_MODIFIED"
        else
            echo -e "${RED}❌ Failed to update $lambda_name${NC}"
            echo "$UPDATE_OUTPUT"
            cd ..
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  Function $function_name does not exist${NC}"
        echo "  Please create it first using the setup script"
        cd ..
        return 1
    fi
    
    # Clean up
    rm -f function.zip
    
    # Return to original directory
    cd ..
    
    return 0
}

# Function to update all Lambdas
update_all() {
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Updating All Lambda Functions                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    
    UPDATED=0
    FAILED=0
    
    # Update Lesson Lambda
    if update_lambda "Lesson Lambda" "lesson_lambda" "CodeLearn-Lesson"; then
        ((UPDATED++))
    else
        ((FAILED++))
    fi
    echo ""
    
    # Update Validation Lambda
    if update_lambda "Validation Lambda" "validation_lambda" "CodeLearn-Validation"; then
        ((UPDATED++))
    else
        ((FAILED++))
    fi
    echo ""
    
    # Update User Lambda
    if update_lambda "User Lambda" "user_lambda" "CodeLearn-User"; then
        ((UPDATED++))
    else
        ((FAILED++))
    fi
    echo ""
    
    # Update Auth Lambda
    if update_lambda "Auth Lambda" "auth_lambda" "CodeLearn-Auth"; then
        ((UPDATED++))
    else
        ((FAILED++))
    fi
    echo ""
    
    # Summary
    echo -e "${BLUE}════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Summary:${NC}"
    echo -e "  ${GREEN}Updated: $UPDATED${NC}"
    echo -e "  ${RED}Failed: $FAILED${NC}"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✅ All Lambda functions updated successfully!${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Some Lambda functions failed to update${NC}"
        return 1
    fi
}

# Main script logic
if [ $# -eq 0 ]; then
    echo "Usage: $0 <function|all>"
    echo ""
    echo "Update Lambda functions:"
    echo "  $0 all           Update all Lambda functions"
    echo "  $0 lesson        Update Lesson Lambda only"
    echo "  $0 validation    Update Validation Lambda only"
    echo "  $0 user          Update User Lambda only"
    echo "  $0 auth          Update Auth Lambda only"
    echo ""
    exit 1
fi

FUNCTION=$1

case $FUNCTION in
    all)
        update_all
        ;;
    lesson)
        update_lambda "Lesson Lambda" "lesson_lambda" "CodeLearn-Lesson"
        ;;
    validation)
        update_lambda "Validation Lambda" "validation_lambda" "CodeLearn-Validation"
        ;;
    user)
        update_lambda "User Lambda" "user_lambda" "CodeLearn-User"
        ;;
    auth)
        update_lambda "Auth Lambda" "auth_lambda" "CodeLearn-Auth"
        ;;
    *)
        echo -e "${RED}❌ Unknown function: $FUNCTION${NC}"
        echo ""
        echo "Valid options: all, lesson, validation, user, auth"
        exit 1
        ;;
esac

exit $?