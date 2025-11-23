import boto3
import os
import logging
from datetime import datetime, timedelta
from calendar import monthrange
from botocore.exceptions import ClientError, NoCredentialsError, BotoCoreError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS clients
ce = boto3.client('ce')
sns = boto3.client('sns')

# Configuration
SNS_TOPIC = os.environ.get('ALERT_TOPIC_ARN')
MONTHLY_BUDGET = float(os.environ.get('MONTHLY_BUDGET', '25.0'))  # Default $25/month
COST_THRESHOLD = float(os.environ.get('COST_THRESHOLD', '0.01'))  # Minimum cost to report


def validate_environment():
    """Validate required environment variables"""
    if not SNS_TOPIC:
        raise ValueError("ALERT_TOPIC_ARN environment variable is required")
    logger.info(f"SNS Topic: {SNS_TOPIC}")
    logger.info(f"Monthly Budget: ${MONTHLY_BUDGET}")
    logger.info(f"Cost Threshold: ${COST_THRESHOLD}")


def validate_lambda_inputs(event, context):
    """Validate Lambda event and context parameters"""
    if event is None:
        raise ValueError("Lambda event cannot be None")
    if context is None:
        raise ValueError("Lambda context cannot be None")
    logger.info(f"Lambda request ID: {getattr(context, 'aws_request_id', 'unknown')}")


def lambda_handler(event, context):
    """Check yesterday's costs and alert if monthly projection exceeds budget
    
    Args:
        event: Lambda event object
        context: Lambda context object
        
    Returns:
        dict: Response with status code and cost information
    """
    try:
        # Validate inputs and environment
        validate_lambda_inputs(event, context)
        validate_environment()
        
        # Calculate date range for yesterday's costs
        today = datetime.now().date()
        yesterday = today - timedelta(days=1)
        
        logger.info(f"Fetching costs for {yesterday.strftime('%Y-%m-%d')}")
        
        # Get cost data from AWS Cost Explorer
        response = ce.get_cost_and_usage(
            TimePeriod={
                'Start': yesterday.strftime('%Y-%m-%d'),
                'End': today.strftime('%Y-%m-%d')
            },
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            GroupBy=[{'Type': 'SERVICE', 'Key': 'SERVICE'}]
        )
        
    except (NoCredentialsError, ClientError) as e:
        logger.error(f"AWS API error: {e}")
        return {
            'statusCode': 500,
            'body': f'AWS API error: {str(e)}'
        }
    except ValueError as e:
        logger.error(f"Validation error: {e}")
        return {
            'statusCode': 500,
            'body': f'Validation error: {str(e)}'
        }
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return {
            'statusCode': 500,
            'body': f'Unexpected error: {str(e)}'
        }

    # Process cost data
    total = 0
    breakdown = []

    try:
        for result in response['ResultsByTime']:
            for group in result['Groups']:
                service = group['Keys'][0]
                cost = float(group['Metrics']['UnblendedCost']['Amount'])
                if cost > COST_THRESHOLD:
                    breakdown.append(f"{service}: ${cost:.2f}")
                    total += cost

        # Calculate monthly projection based on actual days in current month
        current_month = today.month
        current_year = today.year
        days_in_month = monthrange(current_year, current_month)[1]
        monthly_projection = total * days_in_month
        
        logger.info(f"Daily cost: ${total:.2f}, Monthly projection: ${monthly_projection:.2f} (based on {days_in_month} days)")

        # Create status message
        budget_status = "⚠️ OVER BUDGET" if monthly_projection > MONTHLY_BUDGET else "✅ Within Budget"
        costs_display = chr(10).join(breakdown) if breakdown else f'No significant costs (< ${COST_THRESHOLD})'
        
        message = f"""CodeLearn Daily Cost Report
===========================
Date: {yesterday.strftime('%Y-%m-%d')}

Yesterday's Costs:
{costs_display}

TOTAL: ${total:.2f}
Monthly Projection: ${monthly_projection:.2f} ({days_in_month} days)
Budget: ${MONTHLY_BUDGET:.2f}

Budget Status: {budget_status}"""

        logger.info("Cost report generated successfully")

        # Send alert if over budget
        if monthly_projection > MONTHLY_BUDGET:
            try:
                sns_response = sns.publish(
                    TopicArn=SNS_TOPIC,
                    Subject='⚠️ CodeLearn: Cost Alert - Over Budget!',
                    Message=message
                )
                logger.warning(f"Budget alert sent successfully (MessageId: {sns_response.get('MessageId', 'unknown')}) - projection ${monthly_projection:.2f} exceeds budget ${MONTHLY_BUDGET:.2f}")
            except ClientError as e:
                logger.error(f"Failed to send SNS alert - this is a critical issue that needs attention: {e}")
                logger.error(f"Alert details - Topic: {SNS_TOPIC}, Projection: ${monthly_projection:.2f}, Budget: ${MONTHLY_BUDGET:.2f}")
        else:
            logger.info(f"Within budget - no alert needed (${monthly_projection:.2f} <= ${MONTHLY_BUDGET:.2f})")

        return {
            'statusCode': 200,
            'body': f'Daily cost: ${total:.2f}, Projection: ${monthly_projection:.2f}'
        }
        
    except KeyError as e:
        logger.error(f"Unexpected response format from Cost Explorer: {e}")
        return {
            'statusCode': 500,
            'body': f'Error parsing cost data: {str(e)}'
        }
    except Exception as e:
        logger.error(f"Error processing cost data: {e}")
        return {
            'statusCode': 500,
            'body': f'Error processing cost data: {str(e)}'
        }
