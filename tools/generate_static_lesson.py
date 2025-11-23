#!/usr/bin/env python3
"""
Generate static lesson template
Usage: py
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


bedrock_client = create_bedrock_client()


DEVELOPER_PERSONA = "You are CodeLearn AI, a master software development tutor. If the topic is for experience level users, you MUST compare concepts to their C# equivalents (e.g., Python 'dict' is like C# 'Dictionary<TKey, TValue>', Python 'list' is like 'List<T>')."


def generate_lesson_template(language, level, topic):
    """Generate a lesson plan using AWS Bedrock Claude model.
        Args:
            language (str): The programming language (e.g., python, javascript)
            level (str): The experience level (e.g., beginner, intermediate, advanced)
            topic (str): The topic to generate a lesson for

        Returns:
            dict: Lesson plan with keys: lesson_html, challenge_py, test_py
            None: If generation fails
    """

    # This prompt asks for a JSON object with three keys.
    prompt = f"""
{DEVELOPER_PERSONA}

Your task is to generate a complete lesson plan on the topic: "{topic.title()}".
You MUST respond with ONLY a valid, minified JSON object on a single line. All newlines in strings must be escaped as \\n. No formatting, indentation, or whitespace outside of string values. Do not include any text before or after the JSON.

The JSON object must have three keys:
1. "lesson_html": A string of simple HTML (paragraphs, code blocks) explaining the topic. Compare it to C# equivalents.
2. "challenge_py": A string of Python code. This is the "challenge" for the student. It should contain one function stub (e.g., 'def my_function(param): pass') and a clear comment explaining what the function must do.
3. "test_py": A string of Python code. This is a 'pytest' file. It must 'import' the challenge function from a file named 'solution.py' and include 2-3 unit tests to validate it.

Example JSON:
{{"lesson_html":"<p>A Python 'dict'...</p><code>...</code>","challenge_py":"def count_words(text):\n  \"\"\"Counts words...\"\"\"\n  pass","test_py":"from solution import count_words\n\ndef test_count_words():\n  assert count_words('hi') == {{'hi': 1}}"}}

Generate the lesson plan for the topic: "{topic.title()}"
"""
    print("Calling Bedrock (Claude 3 Haiku)...")

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
        response = bedrock_client.invoke_model(
            body=body,
            modelId='us.anthropic.claude-3-5-haiku-20241022-v1:0',  # Fast and cheap
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
        cleaned_json = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\x9f]', '', cleaned_json)
        
        try:
            # The AI *should* return valid JSON, so we parse it
            lesson_plan = json.loads(cleaned_json)
            # Create directory
            dir_path = f"static_Lessons/{language}/{level}"
            os.makedirs(dir_path, exist_ok=True)

            # Save file
            filename = f"{dir_path.lower()}/{topic.lower().replace(' ','_')}.json"
            with open(filename, 'w') as f:
                json.dump(lesson_plan, f, indent=4)

            print(f"Generated lesson template at {filename}")
            print(f"\nNext steps:")
            print(f"1. Verify the lesson content in {filename}.")
            print(f"2. Upload to S3: aws s3 cp {filename} s3://codelearn-static-lessons/static/{language}/{level}/")
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
        print("Usage: python generate_static_lesson.py <language> <level> <topic>")
        print("Example: python generate_static_lesson.py python beginner loops")
        sys.exit(1)

    language = sys.argv[1]
    level = sys.argv[2]
    topic = sys.argv[3]

    generate_lesson_template(language, level, topic)