#!/bin/bash

source config/dev-config.sh

function show_help {
    echo "Lambda Update Script"
    echo "==================="
    echo ""
    echo "Usage: ./update-lambda.sh <function-name>"
    echo ""
    echo "Functions:"
    echo "  lesson       - Update LessonLambda"
    echo "  validation   - Update ValidationLambda"
    echo "  user         - Update UserLambda"
    echo "  all          - Update all functions"
}

function update_function {
    local dir=$1
    local name=$2
    
    echo "📦 Updating $name..."
    
    cd $dir
    
    # Clean old package
    rm -f function.zip
    
    # Install dependencies
    pip3 install -r requirements.txt -t . --upgrade
    
    # Create new package
    zip -r function.zip . -x "*.pyc" -x "__pycache__/*" -q
    
    # Update Lambda
    aws lambda update-function-code \
        --function-name $name \
        --zip-file fileb://function.zip \
        --region $AWS_REGION > /dev/null
    
    echo "✅ $name updated"
    
    cd ..
}

case "$1" in
    lesson)
        update_function "lesson_lambda" "CodeLearn-Lesson"
        ;;
    validation)
        update_function "validation_lambda" "CodeLearn-Validation"
        ;;
    user)
        update_function "user_lambda" "CodeLearn-User"
        ;;
    all)
        update_function "lesson_lambda" "CodeLearn-Lesson"
        update_function "validation_lambda" "CodeLearn-Validation"
        update_function "user_lambda" "CodeLearn-User"
        ;;
    *)
        show_help
        ;;
esac
