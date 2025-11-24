# Tasks: CodeLearn AI Landing Page

**Feature**: 001-landing-page  
**Branch**: `001-landing-page`  
**Input**: Design documents from `/specs/001-landing-page/`

**Format**: `- [ ] [TaskID] [P?] [Story?] Description with file path`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story label (US1, US2, US3, US4)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create frontend directory structure per plan.md: frontend/{styles,scripts,assets/{images,icons}}
- [X] T002 Initialize package.json with Playwright, @lhci/cli, axe-core dependencies
- [X] T003 [P] Configure ESLint with Airbnb config and Stylelint for CSS in .eslintrc.json and .stylelintrc.json
- [X] T004 [P] Install Playwright browsers with `npx playwright install`
- [X] T005 [P] Create .gitignore for node_modules, playwright reports, lighthouse reports

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 Create design system CSS variables in frontend/styles/main.css (colors, fonts, spacing per constitution)
- [X] T007 [P] Create responsive CSS reset and base styles in frontend/styles/main.css (mobile-first, box-sizing)
- [X] T008 [P] Create frontend/assets/logo.svg placeholder (CodeLearn AI logo)
- [X] T009 [P] Setup Playwright configuration in playwright.config.js (Chrome, Firefox, Safari, Edge test matrix)
- [X] T010 [P] Create frontend/callback.html OAuth callback handler page skeleton
- [X] T011 Create frontend/scripts/auth.js with AuthManager class and session storage utilities
- [X] T012 [P] Create course catalog data structure in frontend/scripts/catalog.js (Python, Java, Rust per data-model.md)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - First-Time Visitor Discovers Platform (Priority: P1) 🎯 MVP

**Goal**: Display hero section with value proposition, tagline, and primary CTA that loads within 3 seconds

**Independent Test**: Load http://localhost:8000 and verify hero section displays "AI-powered personalized learning" headline, tagline, and "Start Your Learning Journey" CTA button within viewport without scrolling

### Playwright Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T013 [P] [US1] Create tests/e2e/landing-page.spec.js with test: "homepage loads within 3 seconds"
- [X] T014 [P] [US1] Add test to landing-page.spec.js: "hero section displays value proposition and CTA"
- [X] T015 [P] [US1] Add test to landing-page.spec.js: "primary CTA button is visible and clickable"
- [X] T016 [P] [US1] Create tests/e2e/performance.spec.js with Lighthouse performance audit (target: 90+ score)

### Implementation for User Story 1

- [X] T017 [P] [US1] Create frontend/index.html with semantic HTML5 structure, meta tags, Open Graph tags
- [X] T018 [P] [US1] Create frontend/styles/hero.css with mobile-first hero section layout (CSS Grid)
- [X] T019 [US1] Add hero section HTML to frontend/index.html with headline, tagline, CTA button (depends on T017)
- [ ] T020 [US1] Add hero background image optimization: create frontend/assets/images/hero-bg.webp and hero-bg.jpg fallback
- [X] T021 [US1] Implement hero section styles in frontend/styles/hero.css with responsive breakpoints (320px, 768px, 1200px)
- [X] T022 [US1] Add CTA button click handler in frontend/scripts/main.js to trigger auth modal (placeholder for now)
- [X] T023 [US1] Add critical CSS inlining for hero section to meet <3s load time requirement

**Checkpoint**: Run `npx playwright test tests/e2e/landing-page.spec.js` - User Story 1 tests should PASS

---

## Phase 4: User Story 2 - Visitor Explores Platform Features (Priority: P2)

**Goal**: Display "How It Works" section with 3 distinct features: personalization, AI tutoring, practical projects

**Independent Test**: Scroll to features section and verify 3 feature cards are displayed with icons, headings ("Personalized Learning Paths", "AI-Powered Tutoring", "Real-World Projects"), and descriptions

### Playwright Tests for User Story 2

