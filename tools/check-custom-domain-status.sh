#!/bin/bash

source config/dev-config.sh

echo "🔍 Custom Domain Setup Status"
echo "============================"
echo ""

if [[ -z "$CUSTOM_DOMAIN" ]]; then
    echo "❌ Custom domain not configured"
    echo "Run: ./tools/setup-custom-domain.sh"
    exit 1
fi

echo "📋 Configuration:"
echo "  Domain: $CUSTOM_DOMAIN"
echo "  Certificate ARN: $ACM_CERTIFICATE_ARN"
echo "  CloudFront Distribution: $CLOUDFRONT_DISTRIBUTION_ID"
echo "  Hosted Zone: $HOSTED_ZONE_ID"
echo ""

# Check Certificate Status
echo "🔐 Certificate Status:"
CERT_STATUS=$(aws acm describe-certificate \
    --certificate-arn "$ACM_CERTIFICATE_ARN" \
    --region us-east-1 \
    --query 'Certificate.Status' \
    --output text 2>/dev/null)

if [[ $? -eq 0 ]]; then
    echo "  Status: $CERT_STATUS"
    if [[ "$CERT_STATUS" == "ISSUED" ]]; then
        echo "  ✅ Certificate is validated and ready"
    elif [[ "$CERT_STATUS" == "PENDING_VALIDATION" ]]; then
        echo "  ⏳ Certificate validation in progress"
        echo "     This can take 5-10 minutes after DNS propagation"
    else
        echo "  ⚠️  Certificate status: $CERT_STATUS"
    fi
else
    echo "  ❌ Could not check certificate status"
fi

echo ""

# Check CloudFront Distribution Status
echo "🌐 CloudFront Distribution:"
CF_STATUS=$(aws cloudfront get-distribution \
    --id "$CLOUDFRONT_DISTRIBUTION_ID" \
    --query 'Distribution.Status' \
    --output text 2>/dev/null)

if [[ $? -eq 0 ]]; then
    echo "  Status: $CF_STATUS"
    if [[ "$CF_STATUS" == "Deployed" ]]; then
        echo "  ✅ CloudFront distribution is deployed"
    elif [[ "$CF_STATUS" == "InProgress" ]]; then
        echo "  ⏳ CloudFront deployment in progress"
        echo "     This can take 5-15 minutes"
    else
        echo "  ⚠️  CloudFront status: $CF_STATUS"
    fi
    
    # Check if custom domain is configured
    ALIASES=$(aws cloudfront get-distribution \
        --id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --query 'Distribution.DistributionConfig.Aliases.Items' \
        --output text 2>/dev/null)
    
    if [[ "$ALIASES" == *"$CUSTOM_DOMAIN"* ]]; then
        echo "  ✅ Custom domain configured in CloudFront"
    else
        echo "  ❌ Custom domain NOT configured in CloudFront"
        echo "     Run: ./tools/complete-custom-domain.sh"
    fi
else
    echo "  ❌ Could not check CloudFront status"
fi

echo ""

# Check DNS Resolution
echo "🔗 DNS Resolution:"
DNS_RESULT=$(dig +short "$CUSTOM_DOMAIN" 2>/dev/null)

if [[ -n "$DNS_RESULT" ]]; then
    echo "  ✅ DNS resolves to: $DNS_RESULT"
else
    echo "  ⏳ DNS not yet propagated or CNAME not created"
    echo "     This can take up to 24 hours"
fi

echo ""

# Test HTTPS Access
echo "🌐 HTTPS Test:"
if command -v curl >/dev/null 2>&1; then
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$CUSTOM_DOMAIN" --connect-timeout 10 2>/dev/null)
    
    if [[ "$HTTP_STATUS" == "200" ]]; then
        echo "  ✅ HTTPS site accessible (HTTP $HTTP_STATUS)"
    elif [[ "$HTTP_STATUS" == "000" ]]; then
        echo "  ⏳ Site not yet accessible (DNS/certificate pending)"
    elif [[ "$HTTP_STATUS" == "403" ]]; then
        echo "  ⚠️  Site returns 403 (CloudFront may still be deploying)"
    else
        echo "  ⚠️  Site returns HTTP $HTTP_STATUS"
    fi
else
    echo "  ⚠️  curl not available for testing"
fi

echo ""

# Summary and Next Steps
echo "📋 Next Steps:"
echo ""

if [[ "$CERT_STATUS" == "PENDING_VALIDATION" ]]; then
    echo "1. ⏳ Wait for certificate validation"
    echo "   - Ensure nameservers are updated at domain registrar:"
    echo "     $NAMESERVERS" | tr ' ' '\n' | sed 's/^/     /'
    echo "   - DNS propagation can take up to 24 hours"
    echo "   - Certificate validation usually takes 5-10 minutes after DNS"
    echo ""
elif [[ "$CERT_STATUS" == "ISSUED" ]] && [[ "$ALIASES" != *"$CUSTOM_DOMAIN"* ]]; then
    echo "1. ✅ Certificate is ready"
    echo "2. 🔧 Configure CloudFront with custom domain:"
    echo "   ./tools/complete-custom-domain.sh"
    echo ""
elif [[ "$CERT_STATUS" == "ISSUED" ]] && [[ "$CF_STATUS" == "InProgress" ]]; then
    echo "1. ✅ Certificate is ready"
    echo "2. ⏳ Wait for CloudFront deployment (5-15 minutes)"
    echo ""
elif [[ "$CERT_STATUS" == "ISSUED" ]] && [[ "$CF_STATUS" == "Deployed" ]]; then
    echo "1. ✅ Certificate and CloudFront are ready"
    if [[ "$HTTP_STATUS" == "200" ]]; then
        echo "2. ✅ Custom domain is working!"
        echo "3. 🔧 Update Cognito OAuth:"
        echo "   ./tools/update-cognito-custom-domain.sh"
    else
        echo "2. ⏳ Wait for DNS propagation"
        echo "3. 🔧 Then update Cognito OAuth:"
        echo "   ./tools/update-cognito-custom-domain.sh"
    fi
    echo ""
fi

echo "🔄 Check status again:"
echo "   ./tools/check-custom-domain-status.sh"