# Custom Domain Implementation Guide

## Overview

This guide covers how to set up a custom domain for your CodeLearn application using AWS CloudFront, ACM certificates, and various DNS providers. The application will be accessible via a professional HTTPS URL with full OAuth support.

## Prerequisites

- AWS CLI configured
- CloudFront distribution already deployed
- Domain ownership or access to domain DNS management
- Understanding of DNS concepts (A records, CNAME records, nameservers)

## Architecture

```
User Request (https://codelearn.yourdomain.com)
    ↓
DNS Resolution (CNAME → CloudFront)
    ↓
CloudFront Distribution (with ACM certificate)
    ↓
S3 Static Website (via OAI)
    ↓
CodeLearn Application
```

## Implementation Options

### Option 1: Full Route 53 DNS Management

**Best for:** New domains or domains you want to fully manage in AWS

#### Step 1: Create Route 53 Hosted Zone

```bash
# Create hosted zone for your domain
aws route53 create-hosted-zone \
    --name "yourdomain.com" \
    --caller-reference "codelearn-$(date +%s)" \
    --hosted-zone-config "Comment=Hosted zone for yourdomain.com"

# Get the nameservers
aws route53 get-hosted-zone --id YOUR_ZONE_ID \
    --query 'DelegationSet.NameServers[]' --output text
```

#### Step 2: Update Domain Registrar

Update your domain registrar with the AWS nameservers:
- For GoDaddy: Domains → DNS → Nameservers → Custom
- For Namecheap: Domain List → Manage → Nameservers → Custom DNS
- For Google Domains: DNS → Name servers → Use custom name servers

#### Step 3: Request ACM Certificate

```bash
# Request certificate (must be in us-east-1 for CloudFront)
aws acm request-certificate \
    --domain-name "codelearn.yourdomain.com" \
    --validation-method DNS \
    --region us-east-1
```

#### Step 4: Create DNS Validation Records

```bash
# Get validation records
aws acm describe-certificate \
    --certificate-arn YOUR_CERT_ARN \
    --region us-east-1 \
    --query 'Certificate.DomainValidationOptions[0].ResourceRecord'

# Create validation record in Route 53
aws route53 change-resource-record-sets \
    --hosted-zone-id YOUR_ZONE_ID \
    --change-batch file://validation-record.json
```

### Option 2: Third-Party DNS Provider

**Best for:** Existing domains with external DNS (WordPress.com, Cloudflare, etc.)

#### Step 1: Request ACM Certificate

```bash
aws acm request-certificate \
    --domain-name "codelearn.yourdomain.com" \
    --validation-method DNS \
    --region us-east-1
```

#### Step 2: Add DNS Records in External Provider

**For WordPress.com:**
1. Login to WordPress.com
2. My Sites → Domains → yourdomain.com → DNS Records
3. Add CNAME records as provided by ACM

**For Cloudflare:**
1. Login to Cloudflare dashboard
2. Select your domain → DNS
3. Add CNAME records (set to DNS Only, not Proxied)

**For GoDaddy:**
1. Login to GoDaddy account
2. Domains → DNS → Records
3. Add CNAME records

#### Step 3: DNS Records Required

You'll need to add these records in your DNS provider:

```
# Certificate validation (from ACM)
Type: CNAME
Name: _acme-challenge.codelearn (or as provided by ACM)
Value: validation-string-from-acm.acm-validations.aws.

# Domain pointing to CloudFront
Type: CNAME  
Name: codelearn
Value: your-cloudfront-domain.cloudfront.net
```

### Option 3: Subdomain Delegation

**Best for:** When you want AWS to manage only the subdomain

#### Step 1: Create Subdomain Hosted Zone

```bash
# Create hosted zone for subdomain
aws route53 create-hosted-zone \
    --name "codelearn.yourdomain.com" \
    --caller-reference "subdomain-$(date +%s)"
```

#### Step 2: Delegate Subdomain in Parent DNS

Add NS records in your main domain DNS:

```
Type: NS
Name: codelearn
Value: ns-xxx.awsdns-xx.org (all 4 nameservers from subdomain zone)
```

## CloudFront Configuration

### Update Distribution with Custom Domain

```bash
# Get current distribution config
aws cloudfront get-distribution-config \
    --id YOUR_DISTRIBUTION_ID > current-config.json

# Update configuration (add aliases and certificate)
# Edit the JSON to include:
{
  "Aliases": {
    "Quantity": 1,
    "Items": ["codelearn.yourdomain.com"]
  },
  "ViewerCertificate": {
    "ACMCertificateArn": "YOUR_CERT_ARN",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021",
    "CertificateSource": "acm"
  }
}

# Apply the update
aws cloudfront update-distribution \
    --id YOUR_DISTRIBUTION_ID \
    --distribution-config file://updated-config.json \
    --if-match YOUR_ETAG
```

