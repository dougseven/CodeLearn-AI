import json
import os
import boto3
import time
import hashlib
import urllib.parse
from decimal import Decimal
from typing import Dict, Any, Optional
from botocore.exceptions import ClientError

# Initialize AWS clients
bedrock = boto3.client('bedrock-runtime')
dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')

# Environment variables
CACHE_TABLE = dynamodb.Table(os.environ.get('LESSON_CACHE_TABLE', 'codelearn-lesson-cache-dev'))
PROGRESS_TABLE = dynamodb.Table(os.environ.get('PROGRESS_TABLE', 'codelearn-progress-dev'))
STATIC_LESSONS_BUCKET = os.environ.get('STATIC_LESSONS_BUCKET', '')
EMERGENCY_MODE = os.environ.get('EMERGENCY_MODE', 'false').lower() == 'true'

# Validation constants
VALID_LANGUAGES = ['python', 'java', 'rust', 'javascript', 'typescript', 'go', 'c', 'cpp']
VALID_LEVELS = ['beginner', 'intermediate', 'advanced', 'experienced']

# Use BUDGET MODEL - Claude 3.5 Haiku - unless another model is set.
DEFAULT_MODEL_ID = 'us.anthropic.claude-3-5-haiku-20241022-v1:0'
MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', DEFAULT_MODEL_ID)

