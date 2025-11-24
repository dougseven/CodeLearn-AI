/**
 * Production Deployment Verification Tests
 * Validates live production site on CloudFront
 */

const { test, expect } = require('@playwright/test');

const PRODUCTION_URL = 'https://d26aeuhfo3vnoz.cloudfront.net';

test.describe('Production Deployment', () => {
  test('production site loads successfully', async ({ page }) => {
    const response = await page.goto(PRODUCTION_URL);
    expect(response.status()).toBe(200);
    
    // Verify page title
    await expect(page).toHaveTitle(/CodeLearn AI/);
  });

  test('hero section renders correctly in production', async ({ page }) => {
    await page.goto(PRODUCTION_URL);
    
    // Check hero content
    const hero = page.locator('.hero');
    await expect(hero).toBeVisible();
    
    // Verify headline contains key messaging
    const headline = page.locator('.hero__title, h1');
    await expect(headline).toContainText(/AI/i);
    await expect(headline).toContainText(/learn|education|personalized/i);
    
    // Verify CTA button
    const ctaButton = page.locator('#hero-cta, button:has-text("Start Your Learning Journey")');
    await expect(ctaButton).toBeVisible();
  });

  test('authentication flow works in production', async ({ page, context }) => {
    await page.goto(PRODUCTION_URL);
    
    // Click CTA button
    const ctaButton = page.locator('#hero-cta, button:has-text("Start Your Learning Journey")');
    await ctaButton.click();
    
    // Should redirect to Cognito login
    await page.waitForURL(/amazoncognito\.com/, { timeout: 10000 });
    
    const url = page.url();
    expect(url).toContain('codelearn-224157924354.auth.us-east-1.amazoncognito.com');
    expect(url).toContain('client_id=');
    expect(url).toContain('redirect_uri=');
    expect(url).toContain('response_type=code');
  });

  test('all static assets load successfully', async ({ page }) => {
    const failedRequests = [];
    
    page.on('requestfailed', (request) => {
      failedRequests.push(request.url());
    });
    
    await page.goto(PRODUCTION_URL);
    
    // Wait for page to fully load
    await page.waitForLoadState('networkidle');
    
    // Filter out expected 404s (hero-bg.webp is optional)
    const criticalFailures = failedRequests.filter((url) => !url.includes('hero-bg.webp'));
    
    expect(criticalFailures).toHaveLength(0);
  });

  test('responsive design works on mobile', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto(PRODUCTION_URL);
    
    // Verify hero is visible
    const hero = page.locator('.hero');
    await expect(hero).toBeVisible();
    
    // Verify CTA button is visible and clickable
    const ctaButton = page.locator('#hero-cta');
    await expect(ctaButton).toBeVisible();
    
    const box = await ctaButton.boundingBox();
    expect(box).not.toBeNull();
    expect(box.width).toBeGreaterThan(0);
    expect(box.height).toBeGreaterThan(0);
  });

  test('CloudFront caching headers are correct', async ({ page }) => {
    const response = await page.goto(PRODUCTION_URL);
    
    // Check for caching headers
    const headers = response.headers();
    
    // HTML should not be cached
    if (headers['content-type']?.includes('text/html')) {
      expect(headers['cache-control']).toContain('no-cache');
    }
    
    // CloudFront should add headers
    expect(headers['x-amz-cf-id']).toBeDefined();
    expect(headers['x-cache']).toBeDefined();
  });
});
