# CodeLearn Platform: Budget-Optimized Implementation Guide
## Target: Under $25/Month

**Version:** 1.0  
**Date:** November 15, 2025  
**Budget Target:** $20-25/month for 100-500 active users

---

## Cost Breakdown Strategy

### Monthly Cost Estimate (Target Usage: 100-500 users)

| Service | Usage | Monthly Cost | Optimization Strategy |
|---------|-------|--------------|----------------------|
| **Lambda** | 50K invocations | **$0.50** | Free tier covers most, careful sizing |
| **API Gateway** | 50K requests | **$0.18** | Under free tier limit |
| **DynamoDB** | On-demand pricing | **$2.00** | Small dataset, efficient queries |
| **S3** | 2 GB storage | **$0.05** | Minimal storage needed |
| **CloudFront** | 20 GB transfer | **$0.00** | Within free tier |
| **Cognito** | 500 MAU | **$0.00** | Well under 50K free tier |
| **CloudWatch** | Basic monitoring | **$1.00** | Conservative log retention |
| **Bedrock (Claude)** | 20-30 lesson generations | **$15-18** | **KEY COST - Optimized usage** |
| **Certificate Manager** | SSL cert | **$0.00** | Free for CloudFront |
| **TOTAL** | | **$18.73 - $21.73** | ✅ Under $25! |

---

## Cost Optimization Strategies

### 1. Bedrock Usage Optimization (Biggest Cost Driver)

**Problem:** Bedrock costs ~$0.60 per full lesson generation (lesson + challenge + tests)

**Solution: Smart Caching + Hybrid Content**

#### Strategy A: Aggressive Lesson Caching

```python
import boto3
import hashlib
import json
import time

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
bedrock = boto3.client('bedrock-runtime')

CACHE_BUCKET = 'codelearn-lesson-cache'
CACHE_TABLE = dynamodb.Table('CodeLearn-LessonCache')

def get_or_generate_lesson(language: str, level: str, topic: str):
    """
    Check cache first, only generate if not cached
    This reduces Bedrock calls by 90%+
    """
    cache_key = f"{language}_{level}_{topic}"
    
    # Check DynamoDB cache first (faster than S3)
    try:
        response = CACHE_TABLE.get_item(Key={'lessonKey': cache_key})
        if 'Item' in response:
            print(f"Cache HIT: {cache_key}")
            return response['Item']['content']
    except Exception as e:
        print(f"Cache miss: {e}")
    
    # Generate new lesson (costs money!)
    print(f"Cache MISS: Generating lesson for {cache_key}")
    lesson_content = generate_lesson_with_bedrock(language, level, topic)
    
    # Cache for future use
    CACHE_TABLE.put_item(Item={
        'lessonKey': cache_key,
        'content': lesson_content,
        'createdAt': int(time.time()),
        'ttl': int(time.time()) + (90 * 24 * 3600)  # 90 day TTL
    })
    
    return lesson_content


def generate_lesson_with_bedrock(language: str, level: str, topic: str):
    """Generate lesson using Bedrock - COSTS MONEY"""
    
    # OPTIMIZATION: Use concise prompts to reduce token usage
    prompt = f"""Create a {language} lesson for {level} level on: {topic}

Requirements:
1. Brief explanation (200 words max)
2. 2 code examples
3. One coding challenge
4. 3 test cases

Format as JSON:
{{
  "lesson": "markdown content",
  "challenge": "problem description", 
  "tests": ["test1", "test2", "test3"]
}}"""

    response = bedrock.invoke_model(
        modelId='anthropic.claude-3-haiku-20240307-v1:0',  # CHEAPER MODEL
        body=json.dumps({
            "anthropic_version": "bedrock-2023-05-31",
            "messages": [{"role": "user", "content": prompt}],
            "max_tokens": 1500,  # LIMIT OUTPUT TOKENS
            "temperature": 0.7
        })
    )
    
    result = json.loads(response['body'].read())
    return json.loads(result['content'][0]['text'])
```

**Cost Savings:**
- Without caching: 1,000 lessons/month = $600 💸
- With caching (90% hit rate): 100 new lessons/month = $60 💸
- With caching + limited topics: 20 new lessons/month = $12 ✅

#### Strategy B: Use Cheaper Bedrock Models

| Model | Input Cost (per 1K tokens) | Output Cost (per 1K tokens) | Use Case |
|-------|---------------------------|----------------------------|----------|
| **Claude 3.5 Sonnet** | $0.003 | $0.015 | ❌ Premium - too expensive |
| **Claude 3 Haiku** | $0.00025 | $0.00125 | ✅ **BEST CHOICE** - 12x cheaper! |
| **Claude 3 Opus** | $0.015 | $0.075 | ❌ Most expensive |