- [ ] T024 [P] [US2] Add test to tests/e2e/landing-page.spec.js: "displays 3 platform features with icons"
- [ ] T025 [P] [US2] Add test to tests/e2e/landing-page.spec.js: "feature descriptions use non-technical language"
- [ ] T026 [P] [US2] Add test to tests/e2e/landing-page.spec.js: "features section is visible after scrolling past hero"

### Implementation for User Story 2

- [ ] T027 [P] [US2] Create frontend/styles/features.css with feature card layout (CSS Flexbox/Grid)
- [ ] T028 [P] [US2] Create feature icons: frontend/assets/icons/personalization.svg, ai-tutor.svg, projects.svg
- [ ] T029 [US2] Add features section HTML to frontend/index.html with 3 feature cards (depends on T017)
- [ ] T030 [US2] Implement features section styles in frontend/styles/features.css with hover effects and animations
- [ ] T031 [US2] Add smooth scroll behavior in frontend/scripts/navigation.js for hero → features transition
- [ ] T032 [US2] Optimize feature section images for lazy loading below the fold

**Checkpoint**: Run `npx playwright test` - User Stories 1 AND 2 tests should PASS independently

---

## Phase 5: User Story 3 - Visitor Browses Course Offerings (Priority: P2)

**Goal**: Display course catalog preview with Python, Java, Rust categories and skill level indicators

**Independent Test**: Scroll to course catalog section and verify 3 course cards (Python, Java, Rust) are displayed with icons, difficulty badges, lesson counts, and "View Courses" CTAs

### Playwright Tests for User Story 3

- [ ] T033 [P] [US3] Add test to tests/e2e/landing-page.spec.js: "displays 3 course categories with recognizable icons"
- [ ] T034 [P] [US3] Add test to tests/e2e/landing-page.spec.js: "course cards show skill level indicators"
- [ ] T035 [P] [US3] Add test to tests/e2e/landing-page.spec.js: "clicking View Courses prompts authentication if not logged in"

### Implementation for User Story 3

- [ ] T036 [P] [US3] Create frontend/styles/catalog.css with course card grid layout (3 columns desktop, 1 column mobile)
- [ ] T037 [P] [US3] Create course language icons: frontend/assets/icons/python.svg, java.svg, rust.svg
- [ ] T038 [US3] Add course catalog section HTML to frontend/index.html with course cards (depends on T017)
- [ ] T039 [US3] Implement course catalog rendering in frontend/scripts/catalog.js using data from T012
- [ ] T040 [US3] Implement catalog styles in frontend/styles/catalog.css with difficulty badges (beginner/intermediate/advanced)
- [ ] T041 [US3] Add "View Courses" click handler in frontend/scripts/main.js to check auth state, prompt login if needed
- [ ] T042 [US3] Add hover effects and visual feedback for course cards in frontend/styles/catalog.css

**Checkpoint**: Run `npx playwright test` - User Stories 1, 2, AND 3 tests should PASS independently

---

## Phase 6: User Story 4 - Returning User Logs In (Priority: P3)

**Goal**: Provide persistent login link in navigation that opens modal with AWS Cognito OAuth 2.0 integration

**Independent Test**: Click "Login" link in top navigation, verify modal appears with email/password fields, submit valid credentials, verify redirect to Cognito hosted UI

### Playwright Tests for User Story 4

- [ ] T043 [P] [US4] Add test to tests/e2e/landing-page.spec.js: "login link is visible in navigation"
- [ ] T044 [P] [US4] Add test to tests/e2e/landing-page.spec.js: "clicking login opens authentication modal"
- [ ] T045 [P] [US4] Add test to tests/e2e/landing-page.spec.js: "login button redirects to Cognito OAuth authorize endpoint"
- [ ] T046 [P] [US4] Add test to tests/e2e/landing-page.spec.js: "invalid login shows clear error message"
- [ ] T047 [P] [US4] Add test to tests/e2e/landing-page.spec.js: "closing modal preserves scroll position"

### Implementation for User Story 4