# Cost Tracking
BEDROCK_INPUT_COST_PER_1K = 0.0008  # $0.80 per million tokens
BEDROCK_OUTPUT_COST_PER_1K = 0.004  # $4.00 per million tokens


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Generate or retrieve cached lessons
    COST OPTIMIZATION: Check cache -> static -> generate
    """
    try:
        # Parse request
        body = json.loads(event.get('body', '{}'))
        
        language = body.get('language', 'python').lower()
        level = body.get('level', 'beginner').lower()
        topic = body.get('topic')
        
        # Validate required parameters
        if not all([language, level]):
            return error_response(400, 'Missing required parameters')
            
        # Validate language and level values
        if language not in VALID_LANGUAGES:
            return error_response(400, f'Unsupported language: {language}. Valid options: {", ".join(VALID_LANGUAGES)}')
            
        if level not in VALID_LEVELS:
            return error_response(400, f'Invalid level: {level}. Valid options: {", ".join(VALID_LEVELS)}')
        
        # If no topic specified, use a default
        if not topic:
            topic = 'variables and data types'
        
        # Generate lesson key for caching
        lesson_key = generate_lesson_key(language, level, topic)
        
        # STEP 1: Check cache (90%+ hit rate expected)
        cached_lesson = get_cached_lesson(lesson_key)
        if cached_lesson:
            print(f"✅ CACHE HIT: {lesson_key}")
            increment_cache_hit_count(lesson_key)
            lesson_content = cached_lesson
            was_cached = True
        else:
            print(f"❌ CACHE MISS: {lesson_key}")
            
            # STEP 2: Check if static lesson exists (FREE)
            static_lesson = get_static_lesson(language, level, topic)
            if static_lesson:
                print(f"✅ STATIC LESSON: {lesson_key}")
                lesson_content = static_lesson
                was_cached = False
                # Cache static lessons too for faster access
                cache_lesson(lesson_key, lesson_content, cost=0.0, source='static')
            else:
                # STEP 3: Generate with Bedrock (COSTS MONEY!)
                if EMERGENCY_MODE:
                    # Try to provide a fallback lesson from cache with similar topic
                    fallback_lesson = get_fallback_lesson(language, level)
                    if fallback_lesson:
                        print(f"🔄 EMERGENCY FALLBACK: {lesson_key}")
                        lesson_content = fallback_lesson
                        lesson_content['lesson'] = f"# {topic.title()}\n\n*Note: AI generation is temporarily disabled. Here's a related lesson:*\n\n" + fallback_lesson.get('lesson', '')
                        was_cached = False
                    else:
                        return error_response(503, 'AI generation temporarily disabled and no fallback content available. Please try again later.')
                
                print(f"💰 GENERATING WITH BEDROCK: {lesson_key}")
                lesson_content = generate_lesson_with_bedrock(language, level, topic)
                was_cached = False
                # Cache for future use
                cache_lesson(
                    lesson_key, 
                    lesson_content,
                    cost=lesson_content.get('metadata', {}).get('cost', 0),
                    source='bedrock'
                )
        
        # Generate unique lesson ID
        lesson_id = f"{language}_{level}_{topic.replace(' ', '_')}_{int(time.time())}"
        
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({
                'lessonId': lesson_id,
                'topic': topic,
                'lesson': lesson_content.get('lesson', ''),
                'challenge': lesson_content.get('challenge', ''),
                'tests': lesson_content.get('tests', []),
                'cached': was_cached
            })
        }
        
    except Exception as e:
        print(f"❌ Lesson generation error: {str(e)}")
        import traceback
        traceback.print_exc()
        return error_response(500, f'Failed to generate lesson: {str(e)}')


def generate_lesson_key(language: str, level: str, topic: str) -> str:
    """Generate consistent cache key with proper sanitization"""
    # Sanitize inputs to ensure safe key generation
    safe_language = urllib.parse.quote(language.lower(), safe='')
    safe_level = urllib.parse.quote(level.lower(), safe='')
    safe_topic = urllib.parse.quote(topic.lower().replace(' ', '_').replace('-', '_'), safe='')
    
    key_string = f"{safe_language}_{safe_level}_{safe_topic}"
    # Ensure key length doesn't exceed DynamoDB limits (max 2048 bytes)
    if len(key_string) > 200:
        # Use hash for very long keys
        key_hash = hashlib.md5(key_string.encode()).hexdigest()
        key_string = f"{safe_language}_{safe_level}_{key_hash}"
    
    return key_string


def get_cached_lesson(lesson_key: str) -> Optional[Dict]:
    """Retrieve lesson from cache"""
    try:
        response = CACHE_TABLE.get_item(Key={'lessonKey': lesson_key})
        
        if 'Item' in response:
            item = response['Item']
            
            # Check if TTL expired
            if item.get('ttl', float('inf')) < time.time():
                print(f"Cache entry expired: {lesson_key}")
                return None
            
            return item.get('content')
    except Exception as e:
        print(f"Cache read error: {e}")
    
    return None


def get_static_lesson(language: str, level: str, topic: str) -> Optional[Dict]:
    """
    Check if static lesson exists in S3
    Static lessons are FREE (no Bedrock cost)
    """
    if not STATIC_LESSONS_BUCKET:
        return None
        
    try:
        # Static lessons stored as: static/{language}/{level}/{topic}.json
        s3_key = f"static/{language}/{level}/{topic.replace(' ', '_')}.json"
        
        response = s3.get_object(
            Bucket=STATIC_LESSONS_BUCKET,
            Key=s3_key
        )
        
        lesson_data = json.loads(response['Body'].read())
        print(f"Loaded static lesson: {s3_key}")
        return lesson_data
        
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchKey':
            print(f"No static lesson found: {s3_key}")
            return None
        else:
            print(f"S3 error loading static lesson: {e}")
            return None
    except Exception as e:
        print(f"Error loading static lesson: {e}")
        return None


def generate_lesson_with_bedrock(language: str, level: str, topic: str) -> Dict:
    """
    Generate lesson using Bedrock - COSTS MONEY!
    Optimized for Claude 3 Haiku (budget model)
    """
    
    level_descriptions = {
        'beginner': 'complete beginner with no prior programming experience',
        'intermediate': 'developer with basic understanding of programming',
        'advanced': 'experienced developer looking to deepen knowledge',
        'experienced': 'experienced developer from another language learning this one'
    }
    
    # OPTIMIZATION: Concise prompt to reduce token usage
    prompt = f"""Create a {language} lesson for {level_descriptions.get(level, 'beginner')} on: {topic}

Return ONLY valid JSON (no markdown, no extra text):
{{
  "lesson": "Brief explanation with 2 code examples (300 words max)",
  "challenge": "Clear coding task description (100 words max)",
  "tests": ["test case 1", "test case 2", "test case 3"]
}}

