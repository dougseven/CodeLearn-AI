/**
 * Main JavaScript Entry Point
 * Handles page initialization and CTA interactions (T022)
 * 
 * @module main
 */

import authManager from './auth.js';

// Initialize page on DOMContentLoaded
document.addEventListener('DOMContentLoaded', () => {
  initializeHeroCTA();
  checkAuthStatus();
});

/**
 * Initialize hero CTA button click handler (T022)
 */
function initializeHeroCTA() {
  const ctaButton = document.getElementById('hero-cta');

  if (ctaButton) {
    ctaButton.addEventListener('click', () => {
      // For MVP, trigger login flow
      // In future, could show modal with "Sign Up" vs "Log In" options
      authManager.login();
    });
  }
}

/**
 * Check authentication status and update UI accordingly
 */
function checkAuthStatus() {
  if (authManager.isAuthenticated()) {
    // User is logged in - could update CTA to "Go to Dashboard"
    const ctaButton = document.getElementById('hero-cta');
    if (ctaButton) {
      ctaButton.textContent = 'Go to Dashboard';
      ctaButton.addEventListener('click', (e) => {
        e.stopPropagation();
        // Navigate to dashboard (placeholder for now)
        window.location.href = '/dashboard';
      });
    }
  }
}

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
  anchor.addEventListener('click', (e) => {
    e.preventDefault();
    const targetId = anchor.getAttribute('href').slice(1);
    const targetElement = document.getElementById(targetId);

    if (targetElement) {
      targetElement.scrollIntoView({
        behavior: 'smooth',
        block: 'start',
      });
    }
  });
});
