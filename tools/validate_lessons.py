#!/usr/bin/env python3
"""
Validate all static lesson JSON files
Checks for:
- Valid JSON syntax
- Required fields present
- Reasonable content length
- No template placeholders
"""

import json
import sys
from pathlib import Path

def validate_lesson(filepath: Path) -> list:
    """Validate a single lesson file, return list of errors"""
    errors = []
    
    try:
        # Try to parse JSON
        with open(filepath, 'r') as f:
            lesson = json.load(f)
        
        # Check required fields
        required_fields = ['lesson', 'challenge', 'tests']
        for field in required_fields:
            if field not in lesson:
                errors.append(f"Missing required field: {field}")
        
        # Check lesson content
        if 'lesson' in lesson:
            lesson_text = lesson['lesson']
            if len(lesson_text) < 100:
                errors.append("Lesson content is too short (< 100 characters)")
            
            # Check for template placeholders
            placeholders = ['[Write', '[Explain', '[Describe', '[TODO', '[Add']
            for placeholder in placeholders:
                if placeholder in lesson_text:
                    errors.append(f"Lesson contains template placeholder: {placeholder}")
        
        # Check challenge
        if 'challenge' in lesson:
            challenge_text = lesson['challenge']
            if len(challenge_text) < 50:
                errors.append("Challenge is too short (< 50 characters)")
            
            placeholders = ['[Requirement', '[TODO', '[Add']
            for placeholder in placeholders:
                if placeholder in challenge_text:
                    errors.append(f"Challenge contains template placeholder: {placeholder}")
        
        # Check tests
        if 'tests' in lesson:
            tests = lesson['tests']
            if not isinstance(tests, list):
                errors.append("Tests must be a list")
            elif len(tests) < 1:
                errors.append("At least one test case required")
            else:
                for i, test in enumerate(tests):
                    # Check if test is just a placeholder
                    if 'TODO' in test or ('assert True' in test and len(test) < 100):
                        errors.append(f"Test {i+1} appears to be a placeholder")
        
    except json.JSONDecodeError as e:
        errors.append(f"Invalid JSON: {e}")
    except Exception as e:
        errors.append(f"Error reading file: {e}")
    
    return errors

def main():
    """Validate all lesson files in static_lessons directory"""
    
    print("🔍 Validating Static Lessons")
    print("=" * 50)
    print()
    
    lessons_dir = Path("static_lessons")
    if not lessons_dir.exists():
        print("❌ static_lessons directory not found")
        sys.exit(1)
    
    # Find all JSON files
    json_files = list(lessons_dir.glob("**/*.json"))
    
    if not json_files:
        print("⚠️  No lesson files found")
        sys.exit(1)
    
    total_files = 0
    total_errors = 0
    valid_files = 0
    
    # Validate each file
    for filepath in sorted(json_files):
        total_files += 1
        errors = validate_lesson(filepath)
        
        # Calculate relative path for display
        try:
            rel_path = filepath.relative_to(Path.cwd())
        except ValueError:
            # If filepath is already relative or not under cwd, just use it as-is
            rel_path = filepath
        
        if errors:
            print(f"❌ {rel_path}")
            for error in errors:
                print(f"   - {error}")
            total_errors += len(errors)
        else:
            print(f"✅ {rel_path}")
            valid_files += 1
    
    # Summary
    print()
    print("=" * 50)
    print(f"Validated: {total_files} files")
    print(f"Valid: {valid_files}")
    print(f"Errors: {total_errors}")
    
    if total_errors > 0:
        print()
        print("⚠️  Please fix the errors above before uploading to S3")
        sys.exit(1)
    else:
        print()
        print("✅ All lessons are valid!")
        print()
        print("Ready to upload:")
        print("  ./tools/s3-manager.sh sync-lessons")
        sys.exit(0)

if __name__ == '__main__':
    main()
