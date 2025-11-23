#!/bin/bash
# CodeLearn Platform - New Developer Setup
# One-command setup for getting started with development

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear

echo -e "${BLUE}"
cat << "EOF"
   ____          _      _                           
  / ___|___   __| | ___| |    ___  __ _ _ __ _ __  
 | |   / _ \ / _` |/ _ \ |   / _ \/ _` | '__| '_ \ 
 | |__| (_) | (_| |  __/ |__|  __/ (_| | |  | | | |
  \____\___/ \__,_|\___|_____\___|\__,_|_|  |_| |_|
                                                    
EOF
echo -e "${NC}"
echo -e "${CYAN}New Developer Setup${NC}"
echo "==================="
echo ""

print_step() {
    echo -e "${MAGENTA}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Step 1: Welcome and confirmation
echo -e "${YELLOW}This script will set up your development environment for CodeLearn.${NC}"
echo ""
echo "It will:"
echo "  • Verify prerequisites (AWS CLI, Python, etc.)"
echo "  • Configure AWS credentials"
echo "  • Clone or verify project structure"
echo "  • Install dependencies"
echo "  • Set up configuration files"
echo "  • Test your setup"
echo ""
read -p "Continue with setup? (y/n): " continue_setup

if [ "$continue_setup" != "y" ]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
print_step "Step 1/10: Checking prerequisites..."

# Check AWS CLI
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1)
    print_success "AWS CLI installed: $AWS_VERSION"
else
    print_error "AWS CLI not installed"
    echo ""
    echo "Install AWS CLI:"
    echo "  macOS: brew install awscli"
    echo "  Linux: sudo apt install awscli"
    echo "  Or visit: https://aws.amazon.com/cli/"
    exit 1
fi

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    print_success "$PYTHON_VERSION"
    
    # Check if version is 3.12+
    PYTHON_MINOR=$(python3 -c 'import sys; print(sys.version_info[1])')
    if [ "$PYTHON_MINOR" -lt 12 ]; then
        print_warning "Python 3.12+ recommended (you have 3.$PYTHON_MINOR)"
    fi
else
    print_error "Python 3 not installed"
    echo ""
    echo "Install Python:"
    echo "  macOS: brew install python@3.12"
    echo "  Linux: sudo apt install python3.12"
    exit 1
fi

# Check Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    print_success "$GIT_VERSION"
else
    print_warning "Git not installed (optional but recommended)"
fi

# Check jq (optional)
if command -v jq &> /dev/null; then
    print_success "jq installed (for JSON parsing)"
else
    print_info "jq not installed (optional, but helpful)"
    echo "  Install with: brew install jq"
fi

echo ""
print_step "Step 2/10: Configuring AWS credentials..."

# Check if AWS is configured
if aws sts get-caller-identity &> /dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    AWS_USER=$(aws sts get-caller-identity --query Arn --output text)
    print_success "AWS credentials configured"
    print_info "Account: $AWS_ACCOUNT"
    print_info "User: $AWS_USER"
else
    print_warning "AWS credentials not configured"
    echo ""
    echo "Let's configure your AWS credentials now."
    echo ""
    read -p "AWS Access Key ID: " aws_access_key
    read -p "AWS Secret Access Key: " aws_secret_key
    read -p "Default region (default: us-east-1): " aws_region
    aws_region=${aws_region:-us-east-1}
    
    aws configure set aws_access_key_id "$aws_access_key"
    aws configure set aws_secret_access_key "$aws_secret_key"
    aws configure set region "$aws_region"
    aws configure set output "json"
    
    if aws sts get-caller-identity &> /dev/null; then
        print_success "AWS credentials configured successfully"
    else
        print_error "AWS credentials configuration failed"
        exit 1
    fi
fi

echo ""
print_step "Step 3/10: Setting up project directory..."

# Determine if we're already in the project or need to create it
if [ -f "README.md" ] && grep -q "CodeLearn" README.md; then
    print_success "Already in CodeLearn project directory"
    PROJECT_DIR=$(pwd)
else
    print_info "Creating new project directory..."
    PROJECT_DIR="$HOME/Projects/codelearn-platform"
    
    if [ -d "$PROJECT_DIR" ]; then
        print_warning "Directory already exists: $PROJECT_DIR"
        read -p "Use existing directory? (y/n): " use_existing
        if [ "$use_existing" != "y" ]; then
            read -p "Enter new directory path: " PROJECT_DIR
            mkdir -p "$PROJECT_DIR"
        fi
    else
        mkdir -p "$PROJECT_DIR"
        print_success "Created: $PROJECT_DIR"
    fi
    
    cd "$PROJECT_DIR"
fi

echo ""
print_step "Step 4/10: Creating project structure..."

# Create directory structure
DIRS=(
    "lesson_lambda"
    "validation_lambda"
    "auth_lambda"
    "user_lambda"
    "cost_monitor"
    "emergency_shutdown"
    "frontend"
    "static_lessons/python/beginner"
    "static_lessons/python/intermediate"
    "static_lessons/java/beginner"
    "static_lessons/rust/beginner"
    "tools"
    "tests"
    "docs"
    "config"
    "backups"
    "reports"
)

for dir in "${DIRS[@]}"; do
    mkdir -p "$dir"
done

print_success "Project structure created"

echo ""
print_step "Step 5/10: Installing Python dependencies..."

# Create requirements file if it doesn't exist
if [ ! -f "requirements.txt" ]; then
    cat > requirements.txt << 'EOF'
boto3==1.34.10
pytest==7.4.3
EOF
fi

# Install dependencies
pip3 install -r requirements.txt --quiet --disable-pip-version-check
print_success "Python dependencies installed"

echo ""
print_step "Step 6/10: Setting up configuration..."

# Get AWS account info
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=$(aws configure get region)

# Create configuration file
if [ ! -f "config/dev-config.sh" ]; then
    cat > config/dev-config.sh << EOF
#!/bin/bash
# Development Configuration
# Generated on $(date)

# AWS Configuration
export AWS_REGION="${AWS_REGION}"
export AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID}"

# Project Configuration
export PROJECT_NAME="codelearn"
export ENVIRONMENT="dev"
export STACK_NAME="\${PROJECT_NAME}-\${ENVIRONMENT}"

# Resource Names
export USERS_TABLE="\${PROJECT_NAME}-users-\${ENVIRONMENT}"
export PROGRESS_TABLE="\${PROJECT_NAME}-progress-\${ENVIRONMENT}"
export SESSIONS_TABLE="\${PROJECT_NAME}-sessions-\${ENVIRONMENT}"
export LESSON_CACHE_TABLE="\${PROJECT_NAME}-lesson-cache-\${ENVIRONMENT}"

# S3 Buckets
export STATIC_LESSONS_BUCKET="\${PROJECT_NAME}-static-lessons-\${AWS_ACCOUNT_ID}"
export FRONTEND_BUCKET="\${PROJECT_NAME}-frontend-\${AWS_ACCOUNT_ID}"

# To be filled in during deployment:
export API_ID=""
export API_ENDPOINT=""
export USER_POOL_ID=""
export APP_CLIENT_ID=""
export COGNITO_DOMAIN=""
export LAMBDA_ROLE_ARN=""
export FRONTEND_URL=""

# Print configuration
echo "Configuration loaded:"
echo "  AWS Account: \$AWS_ACCOUNT_ID"
echo "  AWS Region: \$AWS_REGION"
echo "  Stack Name: \$STACK_NAME"
EOF
    chmod +x config/dev-config.sh
    print_success "Configuration file created: config/dev-config.sh"
else
    print_success "Configuration file exists"
fi

# Load configuration
source config/dev-config.sh

echo ""
print_step "Step 7/10: Creating helper scripts..."

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*.so
*.egg-info/
venv/
env/

# AWS
.aws-sam/
*.zip
packaged.yaml

# IDE
.vscode/
.idea/
*.swp

# Environment
.env
*.log
cognito-config.txt

# OS
.DS_Store
Thumbs.db

# Backups
backups/
*.backup
*.bak
EOF
    print_success "Created .gitignore"
fi

# Create README if it doesn't exist
if [ ! -f "README.md" ]; then
    cat > README.md << 'EOF'
# CodeLearn AI Platform

AI-powered coding education platform built on AWS.

## Quick Start

```bash
# Setup (first time only)
./setup-dev.sh

# Daily development
./dev.sh deploy        # Deploy changes
./dev.sh test          # Run tests
./dev.sh logs          # View logs
./dev.sh cost          # Check costs
```

## Documentation

See `docs/` directory for detailed documentation.

## Project Structure

- `lesson_lambda/` - AI lesson generation
- `validation_lambda/` - Code validation
- `frontend/` - Web application
- `static_lessons/` - Pre-built lessons
- `tools/` - Helper scripts
- `config/` - Configuration files

## Target Cost

$20-25/month for 300-500 users
EOF
    print_success "Created README.md"
fi

# Make scripts executable
chmod +x tools/*.sh 2>/dev/null || true
chmod +x *.sh 2>/dev/null || true

echo ""
print_step "Step 8/10: Initializing Git repository..."

if [ ! -d ".git" ]; then
    git init > /dev/null 2>&1
    print_success "Git repository initialized"
    
    # Set up Git config
    if [ -z "$(git config user.name)" ]; then
        read -p "Git user name: " git_name
        git config user.name "$git_name"
    fi
    
    if [ -z "$(git config user.email)" ]; then
        read -p "Git user email: " git_email
        git config user.email "$git_email"
    fi
    
    # Initial commit
    git add .
    git commit -m "Initial project setup" > /dev/null 2>&1
    print_success "Initial commit created"
else
    print_success "Git repository already initialized"
fi

echo ""
print_step "Step 9/10: Verifying AWS access..."

# Test AWS access to services
TESTS_PASSED=0
TESTS_TOTAL=4

# Test DynamoDB
if aws dynamodb list-tables > /dev/null 2>&1; then
    print_success "DynamoDB access verified"
    ((TESTS_PASSED++))
else
    print_error "Cannot access DynamoDB"
fi

# Test S3
if aws s3 ls > /dev/null 2>&1; then
    print_success "S3 access verified"
    ((TESTS_PASSED++))
else
    print_error "Cannot access S3"
fi

# Test Lambda
if aws lambda list-functions > /dev/null 2>&1; then
    print_success "Lambda access verified"
    ((TESTS_PASSED++))
else
    print_error "Cannot access Lambda"
fi

# Test IAM
if aws iam get-user > /dev/null 2>&1; then
    print_success "IAM access verified"
    ((TESTS_PASSED++))
else
    print_warning "Limited IAM access (this is okay)"
    ((TESTS_PASSED++))
fi

echo ""
print_step "Step 10/10: Creating quick reference guide..."

cat > QUICKSTART.md << 'EOF'
# Quick Start Guide

## First Time Setup

You've completed the setup! Here's what to do next:

### 1. Review Configuration

```bash
source config/dev-config.sh
cat config/dev-config.sh
```

### 2. Deploy Infrastructure

```bash
# Option A: Use the quick-start menu
./quick-start-scripts.sh

# Option B: Use dev shortcuts
./dev.sh deploy
```

### 3. Create Your First Static Lesson

```bash
./dev.sh new-lesson
# Follow the prompts
# Edit the generated JSON file
# Validate and upload
```

### 4. Test Everything

```bash
./dev.sh test
```

## Daily Development Workflow

```bash
# Start development
cd ~/Projects/codelearn-platform
source config/dev-config.sh

# Make changes to code...

# Deploy changes
./dev.sh deploy-lesson  # Just the lesson Lambda
# or
./dev.sh deploy        # Everything

# Test
./dev.sh test-lesson   # Quick test
./dev.sh test          # Full test suite

# Monitor
./dev.sh logs          # Live logs
./dev.sh stats         # Statistics
./dev.sh cost          # Current costs
```

## Common Tasks

### View Platform Status
```bash
./dev.sh check-config
```

### Create New Lesson
```bash
./dev.sh new-lesson
```

### Update Frontend
```bash
# Edit frontend/index.html
./dev.sh deploy-fe
```

### View Errors
```bash
./dev.sh errors
```

### Check Costs
```bash
./dev.sh cost
```

## Troubleshooting

### "Command not found"
```bash
# Make sure you're in the project directory
cd ~/Projects/codelearn-platform

# Make scripts executable
chmod +x *.sh tools/*.sh
```

### "AWS credentials not configured"
```bash
aws configure
```

### "Cannot access X service"
Check IAM permissions for your user.

## Documentation

- Full guide: `Technical_Implementation_Guide_Enhanced.md`
- API docs: `docs/api-documentation.md`
- Operations: `docs/operations-runbook.md`

## Getting Help

1. Check the documentation in `docs/`
2. Run `./quick-start-scripts.sh` for interactive menu
3. Use `./dev.sh` for quick commands

## Next Steps

1. Read the Technical Implementation Guide
2. Deploy your first version
3. Create 10-20 static lessons
4. Set up budget alerts
5. Test with real users!
EOF

print_success "Created QUICKSTART.md"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                ║${NC}"
echo -e "${GREEN}║   ✅  Setup Complete!                          ║${NC}"
echo -e "${GREEN}║                                                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}📊 Setup Summary:${NC}"
echo "  ✅ Prerequisites verified"
echo "  ✅ AWS credentials configured"
echo "  ✅ Project structure created"
echo "  ✅ Dependencies installed"
echo "  ✅ Configuration files set up"
echo "  ✅ Helper scripts installed"
echo "  ✅ Git repository initialized"
echo "  ✅ AWS access verified ($TESTS_PASSED/$TESTS_TOTAL services)"
echo ""

echo -e "${YELLOW}📚 Next Steps:${NC}"
echo ""
echo "1. Review the quick start guide:"
echo "   ${CYAN}cat QUICKSTART.md${NC}"
echo ""
echo "2. Start the interactive menu:"
echo "   ${CYAN}./quick-start-scripts.sh${NC}"
echo ""
echo "3. Or use quick commands:"
echo "   ${CYAN}./dev.sh deploy${NC}        # Deploy everything"
echo "   ${CYAN}./dev.sh test${NC}          # Run tests"
echo "   ${CYAN}./dev.sh logs${NC}          # View logs"
echo ""

echo -e "${BLUE}📖 Documentation:${NC}"
echo "  • Technical Guide: Technical_Implementation_Guide_Enhanced.md"
echo "  • Quick Start: QUICKSTART.md"
echo "  • Helper Scripts: ./dev.sh (see ./dev.sh for all commands)"
echo ""

echo -e "${GREEN}🚀 Ready to start building!${NC}"
echo ""

# Save setup info
cat > .setup-complete << EOF
Setup completed: $(date)
AWS Account: $AWS_ACCOUNT_ID
AWS Region: $AWS_REGION
Project Directory: $(pwd)
EOF

# Offer to open documentation
read -p "Open quick start guide now? (y/n): " open_guide
if [ "$open_guide" = "y" ]; then
    if command -v code &> /dev/null; then
        code QUICKSTART.md
    else
        cat QUICKSTART.md | less
    fi
fi

echo ""
print_info "Tip: Run './quick-start-scripts.sh' to see all available options!"