Keep it practical and focused."""

    start_time = time.time()
    
    try:
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "messages": [{
                "role": "user",
                "content": prompt
            }],
            "max_tokens": 1500,  # LIMIT OUTPUT to control costs
            "temperature": 0.7
        }
        
        response = bedrock.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps(request_body)
        )
        
        response_body = json.loads(response['body'].read())
        content_text = response_body['content'][0]['text']
        
        # Calculate cost with Decimal precision
        output_tokens = response_body['usage']['output_tokens']
        input_tokens = response_body['usage']['input_tokens']
        
        # Use Decimal for precise financial calculations
        input_cost = (Decimal(str(input_tokens)) / Decimal('1000')) * Decimal(str(BEDROCK_INPUT_COST_PER_1K))
        output_cost = (Decimal(str(output_tokens)) / Decimal('1000')) * Decimal(str(BEDROCK_OUTPUT_COST_PER_1K))
        cost = float(input_cost + output_cost)  # Convert back to float for JSON serialization
        
        duration = time.time() - start_time
        
        print(f"💰 Bedrock cost: ${cost:.4f} (Input: {input_tokens}, Output: {output_tokens})")
        print(f"⏱️  Generation time: {duration:.2f}s")
        
        # Parse JSON response
        try:
            # Clean up response (remove markdown if present)
            clean_text = content_text.strip()
            if clean_text.startswith('```'):
                lines = clean_text.split('\n')
                clean_text = '\n'.join(lines[1:-1])
            
            lesson_data = json.loads(clean_text)
            
            # Add metadata
            lesson_data['metadata'] = {
                'model': MODEL_ID,
                'inputTokens': input_tokens,
                'outputTokens': output_tokens,
                'cost': cost,
                'duration': duration,
                'generatedAt': int(time.time())
            }
            
            return lesson_data
            
        except json.JSONDecodeError as e:
            print(f"JSON parse error: {e}")
            print(f"Response: {content_text[:200]}")
            # Return a fallback lesson
            return {
                'lesson': f"# {topic.title()}\n\nLesson content generation failed. Please try again.",
                'challenge': "Please try requesting this lesson again.",
                'tests': ["def test_placeholder():\n    assert True"],
                'metadata': {'error': str(e)}
            }
            
    except Exception as e:
        print(f"Bedrock invocation error: {e}")
        return {
            'lesson': f"# {topic.title()}\n\nUnable to generate lesson at this time.",
            'challenge': "Please try again later.",
            'tests': ["def test_placeholder():\n    assert True"],
            'metadata': {'error': str(e)}
        }


def cache_lesson(lesson_key: str, content: Dict, cost: float, source: str):
    """
    Cache lesson for future use
    TTL: 90 days (lessons don't change often)
    """
    try:
        CACHE_TABLE.put_item(Item={
            'lessonKey': lesson_key,
            'content': content,
            'source': source,  # 'static' or 'bedrock'
            'createdAt': int(time.time()),
            'ttl': int(time.time()) + (90 * 24 * 3600),  # 90 days
            'hitCount': 0,
            'totalCost': Decimal(str(cost))  # Convert float to Decimal for DynamoDB
        })
        print(f"✅ Cached lesson: {lesson_key}")
    except Exception as e:
        print(f"Cache write error: {e}")


def increment_cache_hit_count(lesson_key: str):
    """Track cache usage for analytics"""
    try:
        CACHE_TABLE.update_item(
            Key={'lessonKey': lesson_key},
            UpdateExpression='ADD hitCount :inc',
            ExpressionAttributeValues={':inc': 1}
        )
    except Exception as e:
        print(f"Failed to increment hit count: {e}")


def get_fallback_lesson(language: str, level: str) -> Optional[Dict]:
    """
    Get a fallback lesson when emergency mode is active
    Looks for the most basic lesson in the same language/level
    """
    try:
        # Try common topics as fallbacks
        fallback_topics = [
            'variables and data types',
            'basic syntax',
            'hello world',
            'getting started',
            'introduction'
        ]
        
        for topic in fallback_topics:
            fallback_key = generate_lesson_key(language, level, topic)
            cached_fallback = get_cached_lesson(fallback_key)
            if cached_fallback:
                print(f"Found fallback lesson: {fallback_key}")
                return cached_fallback
                
            # Also check static lessons
            static_fallback = get_static_lesson(language, level, topic)
            if static_fallback:
                print(f"Found static fallback lesson: {topic}")
                return static_fallback
        
        print(f"No fallback lesson found for {language}/{level}")
        return None
        
    except Exception as e:
        print(f"Error finding fallback lesson: {e}")
        return None


def cors_headers() -> Dict[str, str]:
    """CORS headers for API responses"""
    return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
    }


def error_response(status_code: int, message: str) -> Dict[str, Any]:
    """Generate error response"""
    return {
        'statusCode': status_code,
        'headers': cors_headers(),
        'body': json.dumps({'error': message})
    }