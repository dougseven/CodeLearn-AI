# CodeLearn Platform - Quick Start Scripts

This directory contains quick-start scripts to simplify common development and operations tasks.

## 📦 Available Scripts

### 1. `setup-dev.sh` - New Developer Setup
**One-command setup for new developers**

```bash
./setup-dev.sh
```

**What it does:**
- ✅ Verifies prerequisites (AWS CLI, Python, Git)
- ✅ Configures AWS credentials
- ✅ Creates project structure
- ✅ Installs dependencies
- ✅ Sets up configuration files
- ✅ Initializes Git repository
- ✅ Creates helper scripts and documentation

**When to use:**
- First time setting up the project
- Setting up on a new machine
- Onboarding a new team member

---

### 2. `dev.sh` - Development Workflow
**Quick commands for daily development**

```bash
./dev.sh <command>
```

**Common commands:**

**Deploy:**
```bash
./dev.sh deploy           # Deploy everything
./dev.sh deploy-fe        # Deploy frontend only
./dev.sh deploy-lambda    # Deploy all Lambdas
./dev.sh deploy-lesson    # Deploy lesson Lambda only
```

**Test:**
```bash
./dev.sh test             # Run all tests
./dev.sh test-api         # Test API endpoints
./dev.sh test-lesson      # Test lesson generation
./dev.sh test-validate    # Test code validation
```

**Monitor:**
```bash
./dev.sh logs             # View live logs (lesson Lambda)
./dev.sh errors           # Show recent errors
./dev.sh stats            # Show Lambda statistics
./dev.sh cost             # Check current costs
```

**Develop:**
```bash
./dev.sh new-lesson       # Create new static lesson
./dev.sh validate-lessons # Validate all lessons
./dev.sh sync-lessons     # Upload lessons to S3
```

**Debug:**
```bash
./dev.sh invoke-lesson    # Test lesson Lambda locally
./dev.sh check-config     # Verify configuration
./dev.sh urls             # Show all URLs
```

**When to use:**
- Daily development tasks
- Quick deployments after code changes
- Testing and debugging
- Monitoring during development

---

### 3. `quick-start-scripts.sh` - Interactive Menu
**Full-featured interactive menu for all operations**

```bash
./quick-start-scripts.sh
```

**Features:**
- 📦 **Setup & Deployment** (7 options)
  - Fresh install, deploy all, deploy components
- 💻 **Development** (4 options)
  - Create lessons, test locally, update config
- 📊 **Monitoring & Maintenance** (5 options)
  - Health checks, dashboard, costs, logs, reports
- 🧪 **Testing** (4 options)
  - API tests, auth tests, load tests, E2E tests
- 🔧 **Troubleshooting** (4 options)
  - Fix issues, emergency controls, restart services
- 🛠️ **Utilities** (4 options)
  - Backup, show URLs, clean files, update config

**When to use:**
- When you don't remember exact commands
- For comprehensive operations
- Weekly maintenance tasks
- Emergency situations

---

## 🚀 Quick Start Guide

### First Time Setup

```bash
# 1. Run the setup script
./setup-dev.sh

# 2. Read the quick start guide
cat QUICKSTART.md

# 3. Deploy the platform
./quick-start-scripts.sh
# Select option 1 (Fresh Install) or 2 (Deploy All)

# 4. Test everything
./dev.sh test
```

### Daily Development Workflow

```bash
# Morning: Check status
./dev.sh check-config
./dev.sh cost

# Development: Make changes to code
# (edit files in lesson_lambda/, frontend/, etc.)

# Deploy changes
./dev.sh deploy-lesson    # Just one Lambda
# or
./dev.sh deploy          # Everything

# Test
./dev.sh test-lesson     # Quick test
./dev.sh test           # Full test

# Monitor
./dev.sh logs           # Live logs
./dev.sh stats          # Statistics
```

### Weekly Maintenance

```bash
# Run weekly report
./quick-start-scripts.sh
# Select option 14 (Generate Weekly Report)

# Or use dev shortcut
./dev.sh cost

# Create new lessons if needed
./dev.sh new-lesson
```

