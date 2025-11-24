<!--
  Sync Impact Report - Version 1.0.0 (Initial Constitution)
  
  Version Change: NONE → 1.0.0 (Initial ratification)
  
  Added Principles:
  - I. Code Quality & Maintainability (code quality standards)
  - II. Test-First Development (testing discipline)
  - III. User Experience Consistency (UX/UI standards)
  - IV. Performance & Cost Optimization (performance requirements)
  
  Templates Status:
  ✅ plan-template.md - Constitution Check section references this file
  ✅ spec-template.md - Requirements section aligns with principles
  ✅ tasks-template.md - Test-first workflow matches Principle II
  ✅ agent-file-template.md - No changes required
  ✅ checklist-template.md - No changes required
  
  Deferred Items: None
  
  Follow-up: Review all existing code against new principles during next sprint
-->

# CodeLearn AI Platform Constitution

## Core Principles

### I. Code Quality & Maintainability

**Standards (NON-NEGOTIABLE)**:

- All Python code MUST follow PEP 8 style guidelines and pass `pylint` with score ≥ 8.0/10
- All functions MUST have type hints for parameters and return values
- All modules, classes, and functions MUST have docstrings describing purpose, parameters, return values, and exceptions
- Cyclomatic complexity MUST NOT exceed 10 per function (refactor if violated)
- Code duplication MUST be eliminated—shared logic extracted to reusable functions or modules
- Lambda functions MUST be modular: separate handler, business logic, and data access layers
- All environment variables MUST be validated at startup; fail fast with clear error messages if missing

**Rationale**: CodeLearn is a teaching platform—our code itself must demonstrate professional quality. Maintainable code reduces bugs, enables rapid feature development, and keeps AWS Lambda cold starts minimal.

### II. Test-First Development (NON-NEGOTIABLE)

**Standards**:

- Test-Driven Development (TDD) MUST be followed: Write tests → User approves → Tests fail → Implement → Tests pass
- All Lambda handlers MUST have unit tests with mocked AWS services (boto3, DynamoDB, S3)
- All API endpoints MUST have integration tests validating request/response contracts
- Critical user paths MUST have end-to-end tests (lesson generation → validation → user feedback)
- Test coverage MUST be ≥ 80% for all production code (measured via `pytest-cov`)
- Tests MUST run in CI/CD pipeline; failing tests block deployment
- Performance-critical paths MUST have load tests demonstrating they meet SLOs under expected load

**Rationale**: Testing prevents regressions, documents expected behavior, and ensures the platform remains reliable as features are added. TDD enforces thinking through requirements before implementation.

### III. User Experience Consistency

**Standards**:

- All API responses MUST follow the standardized format: `{ "statusCode": int, "headers": {...}, "body": json_string }`
- Error messages MUST be user-friendly (no stack traces exposed to frontend), actionable, and consistent in tone
- All frontend components MUST use the centralized design system (colors, fonts, spacing defined in `frontend/styles.css`)
- Loading states MUST be shown for all async operations (lesson generation, code validation)
- User actions MUST provide immediate feedback (success/error messages within 100ms of completion)
- All user-facing text MUST be clear, concise, and encourage learning (avoid technical jargon)
- Lessons MUST be structured consistently: Introduction → Concept → Syntax → Examples → Challenge → Tests

**Rationale**: Consistent UX builds user trust and reduces cognitive load. Learners should focus on coding concepts, not deciphering the interface.

### IV. Performance & Cost Optimization

**Standards (Budget Target: $25/month)**:

