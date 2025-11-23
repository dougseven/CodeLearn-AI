#!/bin/bash

source config/dev-config.sh

echo "🌐 Creating CloudFront Distribution (Simple)"
echo "============================================"
echo ""

# Step 1: Create Origin Access Identity
echo "1. Creating CloudFront Origin Access Identity..."

OAI_RESPONSE=$(aws cloudfront create-cloud-front-origin-access-identity \
    --cloud-front-origin-access-identity-config \
    "CallerReference=$(date +%s),Comment=CodeLearn OAI for ${FRONTEND_BUCKET}")

if [[ $? -eq 0 ]]; then
    OAI_ID=$(echo "$OAI_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['CloudFrontOriginAccessIdentity']['Id'])")
    OAI_CANONICAL_USER=$(echo "$OAI_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['CloudFrontOriginAccessIdentity']['S3CanonicalUserId'])")
    echo "✅ OAI created: $OAI_ID"
else
    echo "❌ Failed to create OAI"
    exit 1
fi

# Step 2: Update S3 bucket policy to allow CloudFront access
echo ""
echo "2. Updating S3 bucket policy..."

BUCKET_POLICY=$(cat << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${OAI_ID}"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${FRONTEND_BUCKET}/*"
        }
    ]
}
EOF
)

echo "$BUCKET_POLICY" | aws s3api put-bucket-policy --bucket "$FRONTEND_BUCKET" --policy file:///dev/stdin

if [[ $? -eq 0 ]]; then
    echo "✅ S3 bucket policy updated"
else
    echo "❌ Failed to update S3 bucket policy"
    exit 1
fi

# Step 3: Create CloudFront distribution
echo ""
echo "3. Creating CloudFront distribution..."
echo "   This may take 15-20 minutes to deploy globally..."

DISTRIBUTION_CONFIG=$(cat << EOF
{
    "CallerReference": "codelearn-$(date +%s)",
    "Comment": "CodeLearn Frontend Distribution",
    "DefaultRootObject": "index.html",
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-${FRONTEND_BUCKET}",
                "DomainName": "${FRONTEND_BUCKET}.s3.${AWS_REGION}.amazonaws.com",
                "S3OriginConfig": {
                    "OriginAccessIdentity": "origin-access-identity/cloudfront/${OAI_ID}"
                }
            }
        ]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-${FRONTEND_BUCKET}",
        "ViewerProtocolPolicy": "redirect-to-https",
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        },
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            }
        },
        "MinTTL": 0,
        "Compress": true
    },
    "CustomErrorResponses": {
        "Quantity": 2,
        "Items": [
            {
                "ErrorCode": 403,
                "ResponsePagePath": "/index.html",
                "ResponseCode": "200",
                "ErrorCachingMinTTL": 300
            },
            {
                "ErrorCode": 404,
                "ResponsePagePath": "/index.html",
                "ResponseCode": "200",
                "ErrorCachingMinTTL": 300
            }
        ]
    },
    "Enabled": true,
    "PriceClass": "PriceClass_100",
    "ViewerCertificate": {
        "CloudFrontDefaultCertificate": true
    }
}
EOF
)

DISTRIBUTION_RESPONSE=$(echo "$DISTRIBUTION_CONFIG" | aws cloudfront create-distribution \
    --distribution-config file:///dev/stdin)

if [[ $? -eq 0 ]]; then
    DISTRIBUTION_ID=$(echo "$DISTRIBUTION_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['Distribution']['Id'])")
    CLOUDFRONT_DOMAIN=$(echo "$DISTRIBUTION_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['Distribution']['DomainName'])")
    CLOUDFRONT_URL="https://$CLOUDFRONT_DOMAIN"
    
    echo ""
    echo "✅ CloudFront distribution created successfully!"
    echo ""
    echo "📋 Distribution Information:"
    echo "  Distribution ID: $DISTRIBUTION_ID"
    echo "  CloudFront Domain: $CLOUDFRONT_DOMAIN"
    echo "  HTTPS URL: $CLOUDFRONT_URL"
    echo ""
    
    # Save to config
    echo "" >> config/dev-config.sh
    echo "# CloudFront Configuration" >> config/dev-config.sh
    echo "export CLOUDFRONT_DISTRIBUTION_ID=\"$DISTRIBUTION_ID\"" >> config/dev-config.sh
    echo "export CLOUDFRONT_DOMAIN=\"$CLOUDFRONT_DOMAIN\"" >> config/dev-config.sh
    echo "export FRONTEND_HTTPS_URL=\"$CLOUDFRONT_URL\"" >> config/dev-config.sh
    
    echo "💾 Configuration saved to config/dev-config.sh"
    echo ""
    echo "⏳ Note: CloudFront distribution is deploying globally (10-15 minutes)"
    echo "📁 Frontend files will be served from: $CLOUDFRONT_URL"
    echo ""
    echo "🔄 Next steps:"
    echo "1. Wait for CloudFront to deploy (check status in AWS console)"
    echo "2. Run: ./tools/update-cognito-https.sh"
    echo "3. Test the HTTPS frontend"
    
else
    echo "❌ Failed to create CloudFront distribution"
    exit 1
fi