# Chrome "Not Secure" Warning - HSTS Cache Issue

## Problem
Custom domain `https://codelearn.dougseven.com` shows "Not Secure" in Chrome even after:
- Clearing browser cache and cookies
- Configuring valid SSL certificate on CloudFront
- Site works fine in incognito mode ✅

## Root Cause
Chrome maintains a separate **HSTS (HTTP Strict Transport Security) cache** that stores domain security policies independently from the regular browser cache. When you previously accessed the domain over HTTP (or without HTTPS properly configured), Chrome cached this state and continues to apply it even after the SSL certificate is configured.

## Why Incognito Works
Incognito mode doesn't use the persistent HSTS cache, so it sees the current (correct) HTTPS configuration.

## Solution: Clear Chrome's HSTS Cache

### Step 1: Access Chrome's Network Internals
1. Open Chrome
2. Navigate to: `chrome://net-internals/#hsts`

### Step 2: Delete Domain Security Policy
1. Scroll down to **"Delete domain security policies"**
2. Enter domain: `codelearn.dougseven.com`
3. Click **"Delete"** button

### Step 3: Verify Deletion
1. Scroll up to **"Query HSTS/PKP domain"**
2. Enter domain: `codelearn.dougseven.com`
3. Result should show: **"Not found"** ✅

### Step 4: Restart Chrome
1. Close Chrome **completely** (Cmd+Q on Mac, Alt+F4 on Windows)
   - Don't just close the window - fully quit the application
2. Reopen Chrome
3. Visit: `https://codelearn.dougseven.com`
4. You should now see the **🔒 lock icon** and "Secure" status!

## Alternative Solutions

### If HSTS Cache Clear Doesn't Work:
1. **Restart your computer** - Clears all network stack caches
2. **Check Chrome flags**: Navigate to `chrome://flags` and search for SSL/HSTS related experiments that might be enabled

### For Other Browsers:
- **Firefox**: Clear history → Check "Active Logins" and "Site Settings"
- **Safari**: Safari → Clear History → All History
- **Edge**: Uses Chromium, follow Chrome steps above

## Prevention: Add HSTS Header to CloudFront

To prevent this issue in the future, we should add HSTS headers via CloudFront Functions:

```javascript
// CloudFront Function to add security headers
function handler(event) {
    var response = event.response;
    var headers = response.headers;
    
    // Add HSTS header (tells browsers to always use HTTPS)
    headers['strict-transport-security'] = { 
        value: 'max-age=31536000; includeSubDomains; preload' 
    };
    
    // Additional security headers
    headers['x-content-type-options'] = { value: 'nosniff' };
    headers['x-frame-options'] = { value: 'DENY' };
    headers['x-xss-protection'] = { value: '1; mode=block' };
    headers['referrer-policy'] = { value: 'strict-origin-when-cross-origin' };
    
    return response;
}
```

## Verification Commands

### Check if HSTS is being sent:
```bash
curl -sI https://codelearn.dougseven.com | grep -i "strict-transport-security"
```

### Test SSL certificate:
```bash
echo | openssl s_client -servername codelearn.dougseven.com -connect codelearn.dougseven.com:443 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```

### Verify CloudFront alias:
```bash
aws cloudfront get-distribution --id E1I9QUOHCNJM6L --query 'Distribution.DistributionConfig.Aliases'
```

## Expected Results

After following these steps, you should see:
- ✅ Green lock icon in Chrome address bar
- ✅ "Connection is secure" when clicking the lock
- ✅ Valid certificate information showing Amazon as issuer
- ✅ No "Not secure" warnings

## Common Mistakes

❌ **Just clearing cache/cookies** - Doesn't clear HSTS cache  
❌ **Only closing Chrome windows** - HSTS cache persists until full quit  
❌ **Testing in regular mode after clearing** - Chrome might re-cache old state  

✅ **Use incognito first** - Confirms SSL is working  
✅ **Delete HSTS entry** - Clears the cached security policy  
✅ **Fully restart Chrome** - Ensures clean slate  

---

**Status**: Issue is browser-side HSTS caching, not server configuration  
**Server**: ✅ Configured correctly with valid SSL certificate  
**Resolution**: Clear Chrome HSTS cache using `chrome://net-internals/#hsts`  
**Date**: November 23, 2025
