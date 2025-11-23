#!/bin/bash

source config/dev-config.sh

echo "🌐 Setting up HTTPS Frontend with CloudFront"
echo "============================================"
echo ""

STACK_NAME="${PROJECT_NAME}-cloudfront-${ENVIRONMENT}"

# Check if we're using a custom domain
echo "Choose setup option:"
echo "1) Use CloudFront default domain (quick setup)"
echo "2) Use custom domain (requires domain ownership and ACM certificate)"
echo ""
read -p "Enter choice (1 or 2): " CHOICE

if [[ "$CHOICE" == "2" ]]; then
    echo ""
    echo "📝 Custom Domain Setup"
    echo "---------------------"
    read -p "Enter your domain name (e.g., codelearn.yourdomain.com): " CUSTOM_DOMAIN
    
    if [[ -z "$CUSTOM_DOMAIN" ]]; then
        echo "❌ Domain name cannot be empty"
        exit 1
    fi
    
    echo ""
    echo "🔐 SSL Certificate Setup"
    echo "------------------------"
    echo "For custom domains, you need an ACM certificate in us-east-1 (required for CloudFront)"
    echo ""
    echo "Options:"
    echo "a) Create new certificate (requires DNS validation)"
    echo "b) Use existing certificate ARN"
    echo ""
    read -p "Choose option (a or b): " CERT_CHOICE
    
    if [[ "$CERT_CHOICE" == "a" ]]; then
        echo "Creating ACM certificate..."
        CERT_ARN=$(aws acm request-certificate \
            --domain-name "$CUSTOM_DOMAIN" \
            --validation-method DNS \
            --region us-east-1 \
            --query 'CertificateArn' \
            --output text)
        
        if [[ $? -eq 0 ]]; then
            echo "✅ Certificate requested: $CERT_ARN"
            echo ""
            echo "⚠️  IMPORTANT: You must validate this certificate before proceeding"
            echo "   1. Go to ACM console: https://us-east-1.console.aws.amazon.com/acm/home"
            echo "   2. Find your certificate and add the required DNS records"
            echo "   3. Wait for validation (can take a few minutes)"
            echo ""
            read -p "Press Enter when certificate is validated..."
        else
            echo "❌ Failed to create certificate"
            exit 1
        fi
    elif [[ "$CERT_CHOICE" == "b" ]]; then
        read -p "Enter certificate ARN: " CERT_ARN
        if [[ -z "$CERT_ARN" ]]; then
            echo "❌ Certificate ARN cannot be empty"
            exit 1
        fi
    else
        echo "❌ Invalid choice"
        exit 1
    fi
    
    DOMAIN_PARAM="--parameters ParameterKey=DomainName,ParameterValue=$CUSTOM_DOMAIN ParameterKey=CertificateArn,ParameterValue=$CERT_ARN"
    echo "Will use custom domain: $CUSTOM_DOMAIN"
    
elif [[ "$CHOICE" == "1" ]]; then
    DOMAIN_PARAM=""
    echo "Will use CloudFront default domain"
else
    echo "❌ Invalid choice"
    exit 1
fi

echo ""
echo "🚀 Deploying CloudFront distribution..."
echo "This may take 15-20 minutes for CloudFront to deploy globally"
echo ""

# Deploy CloudFormation stack
aws cloudformation deploy \
    --template-file cloudfront/cloudfront-setup.yml \
    --stack-name "$STACK_NAME" \
    --parameter-overrides \
        ProjectName="$PROJECT_NAME" \
        Environment="$ENVIRONMENT" \
        S3BucketName="$FRONTEND_BUCKET" \
        $DOMAIN_PARAM \
    --region "$AWS_REGION" \
    --capabilities CAPABILITY_IAM

if [[ $? -eq 0 ]]; then
    echo ""
    echo "✅ CloudFront distribution deployed successfully!"
    echo ""
    
    # Get outputs
    DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionId`].OutputValue' \
        --output text)
    
    CLOUDFRONT_DOMAIN=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDomainName`].OutputValue' \
        --output text)
    
    CLOUDFRONT_URL="https://$CLOUDFRONT_DOMAIN"
    
    echo "📋 Distribution Information:"
    echo "  Distribution ID: $DISTRIBUTION_ID"
    echo "  CloudFront Domain: $CLOUDFRONT_DOMAIN"
    echo "  HTTPS URL: $CLOUDFRONT_URL"
    
    if [[ "$CHOICE" == "2" ]]; then
        CUSTOM_URL="https://$CUSTOM_DOMAIN"
        echo "  Custom Domain URL: $CUSTOM_URL"
        
        echo ""
        echo "🔗 DNS Configuration Required:"
        echo "  Create a CNAME record:"
        echo "    Name: $CUSTOM_DOMAIN"
        echo "    Value: $CLOUDFRONT_DOMAIN"
        echo ""
        
        # Update config with custom domain
        echo "export FRONTEND_HTTPS_URL=\"$CUSTOM_URL\"" >> config/dev-config.sh
    else
        # Update config with CloudFront domain  
        echo "export FRONTEND_HTTPS_URL=\"$CLOUDFRONT_URL\"" >> config/dev-config.sh
    fi
    
    echo ""
    echo "⏳ Note: CloudFront distribution may take 10-15 minutes to be fully deployed"
    echo "📁 Frontend files will be served from: $CLOUDFRONT_URL"
    echo ""
    echo "🔄 Next steps:"
    echo "1. Wait for CloudFront to deploy (check status in AWS console)"
    echo "2. Run: ./tools/update-cognito-https.sh"
    echo "3. Test the HTTPS frontend"
    
else
    echo "❌ Failed to deploy CloudFront distribution"
    exit 1
fi