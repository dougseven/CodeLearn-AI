#!/usr/bin/env python3
"""
Secure code validation using AWS CodeBuild
This replaces the dangerous direct code execution with isolated container execution
"""

import json
import os
import boto3
import time
from typing import Dict, Any, List, Optional
from botocore.exceptions import ClientError

# AWS clients
codebuild = boto3.client('codebuild')
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

# Configuration from environment
CODEBUILD_PROJECT = os.environ.get('VALIDATION_PROJECT', 'codelearn-validation')
VALIDATION_BUCKET = os.environ.get('VALIDATION_BUCKET', 'codelearn-validation-temp')
PROGRESS_TABLE = os.environ.get('PROGRESS_TABLE', 'codelearn-progress-dev')
MAX_EXECUTION_TIME = 300  # 5 minutes max

# Security constraints
MAX_CODE_LENGTH = 10000  # 10KB max
FORBIDDEN_IMPORTS = [
    'os', 'sys', 'subprocess', 'socket', 'urllib', 'requests', 
    'boto3', 'http', 'ftplib', 'smtplib', '__import__', 'eval', 'exec'
]

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Secure code validation orchestrator
    """
    try:
        body = json.loads(event.get('body', '{}'))
        
        code = body.get('code', '')
        tests = body.get('tests', [])
        language = body.get('language', 'python')
        lesson_id = body.get('lessonId')
        user_id = body.get('userId', 'anonymous')
        
        # Input validation
        validation_error = validate_inputs(code, tests, language)
        if validation_error:
            return error_response(400, validation_error)
        
        # Security validation
        security_error = validate_code_security(code, tests)
        if security_error:
            return error_response(403, f'Security violation: {security_error}')
        
        # Execute in secure container
        execution_id = f"{user_id}_{lesson_id}_{int(time.time())}"
        results = execute_code_securely(code, tests, language, execution_id)
        
        # Track progress if all tests passed
        all_passed = all(r.get('passed', False) for r in results)
        if all_passed and lesson_id:
            track_progress(user_id, lesson_id)
        
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({
                'passed': all_passed,
                'results': results,
                'executionId': execution_id,
                'feedback': generate_feedback(results)
            })
        }
        
    except Exception as e:
        print(f"Validation error: {str(e)}")
        return error_response(500, 'Internal validation error')


def validate_inputs(code: str, tests: List[str], language: str) -> Optional[str]:
    """Validate basic input parameters"""
    if not code or not code.strip():
        return 'Code cannot be empty'
    
    if len(code) > MAX_CODE_LENGTH:
        return f'Code too long (max {MAX_CODE_LENGTH} characters)'
    
    if not tests:
        return 'At least one test is required'
    
    if language != 'python':
        return f'Language {language} not supported'
    
    return None


def validate_code_security(code: str, tests: List[str]) -> Optional[str]:
    """Security validation to prevent malicious code"""
    
    # Check for forbidden imports/functions
    code_lower = code.lower()
    for forbidden in FORBIDDEN_IMPORTS:
        if forbidden in code_lower:
            return f'Forbidden import/function: {forbidden}'
    
    # Check tests as well
    all_test_code = '\n'.join(tests).lower()
    for forbidden in FORBIDDEN_IMPORTS:
        if forbidden in all_test_code:
            return f'Forbidden import/function in tests: {forbidden}'
    
    # Check for suspicious patterns
    suspicious_patterns = ['__', 'getattr', 'setattr', 'delattr', 'globals', 'locals']
    for pattern in suspicious_patterns:
        if pattern in code_lower or pattern in all_test_code:
            return f'Suspicious pattern detected: {pattern}'
    
    return None


def execute_code_securely(code: str, tests: List[str], language: str, execution_id: str) -> List[Dict[str, Any]]:
    """Execute code in secure CodeBuild environment"""
    
    try:
        # Upload code to S3 for CodeBuild
        upload_code_to_s3(code, tests, execution_id)
        
        # Start CodeBuild execution
        build_id = start_codebuild_execution(execution_id)
        
        # Wait for completion and get results
        results = wait_for_execution_results(build_id, execution_id)
        
        # Clean up temporary files
        cleanup_execution_files(execution_id)
        
        return results
        
    except Exception as e:
        print(f"Execution error: {str(e)}")
        return [{
            'name': 'execution_error',
            'passed': False,
            'error': 'Code execution failed'
        }]


def upload_code_to_s3(code: str, tests: List[str], execution_id: str) -> None:
    """Upload user code and tests to S3 for CodeBuild"""
    
    # Create execution package
    execution_data = {
        'code': code,
        'tests': tests,
        'timestamp': int(time.time())
    }
    
    # Upload to S3
    s3_key = f"executions/{execution_id}/input.json"
    s3.put_object(
        Bucket=VALIDATION_BUCKET,
        Key=s3_key,
        Body=json.dumps(execution_data),
        ServerSideEncryption='AES256'
    )


def start_codebuild_execution(execution_id: str) -> str:
    """Start CodeBuild project for secure execution"""
    
    response = codebuild.start_build(
        projectName=CODEBUILD_PROJECT,
        environmentVariablesOverride=[
            {
                'name': 'EXECUTION_ID',
                'value': execution_id
            },
            {
                'name': 'S3_BUCKET',
                'value': VALIDATION_BUCKET
            }
        ],
        timeoutInMinutesOverride=5  # Max 5 minutes
    )
    
    return response['build']['id']


def wait_for_execution_results(build_id: str, execution_id: str, max_wait: int = 300) -> List[Dict[str, Any]]:
    """Wait for CodeBuild execution and retrieve results"""
    
    start_time = time.time()
    
    while time.time() - start_time < max_wait:
        try:
            # Check build status
            response = codebuild.batch_get_builds(ids=[build_id])
            build = response['builds'][0]
            
            status = build['buildStatus']
            
            if status == 'SUCCEEDED':
                # Get results from S3
                return get_execution_results(execution_id)
            elif status in ['FAILED', 'STOPPED', 'TIMED_OUT']:
                return [{
                    'name': 'execution_failed',
                    'passed': False,
                    'error': f'Build {status.lower()}'
                }]
            
            # Still running, wait a bit
            time.sleep(2)
            
        except Exception as e:
            print(f"Error checking build status: {e}")
            break
    
    # Timeout
    return [{
        'name': 'execution_timeout',
        'passed': False,
        'error': 'Execution timeout'
    }]


def get_execution_results(execution_id: str) -> List[Dict[str, Any]]:
    """Retrieve execution results from S3"""
    
    try:
        s3_key = f"executions/{execution_id}/results.json"
        response = s3.get_object(Bucket=VALIDATION_BUCKET, Key=s3_key)
        results = json.loads(response['Body'].read())
        return results.get('test_results', [])
    except ClientError:
        return [{
            'name': 'results_error',
            'passed': False,
            'error': 'Could not retrieve results'
        }]


def cleanup_execution_files(execution_id: str) -> None:
    """Clean up temporary S3 files"""
    
    try:
        # List and delete execution files
        response = s3.list_objects_v2(
            Bucket=VALIDATION_BUCKET,
            Prefix=f"executions/{execution_id}/"
        )
        
        if 'Contents' in response:
            delete_objects = [{'Key': obj['Key']} for obj in response['Contents']]
            s3.delete_objects(
                Bucket=VALIDATION_BUCKET,
                Delete={'Objects': delete_objects}
            )
    except Exception as e:
        print(f"Cleanup error: {e}")


def track_progress(user_id: str, lesson_id: str) -> None:
    """Track lesson completion in DynamoDB"""
    
    try:
        table = dynamodb.Table(PROGRESS_TABLE)
        table.put_item(Item={
            'userId': user_id,
            'lessonId': lesson_id,
            'completedAt': int(time.time()),
            'status': 'completed'
        })
    except Exception as e:
        print(f"Progress tracking error: {e}")


def generate_feedback(results: List[Dict[str, Any]]) -> str:
    """Generate helpful feedback based on results"""
    
    passed_count = sum(1 for r in results if r.get('passed', False))
    total_count = len(results)
    
    if passed_count == total_count:
        return "🎉 Excellent! All tests passed!"
    elif passed_count == 0:
        return "❌ No tests passed. Review your code and try again."
    else:
        return f"✅ {passed_count}/{total_count} tests passed. You're getting close!"


def cors_headers() -> Dict[str, str]:
    """CORS headers for API responses"""
    return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
    }


def error_response(status_code: int, message: str) -> Dict[str, Any]:
    """Generate error response"""
    return {
        'statusCode': status_code,
        'headers': cors_headers(),
        'body': json.dumps({'error': message})
    }