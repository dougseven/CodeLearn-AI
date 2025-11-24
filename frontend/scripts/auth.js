/**
 * Authentication Manager for AWS Cognito OAuth 2.0
 * Handles login flow, session management, and token storage
 * 
 * @module auth
 */

// AWS Cognito Configuration (T011)
const AUTH_CONFIG = {
  cognitoDomain: 'codelearn-224157924354.auth.us-east-1.amazoncognito.com',
  clientId: '5d79u7rce8b9ks156lgemd9rd7',
  redirectUri: `${window.location.origin}/callback.html`,
  scopes: ['openid', 'email', 'profile'],
  region: 'us-east-1',
  userPoolId: 'us-east-1_UoB26Bz23',
};

/**
 * AuthManager class for handling authentication operations
 */
class AuthManager {
  constructor() {
    this.sessionKey = 'codelearn_session';
    this.stateKey = 'oauth_state';
  }

  /**
   * Generate cryptographically random state token for CSRF protection
   * @returns {string} Random state token
   */
  generateState() {
    const array = new Uint8Array(32);
    crypto.getRandomValues(array);
    return Array.from(array, (byte) => byte.toString(16).padStart(2, '0')).join('');
  }

  /**
   * Initiate OAuth 2.0 login flow
   * Redirects user to Cognito hosted UI
   */
  login() {
    const state = this.generateState();
    sessionStorage.setItem(this.stateKey, state);

    const params = new URLSearchParams({
      response_type: 'code',
      client_id: AUTH_CONFIG.clientId,
      redirect_uri: AUTH_CONFIG.redirectUri,
      scope: AUTH_CONFIG.scopes.join(' '),
      state,
    });

    const authUrl = `https://${AUTH_CONFIG.cognitoDomain}/oauth2/authorize?${params.toString()}`;
    window.location.href = authUrl;
  }

  /**
   * Logout user and clear session
   * Redirects to Cognito logout endpoint
   */
  logout() {
    this.clearSession();

    const params = new URLSearchParams({
      client_id: AUTH_CONFIG.clientId,
      logout_uri: window.location.origin,
    });

    const logoutUrl = `https://${AUTH_CONFIG.cognitoDomain}/logout?${params.toString()}`;
    window.location.href = logoutUrl;
  }

  /**
   * Check if user is authenticated
   * @returns {boolean} True if user has valid session
   */
  isAuthenticated() {
    const session = this.getSession();
    if (!session || !session.accessToken) {
      return false;
    }

    // Check token expiry
    if (session.tokenExpiry && Date.now() >= session.tokenExpiry) {
      this.clearSession();
      return false;
    }

    return true;
  }

  /**
   * Get current session data
   * @returns {Object|null} Session object or null if not authenticated
   */
  getSession() {
    try {
      const sessionData = sessionStorage.getItem(this.sessionKey);
      return sessionData ? JSON.parse(sessionData) : null;
    } catch (error) {
      console.error('Error reading session:', error);
      return null;
    }
  }

  /**
   * Store session data
   * @param {Object} tokens - Token object from Cognito
   */
  setSession(tokens) {
    const session = {
      accessToken: tokens.access_token,
      idToken: tokens.id_token,
      tokenExpiry: Date.now() + (tokens.expires_in * 1000),
      isAuthenticated: true,
    };

    try {
      sessionStorage.setItem(this.sessionKey, JSON.stringify(session));
    } catch (error) {
      console.error('Error storing session:', error);
    }
  }

  /**
   * Clear session data
   */
  clearSession() {
    sessionStorage.removeItem(this.sessionKey);
    sessionStorage.removeItem(this.stateKey);
  }

  /**
   * Parse and validate ID token (JWT)
   * @param {string} idToken - JWT token from Cognito
   * @returns {Object|null} Decoded token payload or null if invalid
   */
  parseIdToken(idToken) {
    try {
      const parts = idToken.split('.');
      if (parts.length !== 3) {
        return null;
      }

      const payload = JSON.parse(atob(parts[1]));

      // Basic validation
      const now = Math.floor(Date.now() / 1000);
      if (payload.exp && payload.exp < now) {
        console.warn('Token expired');
        return null;
      }

      return payload;
    } catch (error) {
      console.error('Error parsing ID token:', error);
      return null;
    }
  }
}

// Export singleton instance
export default new AuthManager();
