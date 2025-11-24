# Quick Start: Landing Page Development

**Feature**: 001-landing-page  
**Version**: 1.0.0  
**Date**: 2025-11-23

## Prerequisites

- **Node.js**: v18+ (for Playwright)
- **Python**: 3.12+ (for local Lighthouse testing via AWS SAM)
- **AWS CLI**: Configured with profile for S3/CloudFront deployment
- **Git**: Current branch `001-landing-page`

**Install Dependencies**:
```bash
# Playwright (E2E testing)
npm init -y
npm install --save-dev playwright @playwright/test
npx playwright install

# Lighthouse CI (performance testing)
npm install --save-dev @lhci/cli

# Accessibility testing
npm install --save-dev axe-core
```

## Local Development

### 1. Serve Static Files

**Option A: Python HTTP Server** (recommended for simplicity)
```bash
cd frontend
python3 -m http.server 8000
# Access at http://localhost:8000
```

**Option B: Node.js `http-server`**
```bash
npm install -g http-server
cd frontend
http-server -p 8000
# Access at http://localhost:8000
```

### 2. File Structure

```
frontend/
├── index.html              # Main landing page
├── callback.html           # OAuth callback handler
├── styles/
│   ├── main.css            # Global styles
│   ├── hero.css            # Hero section
│   ├── features.css        # Features section
│   ├── catalog.css         # Course catalog
│   ├── navigation.css      # Navigation/footer
│   └── modal.css           # Login modal
├── scripts/
│   ├── auth.js             # Cognito OAuth logic
│   ├── catalog.js          # Course data
│   └── navigation.js       # Smooth scroll, mobile menu
└── assets/
    ├── images/
    │   ├── hero-bg.webp    # Hero background
    │   ├── hero-bg.jpg     # Fallback
    │   └── logo.svg        # Brand logo
    └── icons/
        ├── python.svg
        ├── java.svg
        └── rust.svg
```

### 3. Hot Reload (Optional)

For live CSS/JS updates without manual refresh:

```bash
npm install -g browser-sync
browser-sync start --server frontend --files "frontend/**/*"
# Access at http://localhost:3000
```

## Testing

### Unit Tests (JavaScript Logic)

**Test Framework**: Jest (to be added if needed)

**Run Tests**:
```bash
# Future: npm test
echo "No JavaScript unit tests for static landing page"
```

### E2E Tests (Playwright)

**Test Location**: `tests/e2e/landing-page.spec.js`

**Run Tests**:
```bash
# All browsers
npx playwright test

# Single browser (Chromium)
npx playwright test --project=chromium

# Headed mode (watch browser)
npx playwright test --headed

# Debug mode
npx playwright test --debug
```

**Example Test** (create as `tests/e2e/landing-page.spec.js`):
```javascript
import { test, expect } from '@playwright/test';

test('homepage loads within 3 seconds', async ({ page }) => {
  const startTime = Date.now();
  await page.goto('http://localhost:8000');
  
  // Check hero headline is visible
  const headline = page.locator('h1');
  await expect(headline).toBeVisible();
  await expect(headline).toContainText('Learn to Code');
  
  const loadTime = Date.now() - startTime;
  expect(loadTime).toBeLessThan(3000);
});

test('displays 3 course categories', async ({ page }) => {
  await page.goto('http://localhost:8000');
  
  const courses = page.locator('.course-card');
  await expect(courses).toHaveCount(3);
  
  // Verify course names
  await expect(page.getByText('Python Programming')).toBeVisible();
  await expect(page.getByText('Java Development')).toBeVisible();
  await expect(page.getByText('Rust Systems')).toBeVisible();
});

test('login button opens Cognito OAuth flow', async ({ page, context }) => {
  await page.goto('http://localhost:8000');
  
  // Click login, expect redirect to Cognito
  const [popup] = await Promise.all([
    context.waitForEvent('page'),
    page.click('button:has-text("Login")')
  ]);
  
  await popup.waitForLoadState();
  expect(popup.url()).toContain('cognito');
  expect(popup.url()).toContain('oauth2/authorize');
});
```

### Accessibility Tests (axe-core)

**Test Location**: `tests/e2e/accessibility.spec.js`

**Run Tests**:
```bash
npx playwright test tests/e2e/accessibility.spec.js
```

**Example Test**:
```javascript
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('landing page passes WCAG 2.1 Level AA', async ({ page }) => {
  await page.goto('http://localhost:8000');
  
  const accessibilityScanResults = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa'])
    .analyze();
  
  expect(accessibilityScanResults.violations).toEqual([]);
});
```

### Performance Tests (Lighthouse)

**Run Lighthouse**:
```bash
# Install Lighthouse CLI
npm install -g lighthouse

# Run against local server
lighthouse http://localhost:8000 \
  --output html \
  --output-path reports/lighthouse.html \
  --preset=desktop \
  --only-categories=performance,accessibility

# View report
open reports/lighthouse.html
```

