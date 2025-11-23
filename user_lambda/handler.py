import json
import os
import boto3
import time
from typing import Dict, Any, Optional
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
users_table = dynamodb.Table(os.environ.get('USERS_TABLE', 'codelearn-users-dev'))
progress_table = dynamodb.Table(os.environ.get('PROGRESS_TABLE', 'codelearn-progress-dev'))

# Configuration
MAX_PROGRESS_ITEMS = 100  # Maximum items to return in progress query
ALLOWED_PREFERENCE_KEYS = ['theme', 'language', 'notifications', 'difficulty', 'autoSave']


def validate_preferences(preferences: Dict[str, Any]) -> Optional[str]:
    """Validate user preferences structure and content"""
    if not isinstance(preferences, dict):
        return "Preferences must be a JSON object"
    
    # Check for disallowed keys
    invalid_keys = [key for key in preferences.keys() if key not in ALLOWED_PREFERENCE_KEYS]
    if invalid_keys:
        return f"Invalid preference keys: {', '.join(invalid_keys)}. Allowed: {', '.join(ALLOWED_PREFERENCE_KEYS)}"
    
    # Validate specific preference values
    if 'theme' in preferences and preferences['theme'] not in ['light', 'dark']:
        return "Theme must be 'light' or 'dark'"
    
    if 'language' in preferences and not isinstance(preferences['language'], str):
        return "Language must be a string"
    
    if 'notifications' in preferences and not isinstance(preferences['notifications'], bool):
        return "Notifications must be true or false"
    
    if 'difficulty' in preferences and preferences['difficulty'] not in ['beginner', 'intermediate', 'advanced']:
        return "Difficulty must be 'beginner', 'intermediate', or 'advanced'"
    
    if 'autoSave' in preferences and not isinstance(preferences['autoSave'], bool):
        return "AutoSave must be true or false"
    
    return None


def get_user_id_from_context(event: Dict[str, Any]) -> str:
    """Extract and validate user ID from request context"""
    user_id = event.get('requestContext', {}).get('authorizer', {}).get('userId', 'anonymous')
    if user_id == 'anonymous':
        raise ValueError("User not authenticated")
    return user_id


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Handle user profile operations
    """
    try:
        http_method = event.get('httpMethod', 'GET')
        path = event.get('path', '')
        
        if http_method == 'GET' and '/profile' in path:
            return get_profile(event)
        elif http_method == 'POST' and '/profile' in path:
            return create_profile(event)
        elif http_method == 'PUT' and '/profile' in path:
            return update_profile(event)
        elif http_method == 'GET' and '/progress' in path:
            return get_progress(event)
        else:
            return error_response(404, 'Endpoint not found')
            
    except Exception as e:
        print(f"User handler error: {str(e)}")
        import traceback
        traceback.print_exc()
        return error_response(500, f'Internal error: {str(e)}')


def get_profile(event: Dict[str, Any]) -> Dict[str, Any]:
    """Get user profile"""
    try:
        user_id = get_user_id_from_context(event)
    except ValueError as e:
        return error_response(401, str(e))
    
    try:
        response = users_table.get_item(Key={'userId': user_id})
        
        if 'Item' in response:
            user = response['Item']
            return {
                'statusCode': 200,
                'headers': cors_headers(),
                'body': json.dumps({
                    'userId': user.get('userId'),
                    'email': user.get('email'),
                    'name': user.get('name'),
                    'preferences': user.get('preferences', {}),
                    'createdAt': user.get('createdAt'),
                    'lastLogin': user.get('lastLogin')
                })
            }
        else:
            return error_response(404, 'User not found')
            
    except Exception as e:
        print(f"Error getting profile: {e}")
        return error_response(500, 'Failed to get profile')


def update_profile(event: Dict[str, Any]) -> Dict[str, Any]:
    """Update user profile/preferences"""
    try:
        user_id = get_user_id_from_context(event)
    except ValueError as e:
        return error_response(401, str(e))
    
    try:
        body = json.loads(event.get('body', '{}'))
        preferences = body.get('preferences', {})
        
        # Validate preferences
        validation_error = validate_preferences(preferences)
        if validation_error:
            return error_response(400, validation_error)
        
        # Update user preferences
        users_table.update_item(
            Key={'userId': user_id},
            UpdateExpression='SET preferences = :prefs, lastLogin = :time',
            ExpressionAttributeValues={
                ':prefs': preferences,
                ':time': int(time.time())
            }
        )
        
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({
                'message': 'Profile updated successfully',
                'preferences': preferences
            })
        }
        
    except Exception as e:
        print(f"Error updating profile: {e}")
        return error_response(500, 'Failed to update profile')


def get_progress(event: Dict[str, Any]) -> Dict[str, Any]:
    """Get user's learning progress with pagination"""
    try:
        user_id = get_user_id_from_context(event)
    except ValueError as e:
        return error_response(401, str(e))
    
    try:
        # Get pagination parameters
        query_params = event.get('queryStringParameters') or {}
        limit = min(int(query_params.get('limit', '50')), MAX_PROGRESS_ITEMS)
        last_key = query_params.get('lastKey')
        
        # Build query parameters
        query_params = {
            'KeyConditionExpression': 'userId = :uid',
            'ExpressionAttributeValues': {':uid': user_id},
            'Limit': limit
        }
        
        if last_key:
            # Add pagination token
            query_params['ExclusiveStartKey'] = {'userId': user_id, 'lessonId': last_key}
        
        response = progress_table.query(**query_params)
        
        lessons = response.get('Items', [])
        # Fix: Use 'status' field consistent with validation lambda
        completed = [l for l in lessons if l.get('status') == 'completed']
        
        # Prepare pagination info
        pagination = {}
        if 'LastEvaluatedKey' in response:
            pagination['lastKey'] = response['LastEvaluatedKey'].get('lessonId')
            pagination['hasMore'] = True
        else:
            pagination['hasMore'] = False
        
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({
                'totalLessons': len(lessons),
                'completedLessons': len(completed),
                'lessons': lessons,
                'pagination': pagination
            })
        }
        
    except Exception as e:
        print(f"Error getting progress: {e}")
        return error_response(500, 'Failed to get progress')


