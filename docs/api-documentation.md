# CodeLearn API Documentation

**Base URL:** `https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod`

## Endpoints

### 1. Generate Lesson

Generate an AI-powered lesson or retrieve from cache.

**Endpoint:** `POST /api/lesson`

**Request Body:**
```json
{
  "language": "python",
  "level": "beginner",
  "topic": "variables and data types"
}
```

**Parameters:**
- `language` (string, required): Programming language (python, java, rust)
- `level` (string, required): Skill level (beginner, intermediate, advanced, experienced)
- `topic` (string, optional): Specific topic to learn

**Response:**
```json
{
  "lessonId": "python_beginner_variables_1700000000",
  "topic": "variables and data types",
  "lesson": "# Markdown lesson content...",
  "challenge": "Coding challenge description...",
  "tests": ["test case 1", "test case 2"],
  "cached": true
}
```

**Example:**
```bash
curl -X POST https://YOUR-API/prod/api/lesson \
  -H "Content-Type: application/json" \
  -d '{
    "language": "python",
    "level": "beginner",
    "topic": "variables and data types"
  }'
```

---

### 2. Validate Code

Execute and test user-submitted code.

**Endpoint:** `POST /api/validate`

**Request Body:**
```json
{
  "code": "name = 'Alice'\nage = 25",
  "tests": ["def test_name():\n    assert name == 'Alice'"],
  "language": "python",
  "lessonId": "lesson123"
}
```

**Parameters:**
- `code` (string, required): User's code to validate
- `tests` (array, required): Array of test case strings
- `language` (string, required): Programming language
- `lessonId` (string, required): Associated lesson ID

**Response:**
```json
{
  "passed": true,
  "results": [
    {
      "name": "test_name",
      "passed": true,
      "error": null
    }
  ],
  "feedback": "Great job! All tests passed!"
}
```

---

### 3. Get User Profile

Retrieve user profile and preferences.

**Endpoint:** `GET /api/user/profile`

**Headers:**
- `Authorization: Bearer <jwt-token>`

**Response:**
```json
{
  "userId": "user-uuid",
  "email": "user@example.com",
  "name": "John Doe",
  "preferences": {
    "language": "python",
    "skillLevel": "intermediate"
  },
  "createdAt": 1700000000,
  "lastLogin": 1700000000
}
```

---

### 4. Update User Profile

Update user preferences.

**Endpoint:** `PUT /api/user/profile`

**Headers:**
- `Authorization: Bearer <jwt-token>`

**Request Body:**
```json
{
  "preferences": {
    "language": "java",
    "skillLevel": "beginner"
  }
}
```

**Response:**
```json
{
  "message": "Profile updated successfully",
  "preferences": {
    "language": "java",
    "skillLevel": "beginner"
  }
}
```

---

## Error Responses

All endpoints return errors in this format:

```json
{
  "error": "Error message description"
}
```

**Common Status Codes:**
- `200` - Success
- `400` - Bad Request (missing/invalid parameters)
- `404` - Not Found
- `500` - Internal Server Error
- `503` - Service Unavailable (emergency mode active)

---

## Rate Limiting

Currently no rate limiting is enforced, but it may be added in the future.

---

## CORS

All endpoints support CORS with:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS`
- `Access-Control-Allow-Headers: Content-Type, Authorization`

---

## Cost Optimization

The API implements several cost-saving measures:
- Aggressive caching (90%+ hit rate)
- Static lesson serving (no AI cost)
- Budget AI model (Claude 3 Haiku)
- Limited concurrency
- Emergency shutdown mode

---

## Testing

Use the provided test script:
```bash
./tools/test-api.sh
```