**Using Claude 3 Haiku:**
- Lesson generation: ~$0.05 per lesson (vs $0.60 with Sonnet)
- 200 lessons/month = $10 (vs $120 with Sonnet)
- Quality is still excellent for educational content

#### Strategy C: Hybrid Content Model

**Mix static + dynamic content:**

```python
# Define a fixed curriculum with 30 core lessons
STATIC_LESSONS = [
    {'language': 'python', 'level': 'beginner', 'topic': 'variables'},
    {'language': 'python', 'level': 'beginner', 'topic': 'conditionals'},
    {'language': 'python', 'level': 'beginner', 'topic': 'loops'},
    # ... 27 more
]

# For topics outside the static curriculum, use AI
def get_lesson(language, level, topic):
    # Check if it's a core static lesson
    if is_static_lesson(language, level, topic):
        return load_static_lesson(language, level, topic)
    
    # Otherwise, generate with AI (and cache)
    return get_or_generate_lesson(language, level, topic)
```

**Cost Impact:**
- Create 30 static lessons manually: $0/month
- AI for advanced/custom topics: ~$5-10/month
- **Total Bedrock cost: $5-10/month** ✅

---

### 2. Lambda Optimization

#### Right-Size Memory Allocation

```python
# BEFORE (wasteful)
# Memory: 1024 MB
# Duration: 3 seconds
# Cost: $0.0000166667 per invocation

# AFTER (optimized)
# Memory: 512 MB (lesson generation doesn't need more)
# Duration: 3 seconds  
# Cost: $0.0000083333 per invocation
# Savings: 50%
```

#### Use Lambda Layers for Dependencies

```bash
# Create a layer with dependencies (reuse across functions)
mkdir python
pip install boto3 pytest PyJWT -t python/
zip -r dependencies-layer.zip python/

aws lambda publish-layer-version \
  --layer-name codelearn-dependencies \
  --zip-file fileb://dependencies-layer.zip \
  --compatible-runtimes python3.12
```

**Benefit:** Smaller deployment packages = faster cold starts = lower costs

#### Implement Smart Timeout Values

```python
# lesson_lambda - needs time for Bedrock
TIMEOUT = 60  # seconds

# validation_lambda - quick code execution
TIMEOUT = 15  # seconds

# auth_lambda - very fast
TIMEOUT = 10  # seconds

# user_lambda - database lookup only
TIMEOUT = 10  # seconds
```

---

### 3. DynamoDB Optimization

#### Use On-Demand Pricing (Best for Low Traffic)

```python
# For under 500 users, on-demand is cheaper than provisioned

# Estimated usage:
# - 10 writes per user per session = 5,000 writes/month
# - 50 reads per user per session = 25,000 reads/month

# Cost calculation:
# Writes: 5,000 × $1.25/million = $0.00625
# Reads: 25,000 × $0.25/million = $0.00625
# Storage: 0.1 GB × $0.25/GB = $0.025
# TOTAL: ~$0.04/month
```

#### Optimize Item Size

```python
# BAD: Storing entire lesson in progress table
{
    'userId': 'user123',
    'lessonId': 'lesson456',
    'lessonContent': '... 5KB of text ...',  # Wasteful!
    'completed': True
}

# GOOD: Store only metadata
{
    'userId': 'user123',
    'lessonId': 'lesson456',  # Reference only
    'completed': True,
    'attempts': 2,
    'completedAt': 1234567890
}
# Lesson content retrieved from cache on demand
```

#### Use TTL to Auto-Delete Old Sessions

```python
# Sessions table with automatic cleanup
{
    'sessionId': 'session123',
    'userId': 'user456',
    'createdAt': 1699999999,
    'expiresAt': 1700086399  # TTL - auto-deleted after 24 hours
}

# Saves storage costs - no manual cleanup needed
```

---

### 4. CloudWatch Logs Optimization

#### Reduce Log Retention

```bash
# Set shorter retention for non-critical logs
aws logs put-retention-policy \
  --log-group-name /aws/lambda/CodeLearn-Lesson \
  --retention-in-days 7  # Instead of 30 or forever

# Save ~70% on log storage costs
```

#### Structured Logging (Reduce Volume)

```python
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)  # Don't log DEBUG in production

def lambda_handler(event, context):
    # BEFORE: Verbose logging
    # print(f"Received event: {json.dumps(event)}")  # 2KB per invocation
    
    # AFTER: Minimal logging
    logger.info(json.dumps({
        'event': 'lesson_request',
        'user_id': event['user']['userId']
        # Only log what you need
    }))  # 50 bytes per invocation
```

---

### 5. API Gateway Optimization

#### Enable Caching (Free Tier)