- Lesson generation MUST check DynamoDB cache first (target 90%+ hit rate); only invoke Bedrock on cache miss
- Static lessons (30+ pre-built) MUST be served from S3 (free tier) before considering AI generation
- Lambda functions MUST be right-sized: Lesson=512MB, Validation=256MB, User/Auth=128MB (no over-provisioning)
- Lambda concurrent executions MUST be capped at 5 to prevent cost spikes during traffic bursts
- DynamoDB MUST use on-demand pricing (no provisioned capacity) and TTL for cache expiration (30 days)
- Bedrock MUST use Claude 3.5 Haiku (12x cheaper than Sonnet) for lesson generation
- Emergency shutdown mode MUST activate if projected monthly cost exceeds $30 (503 responses, stop AI calls)
- All database queries MUST use indexes (no table scans); query response time MUST be < 50ms p95
- API Gateway responses MUST be < 500ms p95 (including Lambda execution)
- Frontend static assets MUST be served via CloudFront CDN (when available) to reduce S3 costs

**Rationale**: Cost efficiency is a core product feature. The platform must deliver high-quality education at minimal expense to remain accessible.

## Architecture Constraints

**Technology Stack (MUST comply)**:

- Backend: AWS Lambda (Python 3.12), Amazon Bedrock (Claude 3.5 Haiku)
- Database: DynamoDB (on-demand pricing)
- Storage: S3 (static lessons, frontend hosting)
- Authentication: AWS Cognito with OAuth 2.0 (Google)
- Code Validation: Secure containerized execution (CodeBuild or Fargate—NOT direct Lambda execution)
- API: API Gateway REST API with CORS enabled
- Frontend: Static HTML/CSS/JavaScript hosted on S3 + CloudFront

**Security Requirements (NON-NEGOTIABLE)**:

- User-submitted code MUST NEVER be executed directly in Lambda (use isolated containers)
- All API endpoints requiring user data MUST validate JWT tokens from Cognito
- IAM roles MUST follow least-privilege principle (only required permissions granted)
- S3 buckets MUST block public write access; read-only via CloudFront OAC
- All input validation MUST occur server-side (never trust client-side validation alone)
- Secrets (API keys, OAuth credentials) MUST be stored in AWS Secrets Manager or environment variables (not in code)

## Development Workflow

**Feature Development (MUST follow)**:

1. Create feature branch from `main`: `[###-feature-name]`
2. Write specification in `/specs/[###-feature-name]/spec.md` with prioritized user stories
3. Run `/speckit.plan` to generate implementation plan with constitution checks
4. Write tests first (unit + integration) based on spec acceptance criteria
5. Implement feature following plan; ensure tests pass
6. Update documentation (README, API docs, user guides)
7. Create PR with clear description, link to spec, and test results
8. Code review MUST verify: (a) Constitution compliance, (b) Tests passing, (c) Documentation complete
9. Merge only after approval and CI/CD pipeline success

**Constitution Compliance (Enforced in PRs)**:

- All code changes MUST be reviewed against this constitution
- Violations MUST be documented in `/specs/[###-feature]/plan.md` under "Complexity Tracking" with justification
- Repeated violations without justification will block PR approval
- Constitution amendments require: (a) proposal in PR, (b) team discussion, (c) version bump + migration plan

## Governance

This constitution supersedes all informal development practices. When practices conflict with this constitution, the constitution takes precedence.

**Amendment Process**:

1. Propose amendment in GitHub issue with rationale and affected projects
2. Document breaking changes and migration steps
3. Update constitution with version bump (MAJOR for breaking changes, MINOR for additions, PATCH for clarifications)
4. Propagate changes to dependent templates (plan-template.md, spec-template.md, tasks-template.md)
5. Update all active feature branches to comply with amended constitution

**Version Semantics**:

- MAJOR: Backward-incompatible principle removal, redefinition, or new blocking requirement
- MINOR: New principle added, existing principle materially expanded
- PATCH: Clarifications, typo fixes, wording improvements (no semantic change)

**Compliance Reviews**:

- Weekly: Review recent PRs for constitution violations; address in team sync
- Monthly: Audit existing codebase against principles; create remediation tasks for violations
- Quarterly: Full constitution review; propose amendments if principles no longer serve project goals

**Version**: 1.0.0 | **Ratified**: 2025-11-23 | **Last Amended**: 2025-11-23