- [ ] T048 [P] [US4] Create frontend/styles/navigation.css with sticky header and mobile responsive menu
- [ ] T049 [P] [US4] Create frontend/styles/modal.css with accessible modal styling (focus trap, overlay)
- [ ] T050 [US4] Add navigation bar HTML to frontend/index.html with logo, nav links (About, How It Works, Courses), and Login button (depends on T017)
- [ ] T051 [US4] Create login modal HTML in frontend/index.html using native `<dialog>` element with email/password fields
- [ ] T052 [US4] Implement navigation bar styles in frontend/styles/navigation.css with mobile hamburger menu
- [ ] T053 [US4] Implement modal styles in frontend/styles/modal.css with ARIA labels and keyboard navigation
- [ ] T054 [US4] Implement modal open/close handlers in frontend/scripts/auth.js with focus trap and Esc key support
- [ ] T055 [US4] Implement Cognito OAuth flow in frontend/scripts/auth.js: generate state token, redirect to /oauth2/authorize
- [ ] T056 [US4] Implement OAuth callback handler in frontend/callback.html: validate state, exchange code for tokens (calls future backend)
- [ ] T057 [US4] Implement session management in frontend/scripts/auth.js: store tokens in sessionStorage, check expiry
- [ ] T058 [US4] Add logged-in state UI changes in frontend/scripts/main.js: show "Go to Dashboard" instead of "Login"
- [ ] T059 [US4] Implement logout handler in frontend/scripts/auth.js: clear sessionStorage, redirect to Cognito /logout
- [ ] T060 [US4] Add error handling in frontend/scripts/auth.js for authentication failures with user-friendly messages

**Checkpoint**: Run `npx playwright test` - All user story tests (US1, US2, US3, US4) should PASS independently

---

## Phase 7: Cross-Cutting & Accessibility

**Purpose**: Improvements that affect multiple user stories and ensure compliance

- [ ] T061 [P] Add footer HTML to frontend/index.html with copyright, attribution to Doug Saven, legal links
- [ ] T062 [P] Implement footer styles in frontend/styles/navigation.css
- [ ] T063 [P] Create tests/e2e/accessibility.spec.js with axe-core WCAG 2.1 Level AA audit for all page states
- [ ] T064 [P] Add keyboard navigation tests in tests/e2e/accessibility.spec.js (Tab, Shift+Tab, Enter, Esc)
- [ ] T065 [P] Add screen reader compatibility tests in tests/e2e/accessibility.spec.js (ARIA labels, semantic HTML)
- [ ] T066 Implement smooth scroll behavior for all anchor links in frontend/scripts/navigation.js
- [ ] T067 Add mobile hamburger menu toggle in frontend/scripts/navigation.js
- [ ] T068 Optimize all images with ImageMagick: convert to WebP, ensure <500KB total page weight
- [ ] T069 [P] Add Lighthouse CI configuration in lighthouserc.json (performance ≥90, accessibility 100)
- [ ] T070 [P] Add color contrast validation to ensure WCAG AA compliance (4.5:1 for normal text)

**Checkpoint**: Run `npx playwright test tests/e2e/accessibility.spec.js` - All accessibility tests should PASS

---

## Phase 8: Cross-Browser & Responsive Testing

**Purpose**: Ensure consistent experience across devices and browsers

- [ ] T071 [P] Add responsive layout tests in tests/e2e/responsive.spec.js (320px, 768px, 1200px viewports)
- [ ] T072 [P] Add mobile device emulation tests in tests/e2e/responsive.spec.js (iPhone 13, iPad, Android)
- [ ] T073 [P] Add cross-browser tests in Playwright config: Chrome, Firefox, Safari, Edge
- [ ] T074 Test hero section responsive behavior: verify no horizontal scroll on mobile (320px-768px)
- [ ] T075 Test features section responsive behavior: stack cards on mobile, grid on desktop
- [ ] T076 Test catalog section responsive behavior: 1 column mobile, 2 columns tablet, 3 columns desktop
- [ ] T077 Test navigation bar responsive behavior: hamburger menu <768px, full nav ≥768px
- [ ] T078 Test modal responsive behavior: full-screen on mobile, centered on desktop

