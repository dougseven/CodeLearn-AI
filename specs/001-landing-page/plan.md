# Implementation Plan: CodeLearn AI Landing Page

**Branch**: `001-landing-page` | **Date**: 2025-11-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-landing-page/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Create a public-facing landing page that serves as the primary entry point for the CodeLearn AI platform. The page will communicate the value proposition (AI-powered personalized coding education), showcase three platform features (personalization, AI tutoring, practical projects), display a course catalog preview (Python, Java, Rust), and provide secure authentication access. The page must load within 3 seconds, comply with WCAG 2.1 Level AA accessibility standards, and function identically across modern browsers.

**Technical Approach**: Static HTML/CSS/JavaScript single-page application hosted on S3 + CloudFront. No backend processing required for page rendering. Authentication integration with existing AWS Cognito OAuth 2.0 service. Responsive design using CSS Grid/Flexbox with mobile-first approach. Progressive image loading for performance. Semantic HTML5 for SEO and accessibility.

## Technical Context

**Language/Version**: HTML5, CSS3, JavaScript ES6+ (no transpilation required for modern browsers)  
**Primary Dependencies**: None (vanilla JavaScript, no frameworks) or lightweight library for modal interactions (NEEDS CLARIFICATION: vanilla JS vs. minimal library like Alpine.js)  
**Storage**: S3 bucket for static assets, CloudFront CDN for global delivery  
**Testing**: Cypress or Playwright for E2E tests, Lighthouse for performance/accessibility audits, manual cross-browser testing (NEEDS CLARIFICATION: E2E framework preference)  
**Target Platform**: Modern web browsers (Chrome 90+, Firefox 88+, Safari 14+, Edge 90+), mobile devices (iOS 14+, Android 10+)  
**Project Type**: Web application (frontend-only static site)  
**Performance Goals**: <3s page load on 10 Mbps connection, <1s time-to-interactive, Lighthouse score ≥90 for performance/accessibility  
**Constraints**: WCAG 2.1 Level AA compliance mandatory, no JavaScript frameworks (align with existing frontend architecture), <500KB total asset size before compression, works with JavaScript disabled (graceful degradation)  
**Scale/Scope**: Single landing page (~1500 lines of code), 5-7 images/icons optimized for web, integration with 1 external service (AWS Cognito for authentication)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ I. Code Quality & Maintainability

- **Status**: PASS (with notes)
- **Assessment**: Frontend code will follow best practices (semantic HTML, modular CSS with BEM methodology, well-commented JavaScript). No Python code involved, so PEP 8 and pylint requirements N/A.
- **Action**: Establish JavaScript/CSS linting standards equivalent to Python requirements. Use ESLint with Airbnb config (≥8.0/10 equivalent) and Stylelint for CSS.

### ✅ II. Test-First Development

- **Status**: PASS (with adaptation)
- **Assessment**: TDD will be adapted for frontend: Write Cypress/Playwright tests for user journeys → Implement HTML/CSS → Tests pass. No backend Lambda handlers involved.
- **Action**: Phase 1 will include test scenarios for each user story. Target 80% coverage for JavaScript functions (if any complex logic exists).

### ✅ III. User Experience Consistency

- **Status**: PASS
- **Assessment**: Landing page will establish the design system (colors, fonts, spacing in `frontend/styles.css`) that all future pages will follow. All user-facing text will be clear, professional yet approachable, avoiding technical jargon per FR-018.
- **Action**: Create centralized CSS variables for colors, typography, spacing. Document design tokens for future consistency.

### ✅ IV. Performance & Cost Optimization

- **Status**: PASS
- **Assessment**: Static hosting on S3 + CloudFront is cost-effective (pennies per month). No Lambda, DynamoDB, or AI costs for landing page. Optimized images and minified assets ensure fast loading.
- **Action**: Compress all images (WebP format with JPEG fallback), minify CSS/JS, enable Gzip compression on CloudFront, lazy-load below-the-fold images.

### Architecture Constraints Compliance

- ✅ Frontend: Static HTML/CSS/JavaScript hosted on S3 + CloudFront (matches requirements)
- ✅ Authentication: Integration with existing AWS Cognito OAuth 2.0 (no new auth system required)
- ✅ Security: HTTPS via CloudFront, no sensitive data in client-side code, password masking (FR-014)
- ✅ API: No new API endpoints required for landing page rendering (auth handled by existing service)

**Constitution Verdict**: ✅ **PASS** - Feature aligns with all constitution principles. Frontend-focused feature requires adaptation of Python-specific standards to JavaScript/CSS equivalents.

## Project Structure

### Documentation (this feature)

```text
specs/001-landing-page/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (minimal - just User Session entity)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (API contract for Cognito integration)
│   └── cognito-auth-contract.md
├── checklists/
│   └── requirements.md  # Already exists (spec validation)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
frontend/
├── index.html           # Landing page (NEW - replaces or enhances existing)
├── css/
│   ├── styles.css       # Main stylesheet (UPDATE - add design system variables)
│   ├── hero.css         # Hero section styles (NEW)
│   ├── features.css     # Platform features section styles (NEW)
│   ├── catalog.css      # Course catalog preview styles (NEW)
│   ├── navigation.css   # Navigation bar and footer styles (NEW)
│   └── modal.css        # Login modal styles (NEW)
├── js/
│   ├── main.js          # Main entry point, page initialization (NEW)
│   ├── auth.js          # Authentication modal and Cognito integration (NEW)
│   ├── navigation.js    # Sticky nav, smooth scrolling, mobile menu (NEW)
│   └── analytics.js     # Analytics tracking helpers (OPTIONAL)
├── assets/
│   ├── images/
│   │   ├── logo.svg     # CodeLearn AI logo (NEW - needs design)
│   │   ├── hero-bg.webp # Hero background image (NEW - needs design)
│   │   ├── python-icon.svg (NEW - standard Python logo)
│   │   ├── java-icon.svg   (NEW - standard Java logo)
│   │   ├── rust-icon.svg   (NEW - standard Rust logo)
│   │   ├── feature-personalization-icon.svg (NEW - needs design)
│   │   ├── feature-ai-icon.svg (NEW - needs design)
│   │   └── feature-projects-icon.svg (NEW - needs design)
│   └── fonts/           # Web fonts if not using system fonts (OPTIONAL)
└── tests/
    ├── e2e/
    │   ├── landing-page.spec.js  # Cypress/Playwright E2E tests (NEW)
    │   └── accessibility.spec.js  # Accessibility tests (NEW)
    └── lighthouse/
        └── config.json   # Lighthouse CI config (NEW)
```

**Structure Decision**: This is a web application (frontend-only). All code resides in the `frontend/` directory at the repository root. The landing page (`index.html`) will be the new entry point, potentially replacing or significantly updating the existing `frontend/index.html`. CSS is modularized by section for maintainability. JavaScript is separated by concern (auth, navigation, analytics). Tests are colocated with source under `frontend/tests/`.

## Complexity & Justifications

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations identified**. All constitution principles align with this feature:

- Code quality standards adapted for JavaScript/CSS (ESLint, Stylelint)
- TDD workflow adapted for frontend (Cypress tests written first)
- UX consistency established by creating the design system foundation
- Performance/cost optimization achieved through static hosting and asset optimization

**Deferred Items**: None
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
