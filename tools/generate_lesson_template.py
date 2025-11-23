#!/usr/bin/env python3
"""
Generate static lesson template
Usage: python tools/generate_lesson_template.py python beginner "variables and data types"
"""

import json
import sys
import os
from pathlib import Path

def generate_lesson_template(language: str, level: str, topic: str):
    """Generate lesson template with proper structure"""
    
    # Create the lesson structure
    lesson_data = {
        "lesson": f"""# {topic.title()} in {language.title()}

## Introduction

[Write a brief introduction to {topic}]

## Concept Overview

[Explain the main concept]

## Syntax

```{language}
# Example 1: Basic usage
```

```{language}
# Example 2: Common pattern
```

## Key Points

- Point 1
- Point 2
- Point 3

## Common Mistakes

[Describe common pitfalls]

## Practice

Try these examples yourself:

```{language}
# Exercise hint
```
""",
        
        "challenge": f"""Create a program that demonstrates {topic}.

Requirements:
1. [Requirement 1]
2. [Requirement 2]
3. [Requirement 3]

Your code should handle edge cases and follow best practices.
""",
        
        "tests": [
            "def test_basic():\n    # TODO: Add test for basic functionality\n    assert True",
            "def test_edge_case():\n    # TODO: Add test for edge case\n    assert True",
            "def test_error_handling():\n    # TODO: Add test for error handling\n    assert True"
        ]
    }
    
    # Create directory structure
    lesson_dir = Path(f"static_lessons/{language}/{level}")
    lesson_dir.mkdir(parents=True, exist_ok=True)
    
    # Create filename (replace spaces with underscores)
    filename = lesson_dir / f"{topic.replace(' ', '_').replace('-', '_')}.json"
    
    # Save the file
    with open(filename, 'w') as f:
        json.dump(lesson_data, f, indent=2)
    
    print(f"✅ Created template: {filename}")
    print(f"\nNext steps:")
    print(f"1. Edit {filename}")
    print(f"2. Fill in the lesson content, examples, and tests")
    print(f"3. Verify JSON is valid")
    print(f"4. Upload: ./tools/s3-manager.sh sync-lessons")
    
    return filename

def main():
    if len(sys.argv) != 4:
        print("Usage: python generate_lesson_template.py <language> <level> <topic>")
        print('Example: python tools/generate_lesson_template.py python beginner "variables and data types"')
        sys.exit(1)
    
    language = sys.argv[1].lower()
    level = sys.argv[2].lower()
    topic = sys.argv[3].lower()
    
    # Validate inputs
    valid_languages = ['python', 'java', 'rust']
    valid_levels = ['beginner', 'intermediate', 'advanced']
    
    if language not in valid_languages:
        print(f"❌ Invalid language. Choose from: {', '.join(valid_languages)}")
        sys.exit(1)
    
    if level not in valid_levels:
        print(f"❌ Invalid level. Choose from: {', '.join(valid_levels)}")
        sys.exit(1)
    
    generate_lesson_template(language, level, topic)

if __name__ == '__main__':
    main()