```python
# Cache GET requests for user profiles
# Cache Time: 300 seconds (5 minutes)

# Before caching:
# 100 users × 10 profile requests/day = 1,000 requests/day
# Cost: 30,000 requests/month

# After caching:
# 90% cache hit rate = 3,000 requests/month
# Savings: 27,000 requests = ~$0.10/month
```

#### Compress Responses

```python
def lambda_handler(event, context):
    import gzip
    import base64
    
    data = {'lesson': 'very long lesson content...'}
    response_body = json.dumps(data)
    
    # Check if client supports compression
    accept_encoding = event.get('headers', {}).get('Accept-Encoding', '')
    
    if 'gzip' in accept_encoding:
        # Compress response (save bandwidth)
        compressed = gzip.compress(response_body.encode())
        return {
            'statusCode': 200,
            'headers': {
                'Content-Encoding': 'gzip',
                'Content-Type': 'application/json'
            },
            'body': base64.b64encode(compressed).decode(),
            'isBase64Encoded': True
        }
    
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': response_body
    }
```

---

## Recommended Architecture for $25/Month

### Service Configuration

```yaml
# CloudFormation template optimizations

Resources:
  # Use smallest viable Lambda sizes
  LessonLambda:
    Type: AWS::Serverless::Function
    Properties:
      MemorySize: 512      # Not 1024
      Timeout: 60          # Not 300
      ReservedConcurrentExecutions: 5  # Prevent runaway costs
  
  ValidationLambda:
    Type: AWS::Serverless::Function
    Properties:
      MemorySize: 512      # Enough for pytest
      Timeout: 15          # Quick execution
      ReservedConcurrentExecutions: 10
  
  # DynamoDB with on-demand pricing
  UsersTable:
    Type: AWS::DynamoDB::Table
    Properties:
      BillingMode: PAY_PER_REQUEST  # Not PROVISIONED
      PointInTimeRecoveryEnabled: false  # Save money
  
  # CloudWatch log retention
  LessonLambdaLogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: /aws/lambda/CodeLearn-Lesson
      RetentionInDays: 7  # Not 30 or indefinite
```

---

## Cost Monitoring and Alerts

### Set Up Budget Alerts

```python
import boto3

budgets = boto3.client('budgets')

# Create a budget alert
budgets.create_budget(
    AccountId='YOUR_ACCOUNT_ID',
    Budget={
        'BudgetName': 'CodeLearn-Monthly-Budget',
        'BudgetLimit': {
            'Amount': '25',
            'Unit': 'USD'
        },
        'TimeUnit': 'MONTHLY',
        'BudgetType': 'COST'
    },
    NotificationsWithSubscribers=[
        {
            'Notification': {
                'NotificationType': 'ACTUAL',
                'ComparisonOperator': 'GREATER_THAN',
                'Threshold': 80,  # Alert at 80% ($20)
                'ThresholdType': 'PERCENTAGE'
            },
            'Subscribers': [
                {
                    'SubscriptionType': 'EMAIL',
                    'Address': 'your-email@example.com'
                }
            ]
        }
    ]
)
```

### Daily Cost Tracking Script

```python
import boto3
from datetime import datetime, timedelta

ce = boto3.client('ce')

def check_daily_costs():
    """Check yesterday's costs"""
    
    end = datetime.now().date()
    start = end - timedelta(days=1)
    
    response = ce.get_cost_and_usage(
        TimePeriod={
            'Start': start.strftime('%Y-%m-%d'),
            'End': end.strftime('%Y-%m-%d')
        },
        Granularity='DAILY',
        Metrics=['UnblendedCost'],
        GroupBy=[
            {'Type': 'SERVICE', 'Key': 'SERVICE'}
        ]
    )
    
    print("\nYesterday's AWS Costs:")
    print("=" * 50)
    
    total = 0
    for result in response['ResultsByTime']:
        for group in result['Groups']:
            service = group['Keys'][0]
            cost = float(group['Metrics']['UnblendedCost']['Amount'])
            if cost > 0.01:  # Only show non-trivial costs
                print(f"{service:30} ${cost:6.2f}")
                total += cost
    
    print("=" * 50)
    print(f"{'TOTAL':30} ${total:6.2f}")
    print(f"\nProjected monthly: ${total * 30:.2f}")
    
    # Alert if trending over budget
    if total * 30 > 25:
        print("\n⚠️  WARNING: Trending over $25/month budget!")

# Run this daily via CloudWatch Events
```

---

## Optimization Checklist

### Before Launch