**Expected Scores**:
- Performance: 90+
- Accessibility: 100
- Best Practices: 90+

**Lighthouse CI** (automated):
```bash
# Create lighthouserc.json
cat > lighthouserc.json << EOF
{
  "ci": {
    "collect": {
      "url": ["http://localhost:8000"],
      "numberOfRuns": 3
    },
    "assert": {
      "assertions": {
        "categories:performance": ["error", {"minScore": 0.9}],
        "categories:accessibility": ["error", {"minScore": 1.0}]
      }
    }
  }
}
EOF

# Run LHCI
lhci autorun
```

## Deployment

### 1. Build Artifacts

**Optimize Images**:
```bash
# Install ImageMagick (macOS)
brew install imagemagick

# Convert PNGs to WebP
magick convert frontend/assets/images/hero-bg.jpg \
  -quality 85 frontend/assets/images/hero-bg.webp

# Verify size < 500KB
ls -lh frontend/assets/images/hero-bg.webp
```

**Minify CSS/JS** (optional, since files are small):
```bash
npm install -g clean-css-cli terser

# Minify CSS
cleancss -o frontend/styles/main.min.css frontend/styles/main.css

# Minify JS
terser frontend/scripts/auth.js -o frontend/scripts/auth.min.js
```

### 2. Deploy to S3

**Sync Files**:
```bash
# Set variables
BUCKET_NAME="codelearn-frontend"
AWS_PROFILE="codelearn-dev"

# Sync to S3
aws s3 sync frontend/ s3://${BUCKET_NAME}/ \
  --profile ${AWS_PROFILE} \
  --delete \
  --cache-control "public, max-age=3600"

# Set cache-control for HTML (no cache)
aws s3 cp s3://${BUCKET_NAME}/index.html s3://${BUCKET_NAME}/index.html \
  --profile ${AWS_PROFILE} \
  --cache-control "no-cache" \
  --metadata-directive REPLACE
```

### 3. Invalidate CloudFront Cache

**Create Invalidation**:
```bash
DISTRIBUTION_ID="E1A2B3C4D5E6F7"

aws cloudfront create-invalidation \
  --profile ${AWS_PROFILE} \
  --distribution-id ${DISTRIBUTION_ID} \
  --paths "/*"
```

**Verify Deployment**:
```bash
# Check if index.html is updated
curl -I https://codelearn.ai/ | grep -i last-modified

# Test page load
curl -s https://codelearn.ai/ | grep -i "<title>"
```

## Debugging

### Common Issues

**1. OAuth Callback 404**:
- **Cause**: `callback.html` missing or not deployed
- **Fix**: Ensure `frontend/callback.html` exists and is synced to S3

**2. CORS Errors on Cognito**:
- **Cause**: `redirect_uri` not whitelisted in Cognito App Client settings
- **Fix**: Add `https://codelearn.ai/callback` to Cognito allowed callback URLs

**3. Slow Page Load**:
- **Cause**: Large images or uncompressed CSS/JS
- **Check**: Run Lighthouse and review "Opportunities" section
- **Fix**: Compress images, minify CSS/JS, enable Gzip on S3

**4. Test Failures (Playwright)**:
- **Cause**: Local server not running or wrong port
- **Fix**: Start `python3 -m http.server 8000` before running tests

### Logs

**Playwright Test Logs**:
```bash
# Run with verbose logging
DEBUG=pw:api npx playwright test
```

**Browser Console Logs** (capture in tests):
```javascript
page.on('console', msg => console.log('Browser:', msg.text()));
```

## CI/CD Integration

**GitHub Actions Workflow** (future):
```yaml
name: Landing Page CI

on:
  push:
    branches: [001-landing-page]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: python3 -m http.server 8000 &
      - run: npx playwright test
      - run: lhci autorun

  deploy:
    needs: test
    if: github.ref == 'refs/heads/001-landing-page'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to S3
        run: |
          aws s3 sync frontend/ s3://codelearn-frontend/ --delete
          aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          DISTRIBUTION_ID: ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }}
```

## Useful Commands

```bash
# Check syntax errors in HTML
npx html-validate frontend/index.html

# Check CSS validity
npx stylelint "frontend/styles/**/*.css"

# Check JavaScript syntax
npx eslint frontend/scripts/

# Measure page size
curl -s https://codelearn.ai/ | wc -c  # Should be < 500KB

# Test mobile viewport (Playwright)
npx playwright test --device="iPhone 13"
```

## Next Steps

1. Run `npx playwright test` to execute E2E tests
2. Run `lighthouse http://localhost:8000` to verify performance
3. Deploy to S3 with `aws s3 sync frontend/ s3://codelearn-frontend/`
4. Monitor CloudFront logs for errors: `aws logs tail /aws/cloudfront/codelearn-frontend --follow`
