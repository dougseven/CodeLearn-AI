import json
import os
import boto3
import time
import hashlib
from typing import Dict, Any, Optional

# Initialize AWS clients
bedrock = boto3.client('bedrock-runtime')
dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')

# Environment variables
CACHE_TABLE = dynamodb.Table(os.environ['LESSON_CACHE_TABLE'])
PROGRESS_TABLE = dynamodb.Table(os.environ['PROGRESS_TABLE'])
STATIC_LESSONS_BUCKET = os.environ.get(
    'STATIC_LESSONS_BUCKET', 'codelearn-static-lessons')
EMERGENCY_MODE = os.environ.get('EMERGENCY_MODE', 'false').lower() == 'true'

# Use BUDGET MODEL - Claude 3.5 Haiku
MODEL_ID = 'anthropic.claude-3-5-haiku-20241022-v1:0'

# Cost Tracking
BEDROCK_INPUT_COST_PER_1K = 0.0008  # $0.80 per million tokens
BEDROCK_OUTPUT_COST_PER_1K = 0.004  # $4.00 per million tokens


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Generate or retrieve cached lessons
    COST OPTIMIZATION: Check cache -> static -> generate
    """
    try:
        body = json.loads(event.get('body', '{}'))
        user = event.get('user', {})

        language = body.get('language')
        level = body.get('level')
        topic = body.get('topic')

        if not all([language, level]):
            return error_response(400, {"error": "Missing required parameters: language and level."})

        # Get next topic if not specified
        if not topic:
            topic = get_next_topic(user.get('user_id'), language, level)

        # Generate lesson key for caching
        lesson_key = generate_lesson_key(language, level, topic)

        # STEP 1: Check Cache (90%+ hit rate expected)
        cached_lesson = get_cached_lesson(lesson_key)
        if cached_lesson:
            print(f"Cache hit for lesson: {lesson_key}")
            increment_cache_hit_count(lesson_key)
            lesson_content = cached_lesson
            was_cached = True
        else:
            print(f"Cache miss for lesson: {lesson_key}")

            # STEP 2: Check if lesson exists (FREE)
            static_lesson = get_static_lesson(language, level, topic)
            if static_lesson:
                print(f"Static lesson found for: {lesson_key}")
                lesson_content = static_lesson
                was_cached = False

                # Cache static lessons for faster access
                cache_lesson(lesson_key, lesson_content, cost=0.0, source='static')

            else:
                print(
                    f"No static lesson found for: {lesson_key}, generating dynamically.")

                # STEP 3: Generate Lesson with Bedrock (AI COST)
                if EMERGENCY_MODE:
                    return error_response(503, {"error": "Service is currently in emergency mode. Lesson generation is disabled."})

                print(f"Generating with Bedrock: {lesson_key}")
                lesson_content = generate_lesson_with_bedrock(
                    language, level, topic)
                was_cached = False

                # Cache for future use
                cache_lesson(lesson_key, lesson_content,
                            cost=lesson_content.get(
                                'metadata', {}).get('cost', 0),
                            source='bedrock')

        # Track progress
        lesson_id = f"{language}_{level}_{topic}_{int(time.time())}"
        track_lesson_request(
            user.get('user_id'), lesson_id, language, topic, was_cached)

        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({
                'lessonId': lesson_id,
                'topic': topic,
                'lesson': lesson_content.get('lesson'),
                'challenge': lesson_content.get('challenge'),
                'tests': lesson_content.get('tests'),
                'cached': was_cached  # For debugging / monitoring
            })
        }

    except Exception as e:
        print(f"Error in lesson generation: {str(e)}")
        import traceback
        traceback.print_exc()
        return error_response(500, {"error": "Failed to generate lesson."})


def generate_lesson_key(language: str, level: str, topic: str) -> str:
    """Generate consistent cache key"""
    # Normalize inputs
    key_string = f"{language.lower()}_{level.lower()}_{topic.lower().replace(' ','_')}"
    return key_string


def get_cached_lesson(lesson_key: str) -> Optional[Dict]:
    """Retrieve lessons from cache"""
    try:
        response = CACHE_TABLE.get_item(Key={'lessonKey': lesson_key})
        if 'Item' in response:
            item = response['Item']

            # Check if TTL expired (shouldn't happen, but double check)
            if item.get('ttl', float('inf')) < int(time.time()):
                print(f"Cache entry expired for key: {lesson_key}")
                return None
            return item.get('content')

    except Exception as e:
        print(f"Error retrieving cache for key {lesson_key}: {str(e)}")

    return None


def get_static_lesson(language: str, level: str, topic: str) -> Optional[Dict]:
    """
    Check if static lesson exists in S3
    Static lessons are FREE - no Bedrock cost
    """
    try:
        # Static lessons stored as: static/{language}/{level}/{topic}.json
        s3_key = f"static/{language.lower()}/{level.lower()}/{topic.lower().replace(' ','_')}.json"
        response = s3.get_object(Bucket=STATIC_LESSONS_BUCKET, Key=s3_key)
        lesson_data = json.loads(response['Body'].read().decode('utf-8'))
        print(f"Loaded static lesson from S3: {s3_key}")
        return lesson_data

    except s3.exceptions.NoSuchKey:
        print(f"Static lesson not found in S3: {s3_key}")
        return None

    except Exception as e:
        print(f"Error retrieving static lesson from S3 {s3_key}: {str(e)}")
        return None


def generate_lesson_with_bedrock(language, level, topic):
    """
    Generate lesson using Bedrock - COSTS MONEY
    Optimized for Claude Haiku 3.5 (budget model)
    """

    level_description = {
        'beginner': 'complete beginner with no prior programming experience',
        'intermediate': 'developer with basic understanding of programming',
        'advanced': 'experienced developer looking to deepen knowledge',
        'experienced': 'experienced developer from another language learning this one'
    }

    # Optimization: Concise prompt to reduce token usage
    prompt = f"""Create a {language} lesson for {level_description[level]} on: {topic}