- [ ] Set Lambda memory to minimum viable (512 MB for most)
- [ ] Set Lambda timeouts appropriately (10-60s, not 300s)
- [ ] Set reserved concurrency limits (prevent runaway costs)
- [ ] Enable DynamoDB auto-scaling or use on-demand
- [ ] Set CloudWatch log retention to 7 days
- [ ] Create 20-30 static lessons for common topics
- [ ] Implement lesson caching in DynamoDB/S3
- [ ] Use Claude 3 Haiku (not Sonnet) for Bedrock
- [ ] Set up budget alerts at $20 and $25
- [ ] Enable CloudWatch Contributor Insights (free)

### Weekly Monitoring

- [ ] Check AWS Cost Explorer
- [ ] Review Bedrock token usage
- [ ] Check cache hit rates
- [ ] Review Lambda execution times
- [ ] Check DynamoDB capacity usage
- [ ] Review error rates (errors = wasted $)

### Monthly Review

- [ ] Analyze which lessons are most requested
- [ ] Convert popular AI lessons to static (save money)
- [ ] Review and optimize slow Lambda functions
- [ ] Clean up unused CloudWatch logs
- [ ] Review and optimize DynamoDB indexes

---

## Expected Cost Breakdown (Realistic Usage)

### Month 1 (Low traffic - testing/beta)
- **10 users, 100 lesson requests**
- Lambda: $0.10
- Bedrock: $5.00 (initial lesson generation)
- DynamoDB: $0.50
- Other: $1.00
- **Total: ~$6.60**

### Month 3 (Growing - 100 active users)
- **100 users, 1,000 lesson requests**
- Lambda: $0.50
- Bedrock: $8.00 (90% cache hit rate)
- DynamoDB: $2.00
- CloudWatch: $1.00
- Other: $1.50
- **Total: ~$13.00**

### Month 6 (Stable - 300-500 users)
- **500 users, 5,000 lesson requests**
- Lambda: $2.00
- Bedrock: $12.00 (95% cache hit rate + static lessons)
- DynamoDB: $3.00
- CloudWatch: $2.00
- Other: $2.00
- **Total: ~$21.00** ✅

---

## Emergency Cost Controls

### If Costs Spike Unexpectedly

```python
# Emergency Lambda function to disable expensive features

import boto3

lambda_client = boto3.client('lambda')

def emergency_cost_control(event, context):
    """
    Triggered by CloudWatch alarm when costs > $30
    Temporarily disable AI generation
    """
    
    # Update LessonLambda environment to use static-only mode
    lambda_client.update_function_configuration(
        FunctionName='CodeLearn-Lesson',
        Environment={
            'Variables': {
                'EMERGENCY_MODE': 'true',  # Skip Bedrock, use static only
                'USERS_TABLE': os.environ['USERS_TABLE'],
                'PROGRESS_TABLE': os.environ['PROGRESS_TABLE']
            }
        }
    )
    
    # Send alert
    sns = boto3.client('sns')
    sns.publish(
        TopicArn='arn:aws:sns:us-east-1:ACCOUNT:cost-alerts',
        Subject='🚨 CodeLearn: Emergency Cost Control Activated',
        Message='AI lesson generation disabled. Using static lessons only.'
    )
```

---

## Scaling Within Budget

### As You Grow

| Users | Monthly Cost | Strategy |
|-------|--------------|----------|
| **0-100** | $8-15 | Aggressive caching, mostly static lessons |
| **100-500** | $15-25 | 95% cache hit rate, selective AI use |
| **500-1000** | $25-40 | Need to increase budget OR monetize |
| **1000+** | $40-100+ | Definitely need revenue/monetization |

### Monetization Options (When Ready)

- **Freemium**: Free basic lessons, $9/month for AI-personalized
- **Pay-per-lesson**: $0.25 per premium AI-generated lesson
- **Enterprise**: $99/month for teams with custom curricula
- **Sponsorship**: Company logos on platform

---

## Bottom Line: Can You Build This for $25/Month?

**YES! ✅**

**Key Success Factors:**

1. **Use Claude 3 Haiku** (not Sonnet) - 12x cheaper
2. **Aggressive caching** - 90%+ hit rate on lessons
3. **Hybrid content** - 30 static lessons + AI for advanced topics
4. **Right-sized Lambda** - 512MB, short timeouts
5. **DynamoDB on-demand** - perfect for low/moderate traffic
6. **Smart monitoring** - catch cost spikes early

**Expected Costs:**
- Month 1-2: $6-10 (testing, building cache)
- Month 3-6: $13-21 (steady growth)
- Month 6+: $21-25 (optimized, 300-500 users)

**You can support 300-500 active learners for under $25/month** with smart optimization! 🎉

---

## Next Steps

1. **Week 1**: Build infrastructure (free tier only)
2. **Week 2**: Create 20 static lessons manually
3. **Week 3**: Implement caching + Bedrock (Haiku)
4. **Week 4**: Set up cost monitoring and alerts
5. **Launch**: Start with free tier, add AI gradually

Ready to build? 🚀
