# Research: CodeLearn AI Landing Page

**Feature**: 001-landing-page  
**Phase**: 0 (Research & Best Practices)  
**Purpose**: Resolve NEEDS CLARIFICATION items from Technical Context and establish technology choices with rationale

---

## Research Items

### 1. JavaScript Approach: Vanilla JS vs. Minimal Library

**Question**: Should we use vanilla JavaScript or a lightweight library (like Alpine.js) for modal interactions and UI state management?

**Research Findings**:

**Vanilla JavaScript**:
- ✅ Zero dependencies, no build step, instant page load
- ✅ Full control over code size and performance
- ✅ Aligns with existing CodeLearn frontend architecture (no frameworks mentioned in constitution)
- ✅ Easier to understand for educational platform (our code should be exemplary)
- ❌ More code for managing modal state, event delegation, and accessibility

**Alpine.js (15KB gzipped)**:
- ✅ Declarative syntax for interactive components (x-data, x-show)
- ✅ Built-in accessibility features for modals
- ✅ Minimal learning curve, works directly in HTML
- ❌ External dependency, requires CDN or hosting
- ❌ Adds ~15KB to page weight (still within 500KB constraint)

**Alternatives Considered**:
- React/Vue: Rejected - massive overkill for a single landing page, violates "no JavaScript frameworks" constraint
- jQuery: Rejected - outdated, larger than Alpine.js, no modern advantages

**Decision**: **Vanilla JavaScript**

**Rationale**:
1. **Educational Alignment**: CodeLearn teaches coding best practices. Using vanilla JS demonstrates modern browser APIs and best practices without framework magic.
2. **Performance**: Zero dependencies = fastest possible load time. Modal interactions require ~50 lines of clean JavaScript.
3. **Constitution Compliance**: Aligns with existing architecture (no frameworks mentioned). Future maintainers won't need to learn a library.
4. **Cost**: No CDN dependencies = no external failure points, no additional costs.

**Implementation Notes**:
- Use modern APIs: `dialog` element for modal (native browser support), `IntersectionObserver` for lazy loading
- Ensure accessibility: trap focus in modal, ARIA labels, keyboard navigation (Tab, Esc)
- Total JS budget: ~200 lines for auth modal, navigation, and analytics tracking

---

### 2. E2E Testing Framework: Cypress vs. Playwright

**Question**: Which end-to-end testing framework should we use for landing page functional tests?

**Research Findings**:

**Cypress**:
- ✅ Popular choice (large community, extensive documentation)
- ✅ Built-in test runner with visual debugging
- ✅ Automatic waiting (no need for explicit waits)
- ✅ Time-travel debugging for failed tests
- ❌ Chrome/Edge/Firefox only (no Safari support)
- ❌ Slower test execution for cross-browser tests

**Playwright (Microsoft)**:
- ✅ True cross-browser testing (Chrome, Firefox, Safari, Edge)
- ✅ Faster test execution, parallel test runs
- ✅ Better mobile device emulation
- ✅ Network interception for mocking AWS Cognito responses
- ✅ Built-in accessibility auditing (axe-core integration)
- ❌ Smaller community than Cypress (but growing rapidly)
- ❌ Less mature ecosystem for plugins

**Alternatives Considered**:
- Selenium: Rejected - verbose API, slower execution, outdated tooling
- TestCafe: Rejected - less adoption, fewer features than Cypress/Playwright

**Decision**: **Playwright**

**Rationale**:
1. **Cross-Browser Requirement**: FR-016 requires Chrome, Firefox, Safari, Edge support. Playwright tests all four natively. Cypress would require additional tooling for Safari.
2. **Accessibility Priority**: FR-015 (WCAG 2.1 AA) is non-negotiable. Playwright's built-in axe-core integration automates accessibility audits.
3. **Mobile Testing**: FR-011 requires mobile responsiveness (320px-768px). Playwright's device emulation is superior.
4. **Performance**: Faster test execution means faster CI/CD feedback loops, reducing development friction.

**Implementation Notes**:
- Test matrix: Chrome (desktop/mobile), Firefox, Safari, Edge
- Accessibility tests: Run axe audit on each page state (default, modal open, logged-in)
- Cognito integration: Mock OAuth responses for deterministic tests
- Target test suite execution time: <2 minutes

---

## Best Practices & Patterns

### 3. Responsive Design Strategy

**Decision**: Mobile-First CSS with CSS Grid/Flexbox

