#!/bin/bash
set -e

echo "🚀 Setting up CodeLearn Cost Monitor"
echo "======================================"
echo ""

# Configuration
ROLE_NAME="lambda-cost-monitor-role"
POLICY_NAME="CodeLearn-CostMonitor-Policy"
FUNCTION_NAME="CodeLearn-CostMonitor"
SNS_TOPIC_NAME="CodeLearn-Cost-Alerts"
EMAIL="your-email@example.com"  # ⚠️ CHANGE THIS!
REGION="us-east-1"

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $ACCOUNT_ID"
echo "Region: $REGION"
echo ""

# Create trust policy
echo "📝 Creating trust policy..."
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create permissions policy
echo "📝 Creating permissions policy..."
cat > cost-monitor-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ce:GetCostAndUsage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": "arn:aws:sns:*:*:${SNS_TOPIC_NAME}"
    }
  ]
}
EOF

# Create IAM role
echo "🔐 Creating IAM role: $ROLE_NAME"
aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document file://trust-policy.json \
  --description "Role for CodeLearn cost monitoring Lambda" \
  2>/dev/null || echo "Role already exists"

# Create IAM policy
echo "🔐 Creating IAM policy: $POLICY_NAME"
POLICY_ARN=$(aws iam create-policy \
  --policy-name $POLICY_NAME \
  --policy-document file://cost-monitor-policy.json \
  --query 'Policy.Arn' \
  --output text 2>/dev/null) || \
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"

echo "Policy ARN: $POLICY_ARN"

# Attach policy to role
echo "🔗 Attaching policy to role..."
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn $POLICY_ARN \
  2>/dev/null || echo "Policy already attached"

# Get role ARN
ROLE_ARN=$(aws iam get-role \
  --role-name $ROLE_NAME \
  --query 'Role.Arn' \
  --output text)

echo "Role ARN: $ROLE_ARN"

# Wait for IAM propagation
echo "⏳ Waiting 10 seconds for IAM propagation..."
sleep 10

# Create SNS topic
echo "📧 Creating SNS topic: $SNS_TOPIC_NAME"
SNS_TOPIC_ARN=$(aws sns create-topic \
  --name $SNS_TOPIC_NAME \
  --query 'TopicArn' \
  --output text)

echo "SNS Topic ARN: $SNS_TOPIC_ARN"

# Subscribe email
echo "📧 Subscribing email: $EMAIL"
aws sns subscribe \
  --topic-arn $SNS_TOPIC_ARN \
  --protocol email \
  --notification-endpoint $EMAIL \
  2>/dev/null || echo "Already subscribed"

echo ""
echo "⚠️  IMPORTANT: Check your email ($EMAIL) and confirm the SNS subscription!"
echo "Press Enter after confirming..."
read

# Create Lambda deployment package
echo "📦 Creating Lambda deployment package..."
mkdir -p cost_monitor
cat > cost_monitor/handler.py <<'EOF'
import boto3
import os
from datetime import datetime, timedelta

ce = boto3.client('ce')
sns = boto3.client('sns')

SNS_TOPIC = os.environ.get('ALERT_TOPIC_ARN')
DAILY_BUDGET = 0.83  # $25/month = ~$0.83/day

