#!/bin/bash

source config/dev-config.sh

DOMAIN_NAME="codelearn.dougseven.com"
ROOT_DOMAIN="dougseven.com"

echo "🌐 Setting up Custom Domain: $DOMAIN_NAME"
echo "=========================================="
echo ""

# Check if root domain exists in Route 53
echo "🔍 Checking for existing hosted zones..."
EXISTING_ZONE=$(aws route53 list-hosted-zones --query "HostedZones[?Name=='${ROOT_DOMAIN}.'].Id" --output text)

if [[ -n "$EXISTING_ZONE" && "$EXISTING_ZONE" != "None" ]]; then
    echo "✅ Found existing hosted zone for $ROOT_DOMAIN"
    HOSTED_ZONE_ID=$(echo "$EXISTING_ZONE" | cut -d'/' -f3)
    echo "   Zone ID: $HOSTED_ZONE_ID"
else
    echo "❌ No hosted zone found for $ROOT_DOMAIN"
    echo ""
    echo "Options:"
    echo "1) Create new hosted zone for $ROOT_DOMAIN (if you own the domain)"
    echo "2) Register new domain $ROOT_DOMAIN through Route 53"
    echo "3) Use a different domain you already own"
    echo "4) Continue with CloudFront default domain"
    echo ""
    read -p "Choose option (1-4): " DOMAIN_CHOICE
    
    case $DOMAIN_CHOICE in
        1)
            echo "Creating hosted zone for $ROOT_DOMAIN..."
            ZONE_RESPONSE=$(aws route53 create-hosted-zone \
                --name "$ROOT_DOMAIN" \
                --caller-reference "codelearn-$(date +%s)" \
                --hosted-zone-config "Comment=Hosted zone for $ROOT_DOMAIN")
            
            if [[ $? -eq 0 ]]; then
                HOSTED_ZONE_ID=$(echo "$ZONE_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['HostedZone']['Id'].split('/')[-1])")
                echo "✅ Created hosted zone: $HOSTED_ZONE_ID"
                
                # Show nameservers
                NAMESERVERS=$(aws route53 get-hosted-zone --id "$HOSTED_ZONE_ID" --query 'DelegationSet.NameServers[]' --output text)
                echo ""
                echo "⚠️  IMPORTANT: Update your domain registrar with these nameservers:"
                echo "$NAMESERVERS" | tr '\t' '\n' | sed 's/^/   /'
                echo ""
                read -p "Press Enter after you've updated the nameservers at your domain registrar..."
            else
                echo "❌ Failed to create hosted zone"
                exit 1
            fi
            ;;
        2)
            echo "To register $ROOT_DOMAIN through Route 53:"
            echo "1. Go to: https://console.aws.amazon.com/route53/domains/home"
            echo "2. Search for and register $ROOT_DOMAIN"
            echo "3. Route 53 will automatically create the hosted zone"
            echo "4. Run this script again after registration completes"
            exit 0
            ;;
        3)
            read -p "Enter the domain you own (e.g., yourdomain.com): " USER_DOMAIN
            read -p "Enter subdomain (e.g., codelearn): " SUBDOMAIN
            DOMAIN_NAME="${SUBDOMAIN}.${USER_DOMAIN}"
            ROOT_DOMAIN="$USER_DOMAIN"
            echo "Will use: $DOMAIN_NAME"
            
            # Check for this domain's hosted zone
            HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name=='${ROOT_DOMAIN}.'].Id" --output text | cut -d'/' -f3)
            if [[ -z "$HOSTED_ZONE_ID" || "$HOSTED_ZONE_ID" == "None" ]]; then
                echo "❌ No hosted zone found for $ROOT_DOMAIN"
                echo "Please create a hosted zone first or choose option 1"
                exit 1
            fi
            ;;
        4)
            echo "Continuing with CloudFront default domain..."
            echo "Your current HTTPS URL: $FRONTEND_HTTPS_URL"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice"
            exit 1
            ;;
    esac
fi

echo ""
echo "🔐 Step 1: Request ACM Certificate"
echo "----------------------------------"

# Request ACM certificate (must be in us-east-1 for CloudFront)
echo "Requesting SSL certificate for $DOMAIN_NAME..."
CERT_ARN=$(aws acm request-certificate \
    --domain-name "$DOMAIN_NAME" \
    --validation-method DNS \
    --region us-east-1 \
    --query 'CertificateArn' \
    --output text)