Return ONLY valid JSON (no markdown, no extra text):
{{
    "lesson": "Brief explanation with 2 code examples (300 words max)",
    "challenge": "Clear coding task description (100 words max)",
    "tests": ["test case 1", "test case 2", "test case 3"]
}}

Keep it practical and focused."""

    start_time = time.time()

    # Estimate input tokens (rough)
    input_tokens = len(prompt.split())*1.3  # Words to tokens approximation

    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1500,  # Limit output to control costs
        "messages": [{
            "role": "user",
            "content": prompt
        }],
        "temperature": 0.7,
        "top_p": 0.9,
    }

    response = bedrock.invoke_model(
        body=json.dumps(request_body),
        modelId=MODEL_ID,
        accept='application/json',
        contentType='application/json'
    )

    response_body = json.loads(response.get('body').read())
    content_text = response_body['content'][0]['text']

    # Calculate cost
    output_tokens = response_body['usage']['output_tokens']
    total_input_tokens = response_body['usage']['input_tokens']

    cost = (
        (total_input_tokens / 1000) * BEDROCK_INPUT_COST_PER_1K +
        (output_tokens / 1000) * BEDROCK_OUTPUT_COST_PER_1K
    )

    duration = time.time() - start_time
    print(f"Bedrock generation took {duration:.2f} seconds, cost: ${cost:.6f}")
    print(f"Input tokens: {response_body['usage']['input_tokens']}")
    print(f"Output tokens: {response_body['usage']['output_tokens']}")

    # Parse the JSON response
    try:
        # Clean up response (remove markdown if present)
        clean_text = content_text.strip()
        if clean_text.startswith('```'):
            clean_text = '\n'.join(clean_text.split('\n')[1:-1])

        lesson_data = json.loads(clean_text)

        # Add metadata
        lesson_data['metadata'] = {
            'model': MODEL_ID,
            'input_tokens': total_input_tokens,
            'output_tokens': output_tokens,
            'cost': cost,
            'duration': duration,
            'generatedAt': int(time.time())
        }

        return lesson_data

    except json.JSONDecodeError as e:
        print(f"Error parsing Bedrock response JSON: {str(e)}")
        print(f"Response text: {content_text}")
        raise ValueError("Failed to parse lesson JSON from Bedrock response")


def cache_lesson(lesson_key: str, content: str, cost: float, source: str):
    """
    Cache lesson for future use.
    TTL: 90 days (lessons don't change often)
    """
    try:

        CACHE_TABLE.put_item(
            Item={
                'lessonKey': lesson_key,
                'content': content,
                'metadata': content.get('metadata', {}),
                'source': source,  # Static or Bedrock
                'createdAt': int(time.time()),
                'cost': cost,
                'ttl': int(time.time()) + (90*24*3600),  # 90 days
                'hitCount': 0,
                'totalCost': cost
            }
        )
        print(f"Cached lesson {lesson_key} from source {source}")

    except Exception as e:
        print(f"Error caching lesson {lesson_key}: {str(e)}")


def increment_cache_hit_count(lesson_key: str):
    """Track cache usage for analytics"""
    try:
        CACHE_TABLE.update_item(
            Key={'lessonKey': lesson_key},
            UpdateExpression="ADD hitCount :inc",
            ExpressionAttributeValues={':inc': 1}
        )
    except Exception as e:
        print(f"Error incrementing hit count for {lesson_key}: {str(e)}")


def track_lesson_request(user_id: str, lesson_id: str, language: str, topic: str, was_cached: bool):
    """Log lesson requests for user progress tracking"""
    try:
        PROGRESS_TABLE.put_item(
            Item={
                'userId': user_id,
                'lessonId': lesson_id,
                'topic': topic,
                'language': language,
                'completed': False,
                'attempts': 0,
                'wasCached': was_cached,
                'createdAt': int(time.time()),
            }
        )
        print(f"Tracked lesson request {lesson_id} for user {user_id}")

    except Exception as e:
        print(
            f"Error tracking lesson request {lesson_id} for user {user_id}: {str(e)}")


def get_next_topic(user_id: str, language: str, level: str) -> str:
    """
    Determine the next topic for the user based on their progress.
    """

    # Simplified curriculum (static lessons should cover these)
    curricula = {
        'python': {
            'beginner': [
                'variables and data types',
                'conditionals',
                'loops',
                'functions',
                'lists',
                'dictionaries',
                'string methods',
                'file input/output'
            ],
            'intermediate': [
                'list comprehensions',
                'lambda functions',
                'decorators',
                'generators',
                'context managers',
                'error handling'
            ]
        },
        'java': {
            'beginner': [
                'variables and data types',
                'conditionals',
                'loops',
                'methods',
                'arrays',
                'classes and objects'
            ]
        },
        'rust': {
            'beginner': [
                'variables and mutability',
                'data types',
                'functions',
                'ownership basics',
                'structs'
            ]
        }
    }

    # Get user's completed lessons
    try:
        response = PROGRESS_TABLE.query(
            KeyConditionExpression='userId = :uid',
            FilterExpression='language = :lang AND completed = :comp',
            ExpressionAttributeValues={
                ':uid': user_id,
                ':lang': language,
                ':comp': True
            }
        )
        completed_count = response.get('Count', 0)
    except Exception as e:
        print(f"Error retrieving user progress for {user_id}: {str(e)}")
        completed_count = 0

    # Get curriculum for language and level
    topics = curricula.get(language.lower(), {}).get(
        level.lower(), ['variables and data types'])

    # Return next topic or default
    if completed_count < len(topics):
        return topics[completed_count]
    else:
        return topics[0]  # Loop back


def cors_headers() -> Dict[str, str]:
    """CORS headers for API responses"""
    return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
    }


def error_response(status_code: int, message: str) -> Dict[str, Any]:
    """Generate an error response"""
    return {
        'statusCode': status_code,
        'headers': cors_headers(),
        'body': json.dumps({'error': message})
    }
