#!/bin/bash
echo "🔍 Verifying Prerequisites..."
echo ""

# AWS CLI
if command -v aws &> /dev/null; then
    echo "✅ AWS CLI: $(aws --version)"
else
    echo "❌ AWS CLI not found"
fi

# AWS Credentials
if aws sts get-caller-identity &> /dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    echo "✅ AWS Credentials configured (Account: $ACCOUNT_ID)"
else
    echo "❌ AWS Credentials not configured"
fi

# Python
if command -v python3 &> /dev/null; then
    echo "✅ Python: $(python3 --version)"
else
    echo "❌ Python not found"
fi

# SAM CLI
if command -v sam &> /dev/null; then
    echo "✅ SAM CLI: $(sam --version)"
else
    echo "❌ SAM CLI not found"
fi

# Git
if command -v git &> /dev/null; then
    echo "✅ Git: $(git --version)"
else
    echo "❌ Git not found"
fi

echo ""
echo "If all items show ✅, you're ready to proceed!"