### Alternative: CloudFormation Template

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Update CloudFront distribution with custom domain'

Parameters:
  DistributionId:
    Type: String
    Description: 'Existing CloudFront distribution ID'
  
  CustomDomain:
    Type: String
    Description: 'Custom domain name'
  
  CertificateArn:
    Type: String
    Description: 'ACM certificate ARN in us-east-1'

Resources:
  # Note: CloudFormation cannot directly update existing distributions
  # Use AWS CLI or console for updates
```

## Cognito OAuth Configuration

### Update Redirect URLs

```bash
# Add custom domain to Cognito app client
aws cognito-idp update-user-pool-client \
    --user-pool-id YOUR_USER_POOL_ID \
    --client-id YOUR_APP_CLIENT_ID \
    --callback-urls \
        "https://codelearn.yourdomain.com" \
        "https://codelearn.yourdomain.com/auth/callback" \
        "https://your-cloudfront-domain.cloudfront.net" \
        "http://localhost:3000/auth/callback" \
    --logout-urls \
        "https://codelearn.yourdomain.com" \
        "https://your-cloudfront-domain.cloudfront.net" \
        "http://localhost:3000" \
    --allowed-o-auth-flows "code" \
    --allowed-o-auth-scopes "openid" "email" "profile" \
    --allowed-o-auth-flows-user-pool-client
```

### Test OAuth URLs

```bash
# Primary custom domain OAuth URL
https://your-cognito-domain.auth.region.amazoncognito.com/login?client_id=YOUR_CLIENT_ID&response_type=code&scope=openid+email+profile&redirect_uri=https://codelearn.yourdomain.com

# Fallback CloudFront OAuth URL  
https://your-cognito-domain.auth.region.amazoncognito.com/login?client_id=YOUR_CLIENT_ID&response_type=code&scope=openid+email+profile&redirect_uri=https://your-cloudfront-domain.cloudfront.net
```

## Validation and Testing

### DNS Validation

```bash
# Check DNS resolution
dig codelearn.yourdomain.com

# Check global DNS propagation
dig @8.8.8.8 codelearn.yourdomain.com
dig @1.1.1.1 codelearn.yourdomain.com

# Check CNAME specifically
dig CNAME codelearn.yourdomain.com
```

### Certificate Validation

```bash
# Check certificate status
aws acm describe-certificate \
    --certificate-arn YOUR_CERT_ARN \
    --region us-east-1 \
    --query 'Certificate.Status'

# Wait for validation
aws acm wait certificate-validated \
    --certificate-arn YOUR_CERT_ARN \
    --region us-east-1
```

### HTTPS Testing

```bash
# Test HTTPS connectivity
curl -I https://codelearn.yourdomain.com

# Test with verbose output
curl -v https://codelearn.yourdomain.com

# Check SSL certificate
openssl s_client -connect codelearn.yourdomain.com:443 -servername codelearn.yourdomain.com
```

### CloudFront Testing

```bash
# Check CloudFront distribution status
aws cloudfront get-distribution \
    --id YOUR_DISTRIBUTION_ID \
    --query 'Distribution.Status'

# List distribution domains
aws cloudfront get-distribution \
    --id YOUR_DISTRIBUTION_ID \
    --query 'Distribution.DistributionConfig.Aliases.Items[]'
```

## Troubleshooting

### Common Issues

#### 1. Certificate Validation Stuck

**Problem:** Certificate remains in PENDING_VALIDATION
**Solutions:**
- Verify DNS validation records are correctly added
- Check DNS propagation with multiple resolvers
- Wait 24-48 hours for global DNS propagation
- Ensure CNAME record is exact match (trailing dots matter)

#### 2. CloudFront 403 Errors

**Problem:** Custom domain returns 403 Forbidden
**Causes:**
- CloudFront distribution not updated with custom domain
- Certificate not associated with distribution
- S3 bucket policy doesn't allow CloudFront OAI access
- Custom domain not yet propagated in CloudFront edge locations

**Solutions:**
```bash
# Verify distribution configuration
aws cloudfront get-distribution --id YOUR_ID

# Create invalidation to refresh cache
aws cloudfront create-invalidation \
    --distribution-id YOUR_ID \
    --paths "/*"

# Check S3 bucket policy
aws s3api get-bucket-policy --bucket YOUR_BUCKET
```

#### 3. OAuth Redirect Errors

**Problem:** Authentication fails with redirect URI mismatch
**Solutions:**
- Verify exact URL match in Cognito configuration
- Check for trailing slashes, HTTP vs HTTPS
- Test with both custom domain and CloudFront domain
- Clear browser cache and cookies

#### 4. DNS Resolution Issues

**Problem:** Domain doesn't resolve or points to wrong location
**Solutions:**
```bash
# Check authoritative nameservers
dig NS yourdomain.com

