#!/usr/bin/env python3
"""
Secure code validation using ECS Fargate
Alternative approach with even more isolation than CodeBuild
"""

import json
import os
import boto3
import time
import uuid
from typing import Dict, Any, List, Optional
from botocore.exceptions import ClientError

# AWS clients
ecs = boto3.client('ecs')
s3 = boto3.client('s3')
logs = boto3.client('logs')

# Configuration
ECS_CLUSTER = os.environ.get('VALIDATION_CLUSTER', 'codelearn-validation')
TASK_DEFINITION = os.environ.get('VALIDATION_TASK_DEF', 'codelearn-validator')
SUBNETS = os.environ.get('VALIDATION_SUBNETS', '').split(',')
SECURITY_GROUPS = os.environ.get('VALIDATION_SECURITY_GROUPS', '').split(',')
VALIDATION_BUCKET = os.environ.get('VALIDATION_BUCKET', 'codelearn-validation-temp')

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Secure code validation using ECS Fargate
    """
    try:
        body = json.loads(event.get('body', '{}'))
        
        code = body.get('code', '')
        tests = body.get('tests', [])
        language = body.get('language', 'python')
        lesson_id = body.get('lessonId')
        user_id = body.get('userId', 'anonymous')
        
        # Input validation (same as CodeBuild version)
        validation_error = validate_inputs(code, tests, language)
        if validation_error:
            return error_response(400, validation_error)
        
        security_error = validate_code_security(code, tests)
        if security_error:
            return error_response(403, f'Security violation: {security_error}')
        
        # Execute in isolated Fargate task
        execution_id = str(uuid.uuid4())
        results = execute_in_fargate(code, tests, execution_id)
        
        all_passed = all(r.get('passed', False) for r in results)
        
        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({
                'passed': all_passed,
                'results': results,
                'executionId': execution_id
            })
        }
        
    except Exception as e:
        print(f"Validation error: {str(e)}")
        return error_response(500, 'Internal validation error')


def validate_inputs(code: str, tests: List[str], language: str) -> Optional[str]:
    """Validate basic input parameters - same as CodeBuild version"""
    if not code or not code.strip():
        return 'Code cannot be empty'
    
    if len(code) > 10000:  # 10KB max
        return 'Code too long'
    
    if not tests:
        return 'At least one test is required'
    
    if language != 'python':
        return f'Language {language} not supported'
    
    return None


def validate_code_security(code: str, tests: List[str]) -> Optional[str]:
    """Security validation - same as CodeBuild version"""
    forbidden_imports = [
        'os', 'sys', 'subprocess', 'socket', 'urllib', 'requests', 
        'boto3', 'http', 'ftplib', 'smtplib', '__import__', 'eval', 'exec'
    ]
    
    code_lower = code.lower()
    all_test_code = '\n'.join(tests).lower()
    
    for forbidden in forbidden_imports:
        if forbidden in code_lower or forbidden in all_test_code:
            return f'Forbidden import/function: {forbidden}'
    
    return None


def execute_in_fargate(code: str, tests: List[str], execution_id: str) -> List[Dict[str, Any]]:
    """Execute code in secure Fargate container"""
    
    try:
        # Upload code to S3
        upload_execution_data(code, tests, execution_id)
        
        # Run Fargate task
        task_arn = start_fargate_task(execution_id)
        
        # Wait for completion
        results = wait_for_fargate_completion(task_arn, execution_id)
        
        # Clean up
        cleanup_execution_files(execution_id)
        
        return results
        
    except Exception as e:
        print(f"Fargate execution error: {str(e)}")
        return [{
            'name': 'execution_error',
            'passed': False,
            'error': 'Container execution failed'
        }]


def upload_execution_data(code: str, tests: List[str], execution_id: str) -> None:
    """Upload execution data to S3"""
    execution_data = {
        'code': code,
        'tests': tests,
        'timestamp': int(time.time())
    }
    
    s3_key = f"fargate-executions/{execution_id}/input.json"
    s3.put_object(
        Bucket=VALIDATION_BUCKET,
        Key=s3_key,
        Body=json.dumps(execution_data),
        ServerSideEncryption='AES256'
    )


def start_fargate_task(execution_id: str) -> str:
    """Start secure Fargate task for code validation"""
    
    response = ecs.run_task(
        cluster=ECS_CLUSTER,
        taskDefinition=TASK_DEFINITION,
        launchType='FARGATE',
        platformVersion='1.4.0',  # Latest platform version
        
        networkConfiguration={
            'awsvpcConfiguration': {
                'subnets': SUBNETS,
                'securityGroups': SECURITY_GROUPS,
                'assignPublicIp': 'DISABLED'  # No internet access
            }
        },
        
        overrides={
            'containerOverrides': [
                {
                    'name': 'validator',
                    'environment': [
                        {
                            'name': 'EXECUTION_ID',
                            'value': execution_id
                        },
                        {
                            'name': 'S3_BUCKET',
                            'value': VALIDATION_BUCKET
                        }
                    ]
                }
            ]
        },
        
        tags=[
            {
                'key': 'Purpose',
                'value': 'CodeValidation'
            },
            {
                'key': 'ExecutionId',
                'value': execution_id
            }
        ]
    )
    
    return response['tasks'][0]['taskArn']


def wait_for_fargate_completion(task_arn: str, execution_id: str, max_wait: int = 300) -> List[Dict[str, Any]]:
    """Wait for Fargate task completion and get results"""
    
    start_time = time.time()
    
    while time.time() - start_time < max_wait:
        try:
            # Check task status
            response = ecs.describe_tasks(
                cluster=ECS_CLUSTER,
                tasks=[task_arn]
            )
            
            if not response['tasks']:
                break
                
            task = response['tasks'][0]
            last_status = task.get('lastStatus', '')
            
            if last_status == 'STOPPED':
                # Task completed, get results
                return get_fargate_results(execution_id, task_arn)
            
            time.sleep(3)
            
        except Exception as e:
            print(f"Error checking task status: {e}")
            break
    
    # Timeout - stop the task
    try:
        ecs.stop_task(cluster=ECS_CLUSTER, task=task_arn, reason='Timeout')
    except:
        pass
    
    return [{
        'name': 'execution_timeout',
        'passed': False,
        'error': 'Task execution timeout'
    }]


def get_fargate_results(execution_id: str, task_arn: str) -> List[Dict[str, Any]]:
    """Get execution results from S3 or CloudWatch logs"""
    
    try:
        # Try to get results from S3 first
        s3_key = f"fargate-executions/{execution_id}/results.json"
        response = s3.get_object(Bucket=VALIDATION_BUCKET, Key=s3_key)
        results = json.loads(response['Body'].read())
        return results.get('test_results', [])
        
    except ClientError:
        # Fallback: try to parse CloudWatch logs
        return parse_logs_for_results(task_arn)


def parse_logs_for_results(task_arn: str) -> List[Dict[str, Any]]:
    """Parse CloudWatch logs as fallback for results"""
    
    try:
        # Extract task ID from ARN
        task_id = task_arn.split('/')[-1]
        log_group = f'/ecs/{TASK_DEFINITION}'
        log_stream = f'ecs/validator/{task_id}'
        
        response = logs.get_log_events(
            logGroupName=log_group,
            logStreamName=log_stream
        )
        
        # Look for test results in logs
        for event in response.get('events', []):
            message = event.get('message', '')
            if 'TEST_RESULTS:' in message:
                try:
                    results_json = message.split('TEST_RESULTS:')[1].strip()
                    return json.loads(results_json)
                except:
                    pass
        
    except Exception as e:
        print(f"Log parsing error: {e}")
    
    return [{
        'name': 'results_unavailable',
        'passed': False,
        'error': 'Could not retrieve test results'
    }]


def cleanup_execution_files(execution_id: str) -> None:
    """Clean up temporary S3 files"""
    try:
        response = s3.list_objects_v2(
            Bucket=VALIDATION_BUCKET,
            Prefix=f"fargate-executions/{execution_id}/"
        )
        
        if 'Contents' in response:
            delete_objects = [{'Key': obj['Key']} for obj in response['Contents']]
            s3.delete_objects(
                Bucket=VALIDATION_BUCKET,
                Delete={'Objects': delete_objects}
            )
    except Exception as e:
        print(f"Cleanup error: {e}")


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