**Checkpoint**: Run `npx playwright test --project=chromium --project=firefox --project=webkit` - All tests PASS on all browsers

---

## Phase 9: Performance Optimization

**Purpose**: Ensure <3s page load and Lighthouse score ≥90

- [ ] T079 Minify CSS files using clean-css-cli: frontend/styles/*.css → *.min.css
- [ ] T080 Minify JavaScript files using terser: frontend/scripts/*.js → *.min.js
- [ ] T081 Update frontend/index.html to reference minified assets in production
- [ ] T082 [P] Add lazy loading for below-the-fold images (features, catalog) using `loading="lazy"` attribute
- [ ] T083 [P] Implement critical CSS extraction for hero section and inline in index.html <head>
- [ ] T084 [P] Add preload hints for hero background image in index.html <head>
- [ ] T085 Verify total page weight <500KB uncompressed using `curl -s http://localhost:8000 | wc -c`
- [ ] T086 Run Lighthouse audit with `lighthouse http://localhost:8000 --output=html --output-path=reports/lighthouse.html`
- [ ] T087 Fix any Lighthouse performance issues to achieve ≥90 score
- [ ] T088 Fix any Lighthouse accessibility issues to achieve 100 score

**Checkpoint**: Lighthouse performance ≥90, accessibility 100, page load <3s

---

## Phase 10: Polish & Documentation

**Purpose**: Final touches and deployment preparation

- [ ] T089 [P] Run ESLint on frontend/scripts/*.js and fix all warnings
- [ ] T090 [P] Run Stylelint on frontend/styles/*.css and fix all warnings
- [ ] T091 [P] Add JSDoc comments to all functions in frontend/scripts/*.js
- [ ] T092 [P] Add code quality badges to README.md (Lighthouse scores, test coverage)
- [ ] T093 Validate HTML5 syntax with `npx html-validate frontend/index.html`
- [ ] T094 Test OAuth flow end-to-end with real AWS Cognito credentials (manual test)
- [ ] T095 Create deployment script in tools/deploy-landing-page.sh for S3 sync and CloudFront invalidation
- [ ] T096 Update docs/api-documentation.md with landing page endpoints and OAuth flow
- [ ] T097 Run through quickstart.md instructions to verify accuracy
- [ ] T098 Create PR with landing page implementation and link to tasks.md

**Checkpoint**: All tasks complete, ready for deployment to production

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if staffed)
  - Or sequentially in priority order: US1 (P1) → US2 (P2) → US3 (P2) → US4 (P3)
- **Cross-Cutting (Phase 7)**: Can start after any user story completes
- **Cross-Browser (Phase 8)**: Depends on all user stories being complete
- **Performance (Phase 9)**: Depends on all implementation complete
- **Polish (Phase 10)**: Depends on all previous phases complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Integrates with US1 CTA but independently testable
- **User Story 4 (P3)**: Can start after Foundational (Phase 2) - No dependencies on other stories (navigation is independent)

### Within Each User Story

1. Write Playwright tests FIRST (all tests marked [P] can run in parallel)
2. Run tests → verify they FAIL
3. Implement HTML structure
4. Implement CSS styles
5. Implement JavaScript interactions
6. Run tests → verify they PASS
7. Story complete

### Parallel Opportunities

**Setup Phase (Phase 1)**:
- T003, T004, T005 can all run in parallel (different tools/files)

**Foundational Phase (Phase 2)**:
- T007, T008, T009, T010, T012 can all run in parallel (different files)
- T006 and T011 should run sequentially (T011 depends on CSS variables from T006)

**User Story Implementation**:
- Once Phase 2 completes, ALL user stories (Phase 3, 4, 5, 6) can start in parallel if team has capacity
- Tests within each story (all marked [P]) can run in parallel
- HTML/CSS/JS tasks within a story must be somewhat sequential, but CSS and JS can overlap

**Cross-Cutting Phase (Phase 7)**:
- T061, T062, T063, T064, T065, T069, T070 can all run in parallel (different concerns)

**Cross-Browser Phase (Phase 8)**:
- T071, T072, T073 can run in parallel (different test suites)

**Performance Phase (Phase 9)**:
- T082, T083, T084 can run in parallel (different optimization techniques)
- T089, T090, T091, T092 can run in parallel (different linting/documentation tasks)

---

## Parallel Execution Example: User Story 1

```bash
# After Phase 2 completes, parallelize US1 test creation
# Terminal 1: Create main E2E tests
npx playwright codegen http://localhost:8000  # Record test for T013

# Terminal 2: Create performance tests
touch tests/e2e/performance.spec.js  # T016

# Terminal 3: Create HTML structure
code frontend/index.html  # T017

# Terminal 4: Create hero CSS
code frontend/styles/hero.css  # T018

# All run in parallel, then converge for integration (T019-T023)
```

---

## Parallel Execution Example: All User Stories (with team)

```bash
# After Phase 2 completes, split team across user stories
# Developer 1: US1 (Hero Section) - Priority 1
cd specs/001-landing-page && echo "Working on US1"

# Developer 2: US2 (Features Section) - Priority 2
cd specs/001-landing-page && echo "Working on US2"

# Developer 3: US3 (Catalog Section) - Priority 2
cd specs/001-landing-page && echo "Working on US3"

# Developer 4: US4 (Login/Auth) - Priority 3
cd specs/001-landing-page && echo "Working on US4"

# Each developer follows TDD: write tests → implement → verify
# All stories independently testable and deliverable
```

---

## MVP Scope Recommendation

**Minimum Viable Product (MVP)**: User Story 1 ONLY

**Rationale**: 
- US1 delivers the core value proposition and primary CTA
- Achieves primary success criterion: 3-second comprehension
- Can be deployed independently to validate interest
- Enables early user feedback before building features/catalog/auth

**MVP Includes**:
- Phase 1 (Setup)
- Phase 2 (Foundational)
- Phase 3 (User Story 1: Hero Section)
- Subset of Phase 7 (Footer, basic accessibility)
- Subset of Phase 9 (Performance optimization)

**MVP Excludes**:
- User Story 2 (Features) - can add post-launch
- User Story 3 (Catalog) - can add post-launch
- User Story 4 (Login) - can add post-launch
- Advanced cross-browser testing - focus Chrome/Safari only for MVP

**MVP Task Count**: ~30 tasks (vs. 98 total)
**MVP Timeline Estimate**: 3-5 days for single developer

---

## Summary

- **Total Tasks**: 98
- **User Story Tasks**: 
  - US1 (P1 - Hero): 11 tasks (T013-T023)
  - US2 (P2 - Features): 9 tasks (T024-T032)
  - US3 (P2 - Catalog): 10 tasks (T033-T042)
  - US4 (P3 - Login): 18 tasks (T043-T060)
- **Infrastructure Tasks**: 12 tasks (Setup + Foundational)
- **Quality/Polish Tasks**: 38 tasks (Cross-cutting, Testing, Performance, Documentation)
- **Parallel Opportunities**: 40+ tasks marked [P] can run simultaneously
- **MVP Recommendation**: US1 only (30 tasks, 3-5 days)
- **Full Implementation Estimate**: 10-15 days for single developer, 5-7 days for team of 4

**Format Validation**: ✅ All 98 tasks follow required format: `- [ ] [TaskID] [P?] [Story?] Description with file path`

**Next Steps**:
1. Decide MVP scope (US1 only vs. full feature)
2. Run `npm install` to install Playwright and testing dependencies
3. Start Phase 1 (Setup) tasks T001-T005
4. Begin TDD workflow for User Story 1
