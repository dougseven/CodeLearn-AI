# Data Model: Landing Page

**Feature**: 001-landing-page  
**Version**: 1.0.0  
**Date**: 2025-11-23

## Overview

The landing page is a **static frontend-only feature** with minimal data modeling requirements. Data interactions are limited to client-side state management and authentication flows with AWS Cognito.

## Entities

### 1. User Session (Client-Side State)

**Purpose**: Track authentication state for returning users

**Fields**:
- `isAuthenticated`: boolean - Whether user has valid Cognito token
- `accessToken`: string | null - JWT token from Cognito OAuth 2.0
- `idToken`: string | null - User identity claims
- `tokenExpiry`: number | null - Unix timestamp for token expiration
- `redirectUrl`: string | null - Post-login redirect destination

**State Transitions**:
```
[Anonymous] → [Login Click] → [Cognito OAuth Flow] → [Authenticated]
[Authenticated] → [Token Expires] → [Anonymous]
[Authenticated] → [Logout Click] → [Anonymous]
```

**Validation Rules**:
- `accessToken` must be valid JWT format if present
- `tokenExpiry` must be future timestamp when `isAuthenticated = true`
- Clear all session data on logout

**Storage**: `sessionStorage` (cleared on tab close)

### 2. Course Category (Static Data)

**Purpose**: Display available course offerings in catalog section

**Fields**:
- `id`: string - Unique identifier (e.g., "python", "java", "rust")
- `name`: string - Display name (e.g., "Python Programming")
- `description`: string - Brief 1-sentence overview
- `icon`: string - SVG icon path
- `difficulty`: "beginner" | "intermediate" | "advanced"
- `lessonCount`: number - Number of lessons available
- `enabled`: boolean - Whether category is clickable

**Validation Rules**:
- `id` must match pattern `[a-z]+`
- `name` must be 1-30 characters
- `description` must be 50-150 characters
- `lessonCount` must be >= 0

**Storage**: Hardcoded in `index.html` or `catalog.js` (no backend)

**Initial Data**:
```javascript
const courses = [
  {
    id: "python",
    name: "Python Programming",
    description: "Learn Python from basics to advanced AI development.",
    icon: "/assets/icons/python.svg",
    difficulty: "beginner",
    lessonCount: 24,
    enabled: true
  },
  {
    id: "java",
    name: "Java Development",
    description: "Master Java for enterprise and Android applications.",
    icon: "/assets/icons/java.svg",
    difficulty: "intermediate",
    lessonCount: 18,
    enabled: true
  },
  {
    id: "rust",
    name: "Rust Systems",
    description: "Build safe, high-performance systems with Rust.",
    icon: "/assets/icons/rust.svg",
    difficulty: "advanced",
    lessonCount: 12,
    enabled: true
  }
];
```

## Relationships

**User Session ↔ Course Category**: None (no personalization on landing page)

## Edge Cases

1. **Token Refresh**: Tokens expire during landing page visit
   - **Handling**: Check `tokenExpiry` on page load, clear session if expired

2. **Disabled Courses**: User clicks disabled course category
   - **Handling**: `enabled: false` courses show "Coming Soon" badge, no click handler

3. **Missing Course Data**: JavaScript fails to load course array
   - **Handling**: Show generic "Courses loading..." message after 3s timeout

## Non-Functional Requirements

- **Session Storage**: Must survive page refreshes but not browser restarts (use `sessionStorage`, not `localStorage`)
- **Course Data Size**: Total hardcoded course data must be < 5KB uncompressed
- **Validation Performance**: All client-side validation must complete in < 10ms

## Future Considerations

- **Phase 2**: Course categories may become dynamic (fetched from DynamoDB)
- **Phase 3**: User session may include preferences (theme, language)
- **Phase 4**: Personalized course recommendations based on user history
