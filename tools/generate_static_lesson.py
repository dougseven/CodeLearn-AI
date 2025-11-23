#!/usr/bin/env python3
"""
Generate static lesson template
Usage: python ./tools/generate_static_lesson.py <language> <level> <topic>

Environment Variables:
    BEDROCK_MODEL_ID: AWS Bedrock model ID to use (default: claude-3-5-haiku)
                     Example: us.anthropic.claude-3-5-haiku-20241022-v1:0
    
To set the model ID:
    # For current session:
    export BEDROCK_MODEL_ID="us.anthropic.claude-3-5-haiku-20241022-v1:0"
    
    # For permanent (add to ~/.bashrc, ~/.zshrc, or ~/.profile):
    echo 'export BEDROCK_MODEL_ID="us.anthropic.claude-3-5-haiku-20241022-v1:0"' >> ~/.bashrc
    
    # For this script only:
    BEDROCK_MODEL_ID="us.anthropic.claude-3-5-haiku-20241022-v1:0" python ./tools/generate_static_lesson.py python beginner loops
"""

import os
import sys
import boto3
import json

from botocore.exceptions import ClientError

# Use the Bedrock runtime client


def create_bedrock_client(profile_name=None, region_name='us-east-1'):
    """Create Bedrock client with explicit session configuration."""
    try:
        if profile_name:
            session = boto3.Session(profile_name=profile_name)
        else:
            session = boto3.Session()

        return session.client(
            service_name='bedrock-runtime',
            region_name=region_name
        )
    except Exception as e:
        print(f"Failed to create Bedrock client: {e}")
        return None


# Configuration
# Fast and cheap default
DEFAULT_MODEL_ID = 'us.anthropic.claude-3-5-haiku-20241022-v1:0'
MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', DEFAULT_MODEL_ID)

bedrock_client = create_bedrock_client()


DEVELOPER_PERSONA = "You are CodeLearn AI, a master software development tutor. Your task is to generate a complete, structured lesson plan."


def generate_lesson_template(language, level, topic):
    """Generate a lesson plan using AWS Bedrock Claude model.
        Args:
            language (str): The programming language (e.g., python, javascript)
            level (str): The experience level (e.g., beginner, intermediate, advanced)
            topic (str): The topic to generate a lesson for

        Returns:
            dict: Lesson plan with keys: lesson, challenge, tests
            None: If generation fails
    """

    # This prompt asks for a JSON object with three keys.
    prompt = f"""
{DEVELOPER_PERSONA}

Instructions: Generate a lesson plan for teaching {topic} in {language} at the {level} experience level.

You MUST respond with ONLY a valid, minified JSON object on a single line. Follow these rules strictly:

All newlines in strings must be escaped as \n
No formatting, indentation, or extra whitespace outside string values
Do not include any text before or after the JSON
If the level is intermediate or advanced, compare concepts to C# equivalents (e.g., Python dict → C# Dictionary<TKey, TValue>, Python list → C# List<T>)
JSON Structure
Return a JSON object with exactly three keys:

1. lesson (string)
Markdown-formatted educational content explaining the topic. Include:

Headings and introduction
Concept overview with clear explanations
Syntax with 2-3 code block examples (in the target language)
Key points (bulleted list)
Common mistakes and pitfalls
Practice exercises with hints
2. challenge (string)
Python code skeleton for students to solve. Include:

One function stub (e.g., def my_function(param): pass)
Clear comment explaining what the function must do
Requirements and constraints
3. tests (string)
Pytest test file that:

Imports the challenge function from a file named solution.py
Contains 2-3 unit tests covering basic functionality, edge cases, and error handling
Tests must be a list.
Example Output
{{"lesson": "# Topic Name\n\n## Introduction\n\n[content]\n\n## Concept Overview\n\n[Explain the main concept]\n\n## Syntax\n\n```python\n# Example 1: Basic usage\n```\n\n```python\n# Example 2: Common pattern\n```\n\n## Key Points\n\n- Point 1\n- Point 2\n- Point 3\n\n## Common Mistakes\n\n[Describe common pitfalls]\n\n## Practice\n\nTry these examples yourself:\n\n```python\n# Exercise hint\n```\n","challenge": "Create a program that demonstrates the topic.\n\nRequirements:\n1. [Requirement 1]\n2. [Requirement 2]\n3. [Requirement 3]\n\nYour code should handle edge cases and follow best practices.\n","tests": ["def test_basic():\n    # TODO: Add test for basic functionality\n    assert True","def test_edge_case():\n    # TODO: Add test for edge case\n    assert True","def test_error_handling():\n    # TODO: Add test for error handling\n    assert True"]}}

Generate the lesson for the topic: "{topic.title()}"
"""
    print("Calling Amazon Bedrock...")

    # Claude 3 models use the "messages" API
    messages = [
        {
            "role": "user",
            "content": [{"type": "text", "text": prompt}]
        }
    ]

    # Format the request body
    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 4096,
        "messages": messages,
        "temperature": 0.5,
        "top_p": 0.9,
    })

    # Invoke the model
    try:
        print(f"Using model: {MODEL_ID}")
        response = bedrock_client.invoke_model(
            body=body,
            modelId=MODEL_ID,
            accept='application/json',
            contentType='application/json'
        )

        # Parse the response
        response_body = json.loads(response.get('body').read())
        print(f"Input tokens: {response_body['usage']['input_tokens']}")
        print(f"Output tokens: {response_body['usage']['output_tokens']}")

        # The AI's response is in the 'content' block
        raw_json_text = response_body['content'][0]['text']

        # Clean up the JSON text to handle control characters and newlines
        import re

        # First, escape newlines and other control characters in string values
        cleaned_json = raw_json_text
        # Replace literal newlines with \n in JSON strings
        cleaned_json = cleaned_json.replace('\n', '\\n')
        cleaned_json = cleaned_json.replace('\r', '\\r')
        cleaned_json = cleaned_json.replace('\t', '\\t')

        # Remove other problematic control characters
        cleaned_json = re.sub(
            r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\x9f]', '', cleaned_json)

        try:
            # The AI *should* return valid JSON, so we parse it
            lesson_plan = json.loads(cleaned_json)
            # Create directory
            dir_path = f"static_Lessons/{language}/{level}"
            os.makedirs(dir_path, exist_ok=True)

            # Save file
            filename = f"{dir_path.lower()}/{topic.lower().replace(' ', '_')}.json"
            with open(filename, 'w') as f:
                json.dump(lesson_plan, f, indent=4)

            print(f"Generated lesson template at {filename}")
            print(f"\nNext steps:")
            print(f"1. Verify the lesson content in {filename}.")
            print(
                f"2. Upload to S3: aws s3 cp {filename} s3://codelearn-static-lessons/static/{language}/{level}/")
            return lesson_plan
        except json.JSONDecodeError as json_err:
            print(f"JSON parse error: {json_err}")
            print(f"Raw JSON first 200 chars: {raw_json_text[:200]}...")
            print(f"Cleaned JSON first 200 chars: {cleaned_json[:200]}...")
            return None

    except Exception as e:
        print("Error during Bedrock invocation:", e)
        return None


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python ./tools/generate_static_lesson.py <language> <level> <topic>")
        print("Example: python ./tools/generate_static_lesson.py python beginner loops")
        sys.exit(1)

    language = sys.argv[1]
    level = sys.argv[2]
    topic = sys.argv[3]

    generate_lesson_template(language, level, topic)
