#!/bin/bash

source config/dev-config.sh

echo "🌐 Completing Custom Domain Setup"
echo "================================="
echo ""

if [[ -z "$CUSTOM_DOMAIN" || -z "$ACM_CERTIFICATE_ARN" ]]; then
    echo "❌ Custom domain configuration not found"
    echo "Please run ./tools/setup-custom-domain.sh first"
    exit 1
fi

echo "Domain: $CUSTOM_DOMAIN"
echo "Certificate: $ACM_CERTIFICATE_ARN"
echo "CloudFront: $CLOUDFRONT_DISTRIBUTION_ID"
echo ""

# Check certificate status
echo "🔍 Checking certificate validation status..."
CERT_STATUS=$(aws acm describe-certificate \
    --certificate-arn "$ACM_CERTIFICATE_ARN" \
    --region us-east-1 \
    --query 'Certificate.Status' \
    --output text)

echo "Certificate Status: $CERT_STATUS"

if [[ "$CERT_STATUS" != "ISSUED" ]]; then
    echo "⚠️  Certificate not yet validated"
    echo ""
    echo "Please ensure:"
    echo "1. You've updated nameservers at your domain registrar:"
    echo "   $NAMESERVERS" | tr ' ' '\n' | sed 's/^/   /'
    echo ""
    echo "2. DNS propagation is complete (can take up to 24 hours)"
    echo ""
    echo "3. Certificate validation is complete (usually 5-10 minutes after DNS)"
    echo ""
    echo "Check certificate status:"
    echo "aws acm describe-certificate --certificate-arn $ACM_CERTIFICATE_ARN --region us-east-1"
    exit 1
fi

echo "✅ Certificate is validated!"
echo ""

# Update CloudFront distribution
echo "🌐 Updating CloudFront distribution..."

# Get current distribution config
aws cloudfront get-distribution-config \
    --id "$CLOUDFRONT_DISTRIBUTION_ID" > /tmp/current-distribution.json

# Extract ETag
ETAG=$(python3 -c "
import json
with open('/tmp/current-distribution.json', 'r') as f:
    data = json.load(f)
print(data['ETag'])
")

echo "Current ETag: $ETAG"

# Update distribution config
python3 << EOF
import json

# Read current distribution
with open('/tmp/current-distribution.json', 'r') as f:
    data = json.load(f)

config = data['DistributionConfig']

# Add custom domain and certificate
config['Aliases'] = {
    'Quantity': 1,
    'Items': ['$CUSTOM_DOMAIN']
}

config['ViewerCertificate'] = {
    'ACMCertificateArn': '$ACM_CERTIFICATE_ARN',
    'SSLSupportMethod': 'sni-only',
    'MinimumProtocolVersion': 'TLSv1.2_2021',
    'CertificateSource': 'acm'
}

# Remove CloudFrontDefaultCertificate if it exists
if 'CloudFrontDefaultCertificate' in config['ViewerCertificate']:
    del config['ViewerCertificate']['CloudFrontDefaultCertificate']

# Save updated config
with open('/tmp/updated-distribution.json', 'w') as f:
    json.dump(config, f, indent=2)
EOF

# Update the distribution
UPDATE_RESULT=$(aws cloudfront update-distribution \
    --id "$CLOUDFRONT_DISTRIBUTION_ID" \
    --distribution-config file:///tmp/updated-distribution.json \
    --if-match "$ETAG" 2>&1)

if [[ $? -eq 0 ]]; then
    echo "✅ CloudFront distribution updated"
    echo "⏳ CloudFront is deploying changes (5-15 minutes)..."
else
    echo "❌ Failed to update CloudFront distribution"
    echo "$UPDATE_RESULT"
    echo ""
    echo "This might be due to a concurrent update. Trying again in 30 seconds..."
    sleep 30
    
    # Try again with fresh ETag
    aws cloudfront get-distribution-config \
        --id "$CLOUDFRONT_DISTRIBUTION_ID" > /tmp/current-distribution-2.json
    
    ETAG=$(python3 -c "
import json
with open('/tmp/current-distribution-2.json', 'r') as f:
    data = json.load(f)
print(data['ETag'])
")
    
    aws cloudfront update-distribution \
        --id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --distribution-config file:///tmp/updated-distribution.json \
        --if-match "$ETAG"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ CloudFront distribution updated (retry successful)"
    else
        echo "❌ Failed to update CloudFront distribution on retry"
        echo "Please update manually in AWS Console"
    fi
fi

echo ""
echo "🔗 Creating DNS CNAME record..."

# Create CNAME record pointing to CloudFront
cat > /tmp/cname-record.json << EOF
{
    "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "$CUSTOM_DOMAIN",
            "Type": "CNAME",
            "TTL": 300,
            "ResourceRecords": [{
                "Value": "$CLOUDFRONT_DOMAIN"
            }]
        }
    }]
}
EOF

aws route53 change-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --change-batch file:///tmp/cname-record.json

if [[ $? -eq 0 ]]; then
    echo "✅ CNAME record created: $CUSTOM_DOMAIN → $CLOUDFRONT_DOMAIN"
else
    echo "❌ Failed to create CNAME record"
fi

echo ""
echo "⚙️  Updating configuration..."

# Update config file
sed -i '' '/^export FRONTEND_CUSTOM_URL=/d' config/dev-config.sh 2>/dev/null || true
echo "export FRONTEND_CUSTOM_URL=\"https://$CUSTOM_DOMAIN\"" >> config/dev-config.sh

echo ""
echo "🎉 Custom Domain Setup Complete!"
echo "================================"
echo ""
echo "📋 Summary:"
echo "   Custom Domain: $CUSTOM_DOMAIN"
echo "   Certificate: $ACM_CERTIFICATE_ARN"
echo "   CloudFront: $CLOUDFRONT_DISTRIBUTION_ID"
echo "   Hosted Zone: $HOSTED_ZONE_ID"
echo ""
echo "🌐 URLs:"
echo "   Custom Domain: https://$CUSTOM_DOMAIN"
echo "   CloudFront: $FRONTEND_HTTPS_URL"
echo ""
echo "🔄 Next Steps:"
echo "1. Wait for CloudFront deployment: aws cloudfront get-distribution --id $CLOUDFRONT_DISTRIBUTION_ID --query 'Distribution.Status'"
echo "2. Update Cognito: ./tools/update-cognito-custom-domain.sh"
echo "3. Test custom domain: curl -I https://$CUSTOM_DOMAIN"
echo ""
echo "⚠️  Note: DNS propagation can take up to 24 hours globally"

# Clean up temp files
rm -f /tmp/current-distribution.json /tmp/updated-distribution.json /tmp/cname-record.json /tmp/current-distribution-2.json