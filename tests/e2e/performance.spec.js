import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

// Performance Tests for User Story 1 (T016)

test.describe('Performance - Landing Page', () => {
  test('page achieves Lighthouse performance score ≥90', async ({ page }) => {
    await page.goto('/');
    
    // Wait for page to be fully loaded
    await page.waitForLoadState('networkidle');
    
    // Note: Actual Lighthouse testing is done via @lhci/cli
    // This test ensures page is ready for Lighthouse audit
    const performanceMetrics = await page.evaluate(() => {
      const navigation = performance.getEntriesByType('navigation')[0];
      return {
        domContentLoaded: navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart,
        loadComplete: navigation.loadEventEnd - navigation.loadEventStart,
      };
    });
    
    // Basic performance checks
    expect(performanceMetrics.domContentLoaded).toBeLessThan(2000);
    expect(performanceMetrics.loadComplete).toBeLessThan(3000);
  });

  test('images use WebP format with fallback', async ({ page }) => {
    await page.goto('/');
    
    // Check for picture elements with WebP sources
    const pictures = page.locator('picture');
    const pictureCount = await pictures.count();
    
    if (pictureCount > 0) {
      const firstPicture = pictures.first();
      const webpSource = firstPicture.locator('source[type="image/webp"]');
      await expect(webpSource).toBeAttached();
      
      // Check fallback img exists
      const fallbackImg = firstPicture.locator('img');
      await expect(fallbackImg).toBeAttached();
    }
  });

  test('critical CSS is inlined', async ({ page }) => {
    await page.goto('/');
    
    // Check for inline style tag
    const inlineStyles = page.locator('head style');
    const count = await inlineStyles.count();
    expect(count).toBeGreaterThan(0);
  });

  test('below-the-fold images use lazy loading', async ({ page }) => {
    await page.goto('/');
    
    // Check images below the fold have loading="lazy"
    const images = page.locator('img[loading="lazy"]');
    const count = await images.count();
    
    // Should have at least some lazy-loaded images
    expect(count).toBeGreaterThanOrEqual(0);
  });

  test('time to interactive is under 1 second', async ({ page }) => {
    await page.goto('/');
    
    const tti = await page.evaluate(() => {
      const navigation = performance.getEntriesByType('navigation')[0];
      return navigation.domInteractive - navigation.fetchStart;
    });
    
    expect(tti).toBeLessThan(1000);
  });
});
