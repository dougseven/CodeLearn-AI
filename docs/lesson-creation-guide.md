# Static Lesson Creation Guide

## Why Create Static Lessons?

Each static lesson saves ~$0.05 per view (compared to AI generation).
- 20 lessons ~100 views each = Save $100/month!
- Goal: Create 20-30 high-quality static lessons

## Lesson Structure

Each lesson is a JSON file with three required fields:

```json
{
  "lesson": "Markdown content with # headers, code blocks, etc.",
  "challenge": "Clear coding task description",
  "tests": ["test1 code", "test2 code", "test3 code"]
}
```

## Writing the Lesson Content

### Format
- Use Markdown with proper headers (#, ##, ###)
- Include code examples in \`\`\`language blocks
- Keep it concise (500-1000 words)
- Focus on one concept at a time

### Structure
1. **Introduction** - What is this concept?
2. **Syntax** - How to use it (2-3 examples)
3. **Key Points** - Bullet list of important info
4. **Common Mistakes** - What to avoid
5. **Practice** - Encourage trying the code

### Example Template
```markdown
# Topic Name in Language

## Introduction
[2-3 sentences explaining the concept]

## Syntax
\`\`\`python
# Example 1: Basic usage
\`\`\`

\`\`\`python
# Example 2: Common pattern
\`\`\`

## Key Points
- Point 1
- Point 2
- Point 3

## Common Mistakes
[What beginners often get wrong]
```

## Writing the Challenge

### Requirements
- Clear, specific task description
- Achievable with knowledge from the lesson
- 3-5 requirements
- Takes 5-15 minutes to complete

### Example
```
Create a function that calculates the area of a rectangle.

Requirements:
1. Function should be named calculate_area
2. Takes two parameters: width and height
3. Returns the calculated area (width à— height)
4. Handle the case where width or height is zero
```

## Writing Test Cases

### Format
- Python test functions using pytest conventions
- Name: `def test_something():`
- Use assertions to check correctness

### Tips
- Write 3-5 test cases
- Cover: basic case, edge case, error case
- Be specific in error messages
- Test incrementally (easy → hard)

### Example
```python
def test_basic_calculation():
    assert calculate_area(5, 10) == 50, "Should return 50 for 5x10"

def test_zero_dimensions():
    assert calculate_area(0, 10) == 0, "Should return 0 when width is 0"
    assert calculate_area(5, 0) == 0, "Should return 0 when height is 0"

def test_decimal_numbers():
    assert calculate_area(2.5, 4.0) == 10.0, "Should work with decimals"
```

## Validation Checklist

Before saving a lesson:

- [ ] Lesson content is >500 words
- [ ] Includes 2+ code examples
- [ ] Has clear explanations
- [ ] No template placeholders like [Write]
- [ ] Challenge is clear and achievable
- [ ] 3+ test cases that actually test something
- [ ] JSON is valid (use a JSON validator)
- [ ] Tests use proper assertions

## Quick Creation Process

1. **Generate Template**
   ```bash
   python3 tools/generate_lesson_template.py python beginner "topic name"
   ```

2. **Fill In Content**
   - Open the JSON file in VSCode
   - Replace template placeholders with real content
   - Save frequently

3. **Validate**
   ```bash
   python3 tools/validate_lessons.py
   ```

4. **Upload**
   ```bash
   ./tools/s3-manager.sh sync-lessons
   ```

## Priority Lessons to Create

### Python Beginner (10 lessons)
1. ✅ Variables and data types
2. ⬜ Basic operators
3. ⬜ Conditionals (if/elif/else)
4. ⬜ Loops (for and while)
5. ⬜ Functions
6. ⬜ Lists
7. ⬜ Dictionaries
8. ⬜ String methods
9. ⬜ File I/O
10. ⬜ Error handling

### Java Beginner (5 lessons)
1. ⬜ Variables and data types
2. ⬜ Conditionals
3. ⬜ Loops
4. ⬜ Methods
5. ⬜ Arrays

### Rust Beginner (5 lessons)
1. ⬜ Variables and mutability
2. ⬜ Data types
3. ⬜ Functions
4. ⬜ Control flow
5. ⬜ Ownership basics

## Tips for Quality

- **Be Beginner-Friendly**: Assume no prior knowledge
- **Use Simple Language**: Avoid jargon when possible
- **Provide Context**: Explain WHY, not just HOW
- **Real Examples**: Use practical, relatable examples
- **Incremental**: Build on previous concepts

## Testing Your Lessons

After creating a lesson, test it:

1. Read through as if you're a beginner
2. Try the code examples yourself
3. Complete the challenge
4. Run the tests

If something is confusing to you, it'll be confusing to users!

## Batch Processing

To create many lessons efficiently:

```bash
# Generate all templates at once
for topic in "topic1" "topic2" "topic3"; do
    python3 tools/generate_lesson_template.py python beginner "$topic"
done

# Then fill them in one by one
# Validate periodically
python3 tools/validate_lessons.py

# Upload when done
./tools/s3-manager.sh sync-lessons
```

## Cost Impact

Creating static lessons is a one-time effort that saves money forever:

- **Time Investment**: 30-60 minutes per lesson
- **Total Time**: 10-20 hours for 20 lessons
- **Monthly Savings**: $10-20/month in Bedrock costs
- **Payback Period**: Immediate!

## Need Help?

If stuck:
1. Look at `variables_and_data_types.json` as an example
2. Keep it simple - better to have working lessons than perfect ones
3. You can always improve lessons later