### Emergency Procedures

```bash
# If costs spike
./quick-start-scripts.sh
# Select option 20 (Emergency Cost Control)

# If API is down
./quick-start-scripts.sh
# Select option 19 (Fix Common Issues)

# View recent errors
./dev.sh errors
```

---

## 📋 Command Comparison

| Task | Interactive Menu | Dev Shortcut | Manual Command |
|------|------------------|--------------|----------------|
| Deploy all | Option 2 | `./dev.sh deploy` | Multiple commands |
| Deploy frontend | Option 3 | `./dev.sh deploy-fe` | `aws s3 sync...` |
| Test API | Option 15 | `./dev.sh test-api` | `./tools/test-api.sh` |
| View logs | Option 13 | `./dev.sh logs` | `aws logs tail...` |
| Check costs | Option 12 | `./dev.sh cost` | `./check-costs.sh` |
| New lesson | Option 6 | `./dev.sh new-lesson` | `python3 tools/...` |

**Rule of thumb:**
- Use `./dev.sh` for quick, frequent tasks
- Use `./quick-start-scripts.sh` for comprehensive operations
- Use manual commands for advanced/custom operations

---

## 🔧 Script Organization

```
codelearn-platform/
├── setup-dev.sh              # New developer setup
├── dev.sh                    # Development shortcuts
├── quick-start-scripts.sh    # Interactive menu
├── tools/
│   ├── update-lambda.sh      # Update Lambda functions
│   ├── test-api.sh           # Test API endpoints
│   ├── health-check.sh       # Daily health check
│   ├── dashboard.sh          # View dashboard
│   ├── lambda-stats.sh       # Lambda statistics
│   ├── optimize-costs.sh     # Cost optimization
│   ├── weekly-report.sh      # Generate reports
│   ├── e2e-test.sh           # End-to-end tests
│   ├── fix-common-issues.sh  # Troubleshooting
│   └── ...
└── check-costs.sh            # Quick cost check
```

---

## 💡 Pro Tips

### 1. Make Scripts Executable
```bash
chmod +x *.sh tools/*.sh
```

### 2. Use Tab Completion
```bash
./dev.sh dep<TAB>    # Autocompletes to deploy options
```

### 3. Chain Commands
```bash
./dev.sh deploy && ./dev.sh test && ./dev.sh logs
```

### 4. Create Aliases
Add to your `~/.bashrc` or `~/.zshrc`:
```bash
alias cl='cd ~/Projects/codelearn-platform'
alias cld='cd ~/Projects/codelearn-platform && ./dev.sh'
alias clm='cd ~/Projects/codelearn-platform && ./quick-start-scripts.sh'
```

Then use:
```bash
cl          # Go to project
cld deploy  # Quick deploy
clm         # Open menu
```

### 5. Load Config Automatically
Add to `~/.bashrc` or `~/.zshrc`:
```bash
if [ -f ~/Projects/codelearn-platform/config/dev-config.sh ]; then
    source ~/Projects/codelearn-platform/config/dev-config.sh
fi
```

---

## 🐛 Troubleshooting

### "Permission denied"
```bash
chmod +x script-name.sh
```

### "Command not found: aws"
```bash
# Install AWS CLI
brew install awscli  # macOS
# or
sudo apt install awscli  # Linux
```

### "No such file: config/dev-config.sh"
```bash
# Run setup again
./setup-dev.sh
```

### "Cannot connect to AWS"
```bash
# Reconfigure AWS credentials
aws configure
```

### Scripts don't work after git pull
```bash
# Make sure they're executable
chmod +x *.sh tools/*.sh

# Reload configuration
source config/dev-config.sh
```

---

## 📚 Additional Resources

### Documentation
- **Technical Guide**: `Technical_Implementation_Guide_Enhanced.md`
- **Quick Start**: `QUICKSTART.md`
- **API Docs**: `docs/api-documentation.md`
- **Operations**: `docs/operations-runbook.md`