def create_profile(event: Dict[str, Any]) -> Dict[str, Any]:
    """Create new user profile"""
    try:
        user_id = get_user_id_from_context(event)
    except ValueError as e:
        return error_response(401, str(e))
    
    try:
        body = json.loads(event.get('body', '{}'))
        email = body.get('email', '')
        name = body.get('name', '')
        preferences = body.get('preferences', {})
        
        # Validate required fields
        if not email or not name:
            return error_response(400, 'Email and name are required')
        
        # Validate preferences
        validation_error = validate_preferences(preferences)
        if validation_error:
            return error_response(400, validation_error)
        
        # Check if user already exists
        try:
            response = users_table.get_item(Key={'userId': user_id})
            if 'Item' in response:
                return error_response(409, 'User already exists')
        except ClientError as e:
            print(f"Error checking existing user: {e}")
            return error_response(500, 'Failed to validate user')
        
        # Create new user record
        current_time = int(time.time())
        user_data = {
            'userId': user_id,
            'email': email,
            'name': name,
            'preferences': preferences,
            'createdAt': current_time,
            'lastLogin': current_time
        }
        
        users_table.put_item(Item=user_data)
        
        return {
            'statusCode': 201,
            'headers': cors_headers(),
            'body': json.dumps({
                'message': 'User profile created successfully',
                'userId': user_id,
                'email': email,
                'name': name,
                'preferences': preferences
            })
        }
        
    except json.JSONDecodeError:
        return error_response(400, 'Invalid JSON in request body')
    except Exception as e:
        print(f"Error creating profile: {e}")
        return error_response(500, 'Failed to create profile')


def cors_headers() -> Dict[str, str]:
    return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
    }


def error_response(status_code: int, message: str, details: Optional[str] = None) -> Dict[str, Any]:
    """Generate error response with optional details"""
    response_body = {'error': message}
    
    # Only include details for client errors (4xx), not server errors (5xx)
    if details and 400 <= status_code < 500:
        response_body['details'] = details
    
    return {
        'statusCode': status_code,
        'headers': cors_headers(),
        'body': json.dumps(response_body)
    }