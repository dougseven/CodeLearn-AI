#!/bin/bash

source config/dev-config.sh

echo "🌐 Setting up Subdomain with WordPress DNS"
echo "=========================================="
echo ""

SUBDOMAIN="codelearn.dougseven.com"

echo "Since dougseven.com uses WordPress nameservers, we'll:"
echo "1. Keep the existing WordPress DNS setup"
echo "2. Add a CNAME record for the subdomain only"
echo "3. Use a different certificate approach"
echo ""

echo "📋 What you need to do in WordPress.com:"
echo ""
echo "1. Log into WordPress.com"
echo "2. Go to your site dashboard for dougseven.com"
echo "3. Navigate to: Domains → DNS Records"
echo "4. Add a new CNAME record:"
echo "   Name: codelearn"
echo "   Value: ${CLOUDFRONT_DOMAIN}"
echo "   TTL: 300 (or Auto)"
echo ""
echo "This will point codelearn.dougseven.com to your CloudFront distribution."
echo ""

read -p "Have you added the CNAME record in WordPress? (y/n): " WORDPRESS_DONE

if [[ "$WORDPRESS_DONE" != "y" ]]; then
    echo ""
    echo "Please add the CNAME record first, then run this script again."
    exit 1
fi

echo ""
echo "🔐 Requesting Certificate for Subdomain..."

# Delete the existing hosted zone since we won't use it
echo "Cleaning up Route 53 hosted zone (not needed with WordPress DNS)..."
aws route53 delete-hosted-zone --id "$HOSTED_ZONE_ID" 2>/dev/null || true

# Request new certificate for subdomain only
CERT_ARN=$(aws acm request-certificate \
    --domain-name "$SUBDOMAIN" \
    --validation-method DNS \
    --region us-east-1 \
    --query 'CertificateArn' \
    --output text)

echo "✅ Certificate requested: $CERT_ARN"
echo ""

# Get validation records
sleep 10
VALIDATION_RECORDS=$(aws acm describe-certificate \
    --certificate-arn "$CERT_ARN" \
    --region us-east-1 \
    --query 'Certificate.DomainValidationOptions[0].ResourceRecord' \
    --output json)

if [[ "$VALIDATION_RECORDS" != "null" ]]; then
    VALIDATION_NAME=$(echo "$VALIDATION_RECORDS" | python3 -c "import sys, json; print(json.load(sys.stdin)['Name'])")
    VALIDATION_VALUE=$(echo "$VALIDATION_RECORDS" | python3 -c "import sys, json; print(json.load(sys.stdin)['Value'])")
    
    echo "📋 Certificate Validation Required:"
    echo "Add this CNAME record in WordPress.com DNS:"
    echo ""
    echo "   Record Type: CNAME"
    echo "   Name: $(echo $VALIDATION_NAME | sed 's/.dougseven.com.*//')"
    echo "   Value: $VALIDATION_VALUE"
    echo "   TTL: 300"
    echo ""
    echo "⚠️  Note: Remove the '.dougseven.com' part from the name when adding to WordPress"
    echo ""
    
    read -p "Have you added the validation CNAME record? (y/n): " VALIDATION_DONE
    
    if [[ "$VALIDATION_DONE" == "y" ]]; then
        echo "⏳ Waiting for certificate validation..."
        aws acm wait certificate-validated \
            --certificate-arn "$CERT_ARN" \
            --region us-east-1 \
            --cli-read-timeout 300 \
            --cli-connect-timeout 60 || echo "⚠️  Validation taking longer than expected"
    fi
fi

# Update config
cat > /tmp/new-config.txt << EOF

# Custom Domain Configuration (WordPress DNS)
export CUSTOM_DOMAIN="$SUBDOMAIN"
export ACM_CERTIFICATE_ARN="$CERT_ARN"
export FRONTEND_CUSTOM_URL="https://$SUBDOMAIN"
EOF

cat /tmp/new-config.txt >> config/dev-config.sh

echo ""
echo "🎉 Subdomain Setup Complete!"
echo "============================"
echo ""
echo "Your subdomain: $SUBDOMAIN"
echo "Certificate: $CERT_ARN"
echo ""
echo "🔄 Next Steps:"
echo "1. Wait for certificate validation"
echo "2. Run: ./tools/complete-custom-domain.sh"
echo "3. Test: https://$SUBDOMAIN"

rm -f /tmp/new-config.txt