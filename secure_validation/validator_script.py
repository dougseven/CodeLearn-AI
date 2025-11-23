#!/usr/bin/env python3
"""
Secure validation script that runs inside the container
This script has minimal privileges and restricted environment
"""

import json
import os
import sys
import subprocess
import tempfile
import signal
import boto3
from typing import Dict, Any, List

# Timeout handler
def timeout_handler(signum, frame):
    print("TIMEOUT: Code execution exceeded time limit")
    sys.exit(1)

# Set timeout
signal.signal(signal.SIGALRM, timeout_handler)
signal.alarm(60)  # 60 seconds max

def main():
    """Main validation function"""
    try:
        execution_id = os.environ.get('EXECUTION_ID')
        s3_bucket = os.environ.get('S3_BUCKET')
        
        if not execution_id or not s3_bucket:
            print("ERROR: Missing required environment variables")
            sys.exit(1)
        
        # Download input from S3
        input_data = download_input(s3_bucket, execution_id)
        
        # Run validation
        results = run_validation(input_data)
        
        # Upload results
        upload_results(s3_bucket, execution_id, results)
        
        print("Validation completed successfully")
        
    except Exception as e:
        print(f"ERROR: {str(e)}")
        # Upload error results
        error_results = {
            'test_results': [{
                'name': 'container_error',
                'passed': False,
                'error': str(e)
            }]
        }
        try:
            upload_results(s3_bucket, execution_id, error_results)
        except:
            pass
        sys.exit(1)


def download_input(bucket: str, execution_id: str) -> Dict[str, Any]:
    """Download user code and tests from S3"""
    s3 = boto3.client('s3')
    
    s3_key = f"fargate-executions/{execution_id}/input.json"
    
    response = s3.get_object(Bucket=bucket, Key=s3_key)
    return json.loads(response['Body'].read())


def run_validation(input_data: Dict[str, Any]) -> Dict[str, Any]:
    """Run code validation in secure environment"""
    
    code = input_data['code']
    tests = input_data['tests']
    
    # Additional security checks
    if len(code) > 10000:
        raise ValueError("Code too long")
    
    # Create temporary directory for execution
    with tempfile.TemporaryDirectory() as tmpdir:
        # Write user code
        code_file = os.path.join(tmpdir, 'solution.py')
        with open(code_file, 'w') as f:
            f.write(code)
        
        # Write test file
        test_file = os.path.join(tmpdir, 'test_solution.py')
        test_content = 'from solution import *\n\n' + '\n\n'.join(tests)
        with open(test_file, 'w') as f:
            f.write(test_content)
        
        # Run tests with strict limits
        try:
            # Use subprocess with additional security
            result = subprocess.run(
                [sys.executable, '-m', 'pytest', test_file, '-v', '--tb=short', '--json-report', '--json-report-file=results.json'],
                cwd=tmpdir,
                capture_output=True,
                text=True,
                timeout=30,  # 30 second timeout for pytest
                env={
                    'HOME': tmpdir,
                    'TMPDIR': tmpdir,
                    'PYTHONPATH': tmpdir,
                    'PYTHONDONTWRITEBYTECODE': '1'
                }
            )
            
            # Parse results
            results_file = os.path.join(tmpdir, 'results.json')
            if os.path.exists(results_file):
                with open(results_file, 'r') as f:
                    pytest_results = json.load(f)
                
                test_results = []
                for test in pytest_results.get('tests', []):
                    test_results.append({
                        'name': test['nodeid'].split('::')[-1],
                        'passed': test['outcome'] == 'passed',
                        'error': format_error(test) if test['outcome'] == 'failed' else None
                    })
                
                return {'test_results': test_results}
            
            else:
                # Fallback: parse stdout
                return parse_stdout_results(result.stdout, result.stderr)
                
        except subprocess.TimeoutExpired:
            return {
                'test_results': [{
                    'name': 'timeout',
                    'passed': False,
                    'error': 'Test execution timeout'
                }]
            }
        except Exception as e:
            return {
                'test_results': [{
                    'name': 'execution_error',
                    'passed': False,
                    'error': str(e)[:200]  # Limit error message length
                }]
            }


def format_error(test_data: Dict[str, Any]) -> str:
    """Format test error message safely"""
    try:
        if 'call' in test_data and 'longrepr' in test_data['call']:
            error_msg = str(test_data['call']['longrepr'])
            # Limit error message length and remove sensitive info
            error_msg = error_msg[:300]
            # Remove potential path information
            error_msg = error_msg.replace('/workspace/', '').replace('/tmp/', '')
            return error_msg
    except:
        pass
    
    return 'Test failed'


def parse_stdout_results(stdout: str, stderr: str) -> Dict[str, Any]:
    """Fallback: parse pytest stdout output"""
    results = []
    
    for line in stdout.split('\n'):
        if '::test_' in line:
            test_name = line.split('::')[-1].split(' ')[0]
            passed = 'PASSED' in line
            
            error_msg = None
            if not passed:
                # Simple error message
                error_msg = 'Test failed'
                if 'FAILED' in line and stderr:
                    # Take first line of stderr, sanitized
                    first_error = stderr.split('\n')[0][:100]
                    if 'AssertionError' in first_error or 'Error' in first_error:
                        error_msg = first_error
            
            results.append({
                'name': test_name,
                'passed': passed,
                'error': error_msg
            })
    
    if not results:
        # No tests found
        if stderr:
            error_msg = stderr.split('\n')[0][:200]
        else:
            error_msg = 'No tests executed'
            
        results = [{
            'name': 'execution',
            'passed': False,
            'error': error_msg
        }]
    
    return {'test_results': results}


def upload_results(bucket: str, execution_id: str, results: Dict[str, Any]) -> None:
    """Upload results to S3"""
    s3 = boto3.client('s3')
    
    s3_key = f"fargate-executions/{execution_id}/results.json"
    
    # Also output to logs for debugging
    print(f"TEST_RESULTS: {json.dumps(results)}")
    
    s3.put_object(
        Bucket=bucket,
        Key=s3_key,
        Body=json.dumps(results),
        ServerSideEncryption='AES256'
    )


if __name__ == '__main__':
    main()