#!/bin/bash

source config/dev-config.sh

echo "🔍 Verifying DynamoDB Tables"
echo "=============================="
echo ""

for table in $LESSON_CACHE_TABLE $USERS_TABLE $PROGRESS_TABLE $SESSIONS_TABLE; do
    echo "Checking: $table"
    STATUS=$(aws dynamodb describe-table \
        --table-name $table \
        --query 'Table.TableStatus' \
        --output text 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "  ✅ Status: $STATUS"
        
        # Get item count
        ITEMS=$(aws dynamodb describe-table \
            --table-name $table \
            --query 'Table.ItemCount' \
            --output text)
        echo "  📊 Items: $ITEMS"
        
        # Get billing mode
        BILLING=$(aws dynamodb describe-table \
            --table-name $table \
            --query 'Table.BillingModeSummary.BillingMode' \
            --output text)
        echo "  💰 Billing: $BILLING"
    else
        echo "  ❌ Not found or error"
    fi
    echo ""
done
