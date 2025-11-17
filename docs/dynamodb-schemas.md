# DynamoDB Table Schemas

## Lesson Cache Table

**Purpose**: Cache AI-generated lessons to reduce Bedrock costs

**Table Name**: `codelearn-lesson-cache-dev`

**Schema**:
```json
{
  "lessonKey": "python_beginner_variables",
  "content": {
    "lesson": "# Variables in Python\n\n...",
    "challenge": "Create a variable...",
    "tests": ["def test_...", "def test_..."]
  },
  "metadata": {
    "generatedAt": 1699999999,
    "model": "claude-3-haiku",
    "tokenCount": 1234,
    "cost": 0.0015
  },
  "ttl": 1707788399,
  "hitCount": 42
}
```

**Keys**:
- Partition Key: `lessonKey` (String)

**TTL**: 90 days

## Users Table

**Purpose**: Store user profiles and preferences

**Table Name**: `codelearn-users-dev`

**Schema**:
```json
{
  "userId": "uuid-here",
  "email": "user@example.com",
  "name": "John Doe",
  "idpProvider": "google",
  "idpId": "google-user-id",
  "preferences": {
    "language": "python",
    "skillLevel": "intermediate",
    "priorLanguage": "java"
  },
  "createdAt": 1699999999,
  "lastLogin": 1700000000
}
```

**Keys**:
- Partition Key: `userId` (String)

**Indexes**:
- EmailIndex (GSI): Query by email

## Progress Table

**Purpose**: Track lesson completion

**Table Name**: `codelearn-progress-dev`

**Schema**:
```json
{
  "userId": "uuid-here",
  "lessonId": "lesson-uuid",
  "topic": "variables",
  "language": "python",
  "completed": true,
  "attempts": 3,
  "firstAttemptSuccess": false,
  "completedAt": 1700000000,
  "cached": true,
  "feedbackGenerated": true
}
```

**Keys**:
- Partition Key: `userId` (String)
- Sort Key: `lessonId` (String)

## Sessions Table

**Purpose**: Store temporary session data

**Table Name**: `codelearn-sessions-dev`

**Schema**:
```json
{
  "sessionId": "session-uuid",
  "userId": "user-uuid",
  "token": "jwt-token-here",
  "createdAt": 1700000000,
  "expiresAt": 1700086400
}
```

**Keys**:
- Partition Key: `sessionId` (String)

**TTL**: 24 hours (expiresAt field)