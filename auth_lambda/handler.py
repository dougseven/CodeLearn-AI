import json
import os
import boto3
import time
import hashlib
import secrets
import logging
from typing import Dict, Any, Optional
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Constants
SESSION_EXPIRY_HOURS = 24
SESSION_EXPIRY_SECONDS = SESSION_EXPIRY_HOURS * 60 * 60

dynamodb = boto3.resource('dynamodb')
users_table = dynamodb.Table(os.environ.get('USERS_TABLE', 'codelearn-users-dev'))
sessions_table = dynamodb.Table(os.environ.get('SESSIONS_TABLE', 'codelearn-sessions-dev'))


def validate_claims(claims: Dict[str, Any]) -> Optional[str]:
    """Validate required claims data."""
    if not claims:
        return "No claims provided"
    
    user_id = claims.get('sub')
    email = claims.get('email')
    
    if not user_id or not isinstance(user_id, str) or len(user_id.strip()) == 0:
        return "Invalid or missing user ID"
    
    if not email or not isinstance(email, str) or '@' not in email:
        return "Invalid or missing email"
    
    return None


def hash_token(token: str) -> str:
    """Hash a session token for secure storage."""
    return hashlib.sha256(token.encode()).hexdigest()


def cleanup_expired_sessions(user_id: str, current_time: int) -> None:
    """Remove expired sessions for a user."""
    try:
        # Query for user's sessions
        response = sessions_table.query(
            IndexName='user-id-index',  # Assuming this GSI exists
            KeyConditionExpression='user_id = :user_id',
            FilterExpression='expires_at < :current_time',
            ExpressionAttributeValues={
                ':user_id': user_id,
                ':current_time': current_time
            }
        )
        
        # Delete expired sessions
        for item in response.get('Items', []):
            sessions_table.delete_item(
                Key={'session_id': item['session_id']}
            )
            logger.info(f"Deleted expired session: {item['session_id']}")
            
    except ClientError as e:
        logger.warning(f"Session cleanup failed for user {user_id}: {e}")
        # Don't fail the auth process if cleanup fails


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Handle OAuth callback and create user session.
    """
    try:
        # Get user info from Cognito authorizer
        claims = event.get('requestContext', {}).get('authorizer', {}).get('claims', {})

        # Validate claims
        validation_error = validate_claims(claims)
        if validation_error:
            logger.warning(f"Claims validation failed: {validation_error}")
            return error_response(401, 'Unauthorized: Invalid claims')
        
        # Extract user information
        user_id = claims.get('sub').strip()
        email = claims.get('email').strip().lower()
        name = claims.get('name', email.split('@')[0]).strip()

        # Create or update user in database
        now = int(time.time())
        
        try:
            # Try to update existing user (preserve created_at and preferences)
            users_table.update_item(
                Key={'user_id': user_id},
                UpdateExpression='SET email = :email, #name = :name, last_login = :last_login',
                ExpressionAttributeNames={'#name': 'name'},  # 'name' is a reserved keyword
                ExpressionAttributeValues={
                    ':email': email,
                    ':name': name,
                    ':last_login': now
                }
            )
            logger.info(f"Updated existing user: {user_id}")
        except ClientError as e:
            if e.response['Error']['Code'] == 'ValidationException':
                # User doesn't exist, create new one
                try:
                    users_table.put_item(
                        Item={
                            'user_id': user_id,
                            'email': email,
                            'name': name,
                            'created_at': now,
                            'last_login': now,
                            'preferences': {}
                        },
                        ConditionExpression='attribute_not_exists(user_id)'
                    )
                    logger.info(f"Created new user: {user_id}")
                except ClientError as ce:
                    if ce.response['Error']['Code'] == 'ConditionalCheckFailedException':
                        # Race condition: user was created between update and put
                        logger.info(f"User created concurrently, updating: {user_id}")
                        users_table.update_item(
                            Key={'user_id': user_id},
                            UpdateExpression='SET email = :email, #name = :name, last_login = :last_login',
                            ExpressionAttributeNames={'#name': 'name'},
                            ExpressionAttributeValues={
                                ':email': email,
                                ':name': name,
                                ':last_login': now
                            }
                        )
                    else:
                        raise ce
            else:
                raise e

        # Clean up expired sessions for this user
        cleanup_expired_sessions(user_id, now)
        
        # Create session
        session_id = secrets.token_urlsafe(32)
        session_token = secrets.token_urlsafe(64)
        session_token_hash = hash_token(session_token)
        
        try:
            sessions_table.put_item(
                Item={
                    'session_id': session_id,
                    'user_id': user_id,
                    'token_hash': session_token_hash,
                    'created_at': now,
                    'expires_at': now + SESSION_EXPIRY_SECONDS
                }
            )
            logger.info(f"Created session for user: {user_id}")
        except ClientError as e:
            logger.error(f"Failed to create session for user {user_id}: {e}")
            return error_response(500, 'Failed to create session')

        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({
                'session_id': session_id,
                'session_token': session_token,
                'userId': user_id,
                'email': email,
                'name': name
            })
        }
    
    except ClientError as e:
        logger.error(f"DynamoDB error during authentication: {e.response['Error']['Code']}")
        return error_response(500, 'Authentication service unavailable')
    except Exception as e:
        logger.error(f"Unexpected error during authentication: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return error_response(500, 'Authentication failed')
    

def cors_headers() -> Dict[str, str]:
    return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    }


def error_response(status_code: int, message: str) -> Dict[str, Any]:
    return {
        'statusCode': status_code,
        'headers': cors_headers(),
        'body': json.dumps({'message': message})
    }