**Best Practices**:
- Start with mobile layout (320px), progressively enhance for tablet (768px) and desktop (1200px+)
- Use CSS Grid for two-dimensional layouts (hero section, course catalog grid)
- Use Flexbox for one-dimensional layouts (navigation, feature cards)
- CSS custom properties (variables) for breakpoints, colors, spacing
- `clamp()` for fluid typography (16px-24px range)

**Example Breakpoints**:
```css
:root {
  --bp-mobile: 320px;
  --bp-tablet: 768px;
  --bp-desktop: 1200px;
}

/* Mobile-first: default styles for 320px+ */
.hero { padding: 2rem 1rem; }

/* Tablet: 768px+ */
@media (min-width: 768px) {
  .hero { padding: 4rem 2rem; }
}

/* Desktop: 1200px+ */
@media (min-width: 1200px) {
  .hero { padding: 6rem 4rem; }
}
```

---

### 4. Image Optimization Strategy

**Decision**: WebP with JPEG Fallback + Lazy Loading

**Best Practices**:
- Primary format: WebP (30-50% smaller than JPEG, supported by 95%+ browsers)
- Fallback: JPEG for legacy browsers (Safari < 14)
- Use `<picture>` element for responsive images:
  ```html
  <picture>
    <source srcset="hero-bg.webp" type="image/webp">
    <img src="hero-bg.jpg" alt="CodeLearn AI platform">
  </picture>
  ```
- Lazy load below-the-fold images: `loading="lazy"` attribute
- Responsive images: provide 1x, 2x, 3x versions for different screen densities
- Icon strategy: Use SVGs (inline for critical icons like logo, external for language icons)

**Image Budget**:
- Hero background: ~150KB (compressed WebP)
- Platform logo: ~5KB (SVG)
- Language icons (3×): ~15KB total (SVG)
- Feature icons (3×): ~15KB total (SVG)
- **Total**: ~185KB images + ~50KB CSS + ~10KB JS = ~245KB (well under 500KB constraint)

---

### 5. Accessibility (WCAG 2.1 Level AA) Checklist

**Required Implementations**:
- **Keyboard Navigation**: All interactive elements accessible via Tab, Enter, Esc
- **Screen Reader Support**: Semantic HTML5 (`<header>`, `<nav>`, `<main>`, `<footer>`), ARIA labels where needed
- **Color Contrast**: Minimum 4.5:1 for normal text, 3:1 for large text (18px+)
- **Focus Indicators**: Visible focus states for all interactive elements
- **Skip Links**: "Skip to main content" link for keyboard users
- **Form Labels**: Explicit `<label>` elements for email/password inputs
- **Error Messages**: Associated with form fields via `aria-describedby`
- **Modal Accessibility**: Focus trap, close on Esc, return focus on close

**Testing Tools**:
- Lighthouse accessibility audit (target score: 100)
- axe DevTools browser extension
- NVDA/JAWS screen reader manual testing

---

### 6. Performance Optimization Checklist

**Required Implementations**:
- **Critical CSS**: Inline above-the-fold styles (~5KB) in `<head>`
- **Async JavaScript**: Load auth/analytics scripts with `defer` attribute
- **Resource Hints**: Use `<link rel="preconnect">` for Cognito domain
- **Compression**: Enable Gzip/Brotli on CloudFront (60-80% size reduction)
- **Caching**: Set long cache headers for static assets (1 year), short for HTML (5 minutes)
- **Minification**: Minify CSS/JS in production (remove whitespace, comments)
- **CDN**: Use CloudFront edge locations for global low-latency delivery

**Performance Budget**:
- Time to First Byte (TTFB): <200ms
- First Contentful Paint (FCP): <1s
- Largest Contentful Paint (LCP): <2.5s
- Time to Interactive (TTI): <3s
- Total page weight: <500KB (target: 245KB)

---

## Technology Decisions Summary

| Question | Decision | Rationale |
|----------|----------|-----------|
| JavaScript Approach | Vanilla JavaScript | Zero dependencies, educational value, aligns with architecture, best performance |
| E2E Testing | Playwright | Cross-browser support (Safari!), built-in accessibility audits, faster execution |
| Responsive Strategy | Mobile-First CSS Grid/Flexbox | Industry standard, progressive enhancement, clean code |
| Image Format | WebP + JPEG fallback | 30-50% smaller than JPEG, 95%+ browser support, graceful degradation |
| Performance | Critical CSS + lazy loading | <3s load time, meets FR-012 and SC-003 targets |

**All NEEDS CLARIFICATION items resolved**. Proceeding to Phase 1 (data model, contracts, quickstart).