### Helper Tools
- **Cost Monitor**: `./check-costs.sh`
- **S3 Manager**: `./tools/s3-manager.sh`
- **Lesson Validator**: `python3 tools/validate_lessons.py`
- **Lesson Generator**: `python3 tools/generate_lesson_template.py`

### AWS Console Links
- **Lambda Functions**: https://console.aws.amazon.com/lambda/
- **DynamoDB Tables**: https://console.aws.amazon.com/dynamodb/
- **S3 Buckets**: https://console.aws.amazon.com/s3/
- **CloudWatch Logs**: https://console.aws.amazon.com/cloudwatch/
- **Cost Explorer**: https://console.aws.amazon.com/cost-management/

---

## 🎯 Common Workflows

### Starting a New Feature
```bash
# 1. Create a new branch (optional)
git checkout -b feature/new-feature

# 2. Make your changes
# (edit code files)

# 3. Test locally
./dev.sh invoke-lesson

# 4. Deploy
./dev.sh deploy-lesson

# 5. Test in AWS
./dev.sh test-lesson

# 6. Monitor
./dev.sh logs

# 7. Commit
git add .
git commit -m "Add new feature"
```

### Fixing a Bug
```bash
# 1. View recent errors
./dev.sh errors

# 2. Check logs
./dev.sh logs

# 3. Make fix
# (edit code)

# 4. Test
./dev.sh invoke-lesson

# 5. Deploy
./dev.sh deploy-lesson

# 6. Verify
./dev.sh test

# 7. Monitor for a few minutes
./dev.sh logs
```

### Creating Content
```bash
# 1. Generate template
./dev.sh new-lesson

# 2. Edit the JSON file
# (fill in lesson content)

# 3. Validate
./dev.sh validate-lessons

# 4. Upload
./dev.sh sync-lessons

# 5. Test
./dev.sh test-lesson
```

### Weekly Maintenance
```bash
# 1. Run health check
./dev.sh check-config

# 2. Check costs
./dev.sh cost

# 3. Generate report
./quick-start-scripts.sh
# Select option 14

# 4. Review and optimize
# Check cache hit rate
# Convert popular AI lessons to static

# 5. Backup
./quick-start-scripts.sh
# Select option 23
```

---

## ⚡ Performance Tips

### Speed Up Deployments
```bash
# Deploy only what changed
./dev.sh deploy-lesson    # Just lesson Lambda
./dev.sh deploy-fe        # Just frontend

# Instead of
./dev.sh deploy          # Everything (slower)
```

### Reduce Costs
```bash
# Create more static lessons
./dev.sh new-lesson

# Check cache performance
./dev.sh stats

# Monitor daily
./dev.sh cost
```

### Faster Testing
```bash
# Test specific component
./dev.sh test-lesson      # Just lesson API
./dev.sh invoke-lesson    # Local test (no AWS)

# Instead of
./dev.sh test            # Everything (slower)
```

---

## 🆘 Getting Help

### In-Script Help
```bash
./dev.sh                  # Shows all commands
./quick-start-scripts.sh  # Interactive menu with descriptions
```

### Documentation
```bash
cat QUICKSTART.md         # Quick reference
cat docs/operations-runbook.md  # Operations guide
```

### Debugging
```bash
./dev.sh check-config     # Verify setup
./dev.sh errors          # View recent errors
./dev.sh logs            # Live logs
```

### Community
- Check GitHub issues
- Review documentation in `docs/`
- Run interactive troubleshooter: `./quick-start-scripts.sh` → Option 19

---

## 📝 Notes

- All scripts assume you're in the project root directory
- Configuration is loaded from `config/dev-config.sh`
- Most scripts require AWS credentials to be configured
- Scripts use colors for better readability (disable with `NO_COLOR=1`)

---

## ✨ Contributing

When adding new scripts:

1. Follow the existing naming convention
2. Add help text / usage instructions
3. Include error handling
4. Add to this README
5. Update the quick-start menu if appropriate
6. Test on a fresh setup

---

## 📄 License

Private project - All rights reserved

---

**Last Updated**: November 2025

**Maintainer**: [Your Name]