# Check from authoritative server
dig @nameserver.com codelearn.yourdomain.com

# Flush local DNS cache (macOS)
sudo dscacheutil -flushcache
```

### Monitoring and Alerts

#### CloudWatch Alarms

```bash
# Create alarm for CloudFront errors
aws cloudwatch put-metric-alarm \
    --alarm-name "CloudFront-4xx-Errors" \
    --alarm-description "Monitor CloudFront 4xx errors" \
    --metric-name "4xxErrorRate" \
    --namespace "AWS/CloudFront" \
    --statistic Average \
    --period 300 \
    --threshold 5 \
    --comparison-operator GreaterThanThreshold
```

#### Route 53 Health Checks

```bash
# Create health check for custom domain
aws route53 create-health-check \
    --caller-reference "codelearn-$(date +%s)" \
    --health-check-config \
        Type=HTTPS,ResourcePath=/,FullyQualifiedDomainName=codelearn.yourdomain.com
```

## Security Considerations

### SSL/TLS Configuration

- **Minimum TLS Version:** TLS 1.2 (recommended for CloudFront)
- **SSL Support Method:** SNI-only (cost-effective)
- **Certificate Scope:** Single domain or wildcard if planning multiple subdomains

### DNS Security

- **Enable DNSSEC** if supported by your DNS provider
- **Use strong passwords** for DNS provider accounts
- **Enable 2FA** on domain registrar and DNS provider accounts
- **Monitor DNS changes** with alerting

### CloudFront Security Headers

```javascript
// CloudFront Function for security headers
function handler(event) {
    var response = event.response;
    var headers = response.headers;
    
    headers['strict-transport-security'] = {value: 'max-age=31536000; includeSubdomains'};
    headers['content-security-policy'] = {value: "default-src 'self' https:"};
    headers['x-content-type-options'] = {value: 'nosniff'};
    headers['x-frame-options'] = {value: 'DENY'};
    headers['x-xss-protection'] = {value: '1; mode=block'};
    
    return response;
}
```

## Cost Optimization

### CloudFront Pricing

- **First 1 TB/month:** FREE for 12 months (new AWS accounts)
- **Data transfer:** $0.085 - $0.25 per GB (varies by region)
- **Requests:** $0.0075 per 10,000 requests (HTTPS)
- **Custom SSL certificate:** FREE with ACM

### Route 53 Pricing

- **Hosted zone:** $0.50 per month
- **DNS queries:** $0.40 per million queries
- **Health checks:** $0.50 per health check per month

### Total Estimated Monthly Cost

For typical usage (< 1 TB transfer, < 1M requests):
- **Route 53:** ~$1/month
- **CloudFront:** FREE (within free tier)
- **ACM Certificate:** FREE
- **Total:** ~$1/month

## Maintenance

### Certificate Renewal

ACM certificates auto-renew when:
- Domain validation records remain in DNS
- Certificate is actively used by AWS services
- No action required for auto-renewal

### Monitoring Checklist

- [ ] Certificate expiration dates
- [ ] DNS record integrity
- [ ] CloudFront distribution health
- [ ] OAuth redirect URL functionality
- [ ] SSL/TLS configuration
- [ ] Performance metrics

### Backup and Recovery

```bash
# Export Route 53 zone for backup
aws route53 list-resource-record-sets \
    --hosted-zone-id YOUR_ZONE_ID > zone-backup.json

# Export CloudFront configuration
aws cloudfront get-distribution-config \
    --id YOUR_DISTRIBUTION_ID > distribution-backup.json

# Export Cognito configuration
aws cognito-idp describe-user-pool-client \
    --user-pool-id YOUR_POOL_ID \
    --client-id YOUR_CLIENT_ID > cognito-backup.json
```

## Conclusion

Custom domain implementation provides:
- **Professional branding** with your own domain
- **Full HTTPS support** with automatic certificate management
- **OAuth compatibility** with all identity providers
- **SEO benefits** from consistent domain usage
- **User trust** through branded, secure URLs

The implementation requires careful DNS management and AWS service coordination, but provides significant value for production applications.

## Scripts and Automation

All implementation steps can be automated using the provided scripts:

- `setup-custom-domain.sh` - Full Route 53 setup
- `setup-subdomain-only.sh` - Third-party DNS setup  
- `complete-custom-domain.sh` - CloudFront configuration
- `update-cognito-custom-domain.sh` - OAuth URL updates
- `check-custom-domain-status.sh` - Monitoring and validation

These scripts handle error conditions, provide progress feedback, and ensure idempotent operations for reliable deployment.