if [[ $? -eq 0 ]]; then
    echo "✅ Certificate requested: $CERT_ARN"
    
    # Wait for certificate to be issued and get validation records
    echo "⏳ Waiting for validation records..."
    sleep 10
    
    # Get DNS validation records
    VALIDATION_RECORDS=$(aws acm describe-certificate \
        --certificate-arn "$CERT_ARN" \
        --region us-east-1 \
        --query 'Certificate.DomainValidationOptions[0].ResourceRecord' \
        --output json)
    
    if [[ "$VALIDATION_RECORDS" != "null" ]]; then
        VALIDATION_NAME=$(echo "$VALIDATION_RECORDS" | python3 -c "import sys, json; print(json.load(sys.stdin)['Name'])")
        VALIDATION_VALUE=$(echo "$VALIDATION_RECORDS" | python3 -c "import sys, json; print(json.load(sys.stdin)['Value'])")
        
        echo ""
        echo "📋 DNS Validation Required:"
        echo "   Record Type: CNAME"
        echo "   Name: $VALIDATION_NAME"
        echo "   Value: $VALIDATION_VALUE"
        echo ""
        
        # Create DNS validation record
        echo "Creating DNS validation record..."
        cat > /tmp/dns-validation.json << EOF
{
    "Changes": [{
        "Action": "CREATE",
        "ResourceRecordSet": {
            "Name": "$VALIDATION_NAME",
            "Type": "CNAME",
            "TTL": 300,
            "ResourceRecords": [{
                "Value": "$VALIDATION_VALUE"
            }]
        }
    }]
}
EOF
        
        aws route53 change-resource-record-sets \
            --hosted-zone-id "$HOSTED_ZONE_ID" \
            --change-batch file:///tmp/dns-validation.json
        
        if [[ $? -eq 0 ]]; then
            echo "✅ DNS validation record created"
            echo "⏳ Waiting for certificate validation (this can take 5-10 minutes)..."
            
            # Wait for certificate to be validated
            aws acm wait certificate-validated \
                --certificate-arn "$CERT_ARN" \
                --region us-east-1
            
            if [[ $? -eq 0 ]]; then
                echo "✅ Certificate validated successfully!"
            else
                echo "⚠️  Certificate validation is taking longer than expected"
                echo "   You can continue and check status later in ACM console"
            fi
        else
            echo "❌ Failed to create DNS validation record"
            echo "   Please add the CNAME record manually in Route 53"
        fi
    else
        echo "⚠️  Validation records not yet available"
        echo "   Check ACM console for validation requirements"
    fi
else
    echo "❌ Failed to request certificate"
    exit 1
fi

echo ""
echo "🌐 Step 2: Update CloudFront Distribution"
echo "-----------------------------------------"

# Update CloudFront distribution with custom domain and certificate
echo "Updating CloudFront distribution..."

# Get current distribution config
aws cloudfront get-distribution-config \
    --id "$CLOUDFRONT_DISTRIBUTION_ID" > /tmp/current-distribution.json

# Extract current config and ETag
ETAG=$(python3 -c "
import json
with open('/tmp/current-distribution.json', 'r') as f:
    data = json.load(f)
print(data['ETag'])
")

# Update distribution config
python3 << 'EOF'
import json

# Read current distribution
with open('/tmp/current-distribution.json', 'r') as f:
    data = json.load(f)

config = data['DistributionConfig']

# Add custom domain and certificate
config['Aliases'] = {
    'Quantity': 1,
    'Items': ['{domain_name}']
}

config['ViewerCertificate'] = {
    'ACMCertificateArn': '{cert_arn}',
    'SSLSupportMethod': 'sni-only',
    'MinimumProtocolVersion': 'TLSv1.2_2021',
    'CertificateSource': 'acm'
}

# Save updated config
with open('/tmp/updated-distribution.json', 'w') as f:
    json.dump(config, f, indent=2)
EOF

# Replace placeholders
sed -i '' "s/{domain_name}/$DOMAIN_NAME/g" /tmp/updated-distribution.json
sed -i '' "s|{cert_arn}|$CERT_ARN|g" /tmp/updated-distribution.json

# Update the distribution
aws cloudfront update-distribution \
    --id "$CLOUDFRONT_DISTRIBUTION_ID" \
    --distribution-config file:///tmp/updated-distribution.json \
    --if-match "$ETAG"

if [[ $? -eq 0 ]]; then
    echo "✅ CloudFront distribution updated"
    echo "⏳ CloudFront is deploying changes (5-10 minutes)..."
else
    echo "❌ Failed to update CloudFront distribution"
    echo "   You may need to update manually in AWS console"
fi

echo ""
echo "🔗 Step 3: Create DNS CNAME Record"
echo "----------------------------------"

# Create CNAME record pointing to CloudFront
echo "Creating CNAME record for $DOMAIN_NAME..."

cat > /tmp/cname-record.json << EOF
{
    "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "$DOMAIN_NAME",
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
    echo "✅ CNAME record created: $DOMAIN_NAME → $CLOUDFRONT_DOMAIN"
else
    echo "❌ Failed to create CNAME record"
fi

echo ""
echo "⚙️  Step 4: Update Configuration"
echo "-------------------------------"

# Update config file
echo "# Custom Domain Configuration" >> config/dev-config.sh
echo "export CUSTOM_DOMAIN=\"$DOMAIN_NAME\"" >> config/dev-config.sh
echo "export FRONTEND_CUSTOM_URL=\"https://$DOMAIN_NAME\"" >> config/dev-config.sh
echo "export ACM_CERTIFICATE_ARN=\"$CERT_ARN\"" >> config/dev-config.sh

echo ""
echo "🎉 Custom Domain Setup Complete!"
echo "================================"
echo ""
echo "📋 Summary:"
echo "   Custom Domain: $DOMAIN_NAME"
echo "   Certificate: $CERT_ARN"
echo "   CloudFront: $CLOUDFRONT_DISTRIBUTION_ID"
echo "   Hosted Zone: $HOSTED_ZONE_ID"
echo ""
echo "🌐 URLs:"
echo "   Custom Domain: https://$DOMAIN_NAME"
echo "   CloudFront: $FRONTEND_HTTPS_URL"
echo ""
echo "🔄 Next Steps:"
echo "1. Wait for CloudFront deployment (5-10 minutes)"
echo "2. Run: ./tools/update-cognito-https.sh"
echo "3. Test: curl -I https://$DOMAIN_NAME"
echo ""
echo "⚠️  Note: DNS propagation can take up to 24 hours globally"

# Clean up temp files
rm -f /tmp/dns-validation.json /tmp/current-distribution.json /tmp/updated-distribution.json /tmp/cname-record.json