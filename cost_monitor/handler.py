import boto3
import os
import logging
from datetime import datetime, timedelta
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


def lambda_handler(event, context):
    """Check daily costs and alert if trending over budget
    
    Args:
        event: Lambda event object
        context: Lambda context object
        
    Returns:
        dict: Response with status code and cost information
    """
    try:
        # Validate environment
        validate_environment()
        
        # Calculate date range for yesterday's costs
        end = datetime.now().date()
        start = end - timedelta(days=1)
        
        logger.info(f"Fetching costs for {start.strftime('%Y-%m-%d')}")
        
        # Get cost data from AWS Cost Explorer
        response = ce.get_cost_and_usage(
            TimePeriod={
                'Start': start.strftime('%Y-%m-%d'),
                'End': end.strftime('%Y-%m-%d')
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
        logger.error(f"Configuration error: {e}")
        return {
            'statusCode': 400,
            'body': f'Configuration error: {str(e)}'
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

        monthly_projection = total * 30
        
        logger.info(f"Daily cost: ${total:.2f}, Monthly projection: ${monthly_projection:.2f}")

        # Create status message
        message = f"""
CodeLearn Daily Cost Report
===========================
Date: {start.strftime('%Y-%m-%d')}

Yesterday's Costs:
{chr(10).join(breakdown) if breakdown else 'No significant costs (< $' + str(COST_THRESHOLD) + ')'}

TOTAL: ${total:.2f}
Monthly Projection: ${monthly_projection:.2f}
Budget: ${MONTHLY_BUDGET:.2f}

Budget Status: {"⚠️ OVER BUDGET" if monthly_projection > MONTHLY_BUDGET else "✅ Within Budget"}
        """

        logger.info("Cost report generated successfully")

        # Send alert if over budget
        if monthly_projection > MONTHLY_BUDGET:
            try:
                sns.publish(
                    TopicArn=SNS_TOPIC,
                    Subject='⚠️ CodeLearn: Cost Alert - Over Budget!',
                    Message=message
                )
                logger.warning(f"Budget alert sent - projection ${monthly_projection:.2f} exceeds budget ${MONTHLY_BUDGET:.2f}")
            except ClientError as e:
                logger.error(f"Failed to send SNS alert: {e}")
                # Don't fail the function if SNS fails, just log the error
        else:
            logger.info(f"Within budget - no alert needed")

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