def lambda_handler(event, context):
    """Check daily costs and alert if trending over budget"""
    
    end = datetime.now().date()
    start = end - timedelta(days=1)
    
    try:
        response = ce.get_cost_and_usage(
            TimePeriod={
                'Start': start.strftime('%Y-%m-%d'),
                'End': end.strftime('%Y-%m-%d')
            },
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            GroupBy=[{'Type': 'SERVICE', 'Key': 'SERVICE'}]
        )
        
        total = 0
        breakdown = []
        
        for result in response['ResultsByTime']:
            for group in result['Groups']:
                service = group['Keys'][0]
                cost = float(group['Metrics']['UnblendedCost']['Amount'])
                if cost > 0.01:
                    breakdown.append(f"{service}: ${cost:.2f}")
                    total += cost
        
        monthly_projection = total * 30
        
        message = f"""
CodeLearn Daily Cost Report
===========================
Date: {start.strftime('%Y-%m-%d')}

Yesterday's Costs:
{chr(10).join(breakdown) if breakdown else 'No costs recorded'}

TOTAL: ${total:.2f}
Monthly Projection: ${monthly_projection:.2f}
Daily Budget: ${DAILY_BUDGET:.2f}

Budget Status: {"⚠️ OVER BUDGET" if monthly_projection > 25 else "✅ Within Budget"}
        """
        
        print(message)
        
        # Alert if over budget
        if monthly_projection > 25 and SNS_TOPIC:
            sns.publish(
                TopicArn=SNS_TOPIC,
                Subject='⚠️ CodeLearn: Cost Alert - Over Budget!',
                Message=message
            )
            return {
                'statusCode': 200,
                'body': f'ALERT SENT: ${total:.2f}, Projection: ${monthly_projection:.2f}'
            }
        
        return {
            'statusCode': 200,
            'body': f'OK: ${total:.2f}, Projection: ${monthly_projection:.2f}'
        }
        
    except Exception as e:
        error_msg = f"Error checking costs: {str(e)}"
        print(error_msg)
        
        if SNS_TOPIC:
            sns.publish(
                TopicArn=SNS_TOPIC,
                Subject='❌ CodeLearn: Cost Monitor Error',
                Message=error_msg
            )
        
        return {
            'statusCode': 500,
            'body': error_msg
        }
EOF

cd cost_monitor
zip -q function.zip handler.py
cd ..

# Create Lambda function
echo "🔧 Creating Lambda function: $FUNCTION_NAME"
aws lambda create-function \
  --function-name $FUNCTION_NAME \
  --runtime python3.12 \
  --handler handler.lambda_handler \
  --role $ROLE_ARN \
  --zip-file fileb://cost_monitor/function.zip \
  --timeout 30 \
  --memory-size 128 \
  --environment Variables={ALERT_TOPIC_ARN=$SNS_TOPIC_ARN} \
  --region $REGION \
  2>/dev/null || echo "Function already exists, updating code..."

# Update if already exists
aws lambda update-function-code \
  --function-name $FUNCTION_NAME \
  --zip-file fileb://cost_monitor/function.zip \
  --region $REGION \
  2>/dev/null || true

# Test the function
echo "🧪 Testing Lambda function..."
aws lambda invoke \
  --function-name $FUNCTION_NAME \
  --region $REGION \
  response.json

echo ""
echo "Response:"
cat response.json
echo ""

# Create EventBridge rule
echo "⏰ Creating EventBridge rule for daily execution..."
RULE_ARN=$(aws events put-rule \
  --name DailyCostCheck \
  --schedule-expression "cron(0 12 * * ? *)" \
  --state ENABLED \
  --description "Run CodeLearn cost check daily at noon UTC" \
  --region $REGION \
  --query 'RuleArn' \
  --output text)

echo "Rule ARN: $RULE_ARN"

# Add Lambda as target
LAMBDA_ARN=$(aws lambda get-function \
  --function-name $FUNCTION_NAME \
  --region $REGION \
  --query 'Configuration.FunctionArn' \
  --output text)

aws events put-targets \
  --rule DailyCostCheck \
  --targets "Id=1,Arn=$LAMBDA_ARN" \
  --region $REGION

# Grant EventBridge permission to invoke Lambda
aws lambda add-permission \
  --function-name $FUNCTION_NAME \
  --statement-id AllowEventBridgeInvoke \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn $RULE_ARN \
  --region $REGION \
  2>/dev/null || echo "Permission already exists"

# Clean up
rm -f trust-policy.json cost-monitor-policy.json response.json

echo ""
echo "✅ Setup Complete!"
echo "=================="
echo ""
echo "📋 Summary:"
echo "  • IAM Role: $ROLE_NAME"
echo "  • Lambda Function: $FUNCTION_NAME"
echo "  • SNS Topic: $SNS_TOPIC_NAME"
echo "  • Email: $EMAIL"
echo "  • Schedule: Daily at 12:00 UTC"
echo ""
echo "🔍 To view logs:"
echo "  aws logs tail /aws/lambda/$FUNCTION_NAME --follow"
echo ""
echo "💰 To manually check costs:"
echo "  aws lambda invoke --function-name $FUNCTION_NAME response.json && cat response.json"
echo ""
echo "🎉 Done! You'll receive daily cost reports at $EMAIL"