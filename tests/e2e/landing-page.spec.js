import { test, expect } from '@playwright/test';

// User Story 1 Tests: First-Time Visitor Discovers Platform (T013-T015)

test.describe('Landing Page - Hero Section', () => {
  test('homepage loads within 3 seconds', async ({ page }) => {
    const startTime = Date.now();
    
    await page.goto('/');
    
    // Wait for hero section to be visible
    const heroSection = page.locator('.hero');
    await expect(heroSection).toBeVisible();
    
    const loadTime = Date.now() - startTime;
    expect(loadTime).toBeLessThan(3000);
  });

  test('hero section displays value proposition and CTA', async ({ page }) => {
    await page.goto('/');
    
    // Check for headline with "AI-powered" and "personalized learning" keywords
    const headline = page.locator('h1');
    await expect(headline).toBeVisible();
    const headlineText = await headline.textContent();
    expect(headlineText).toMatch(/AI[-\s]powered/i);
    expect(headlineText).toMatch(/personalized/i);
    expect(headlineText).toMatch(/learn/i);
    
    // Check for tagline
    const tagline = page.locator('.hero__tagline, .tagline');
    await expect(tagline).toBeVisible();
    
    // Check for primary CTA button
    const ctaButton = page.locator('button:has-text("Start Your Learning Journey"), a:has-text("Start Your Learning Journey")');
    await expect(ctaButton).toBeVisible();
  });

  test('primary CTA button is visible and clickable', async ({ page }) => {
    await page.goto('/');
    
    const ctaButton = page.locator('button:has-text("Start Your Learning Journey"), a:has-text("Start Your Learning Journey")').first();
    
    // Check button is in viewport without scrolling
    await expect(ctaButton).toBeVisible();
    await expect(ctaButton).toBeInViewport();
    
    // Check button is clickable
    await expect(ctaButton).toBeEnabled();
    
    // Click button and verify action (should open modal or navigate)
    await ctaButton.click();
    
    // Check if modal appears or navigation occurs
    // (Implementation will depend on actual behavior)
  });

  test('hero section displays platform name', async ({ page }) => {
    await page.goto('/');
    
    // Check for CodeLearn branding
    const brandText = page.locator('text=/CodeLearn/i');
    await expect(brandText).toBeVisible();
  });

  test('hero section content is accessible via keyboard', async ({ page }) => {
    await page.goto('/');
    
    // Tab to CTA button
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    
    // Check that CTA button has focus
    const ctaButton = page.locator('button:has-text("Start Your Learning Journey"), a:has-text("Start Your Learning Journey")').first();
    await expect(ctaButton).toBeFocused();
    
    // Press Enter to activate
    await page.keyboard.press('Enter');
  });
});
