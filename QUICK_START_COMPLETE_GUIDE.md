# Quick Start Scripts - Complete Guide

## 📦 What You've Got

I've created a complete set of quick-start scripts to make development and operations as smooth as possible. Here's everything you have:

## 🎯 The Scripts

### 1. **`start.sh`** - Your Starting Point
**The smart entry point that figures out what you need**

```bash
./start.sh
```

**What it does:**
- Detects if this is your first time
- Guides you through initial setup if needed
- Presents a simple menu for common tasks
- Points you to the right tool for what you want to do

**When to use:** 
- First time running the project
- When you forget which script to use
- Quick access to common tasks

---

### 2. **`setup-dev.sh`** - Complete Setup
**One-command setup for new developers**

```bash
./setup-dev.sh
```

**What it does:**
- ✅ Verifies all prerequisites (AWS CLI, Python, Git)
- ✅ Configures AWS credentials
- ✅ Creates complete project structure
- ✅ Installs all dependencies
- ✅ Sets up configuration files
- ✅ Creates helper scripts
- ✅ Initializes Git repository
- ✅ Verifies AWS access to all services
- ✅ Creates documentation and guides

**When to use:**
- First time setting up the project
- Setting up on a new machine
- Onboarding a new team member
- After major system changes

**Time:** ~5-10 minutes

---

### 3. **`dev.sh`** - Development Shortcuts
**Quick commands for daily development**

```bash
./dev.sh <command>
```

**Categories:**

**DEPLOY:**
```bash
./dev.sh deploy           # Everything
./dev.sh deploy-fe        # Frontend only
./dev.sh deploy-lambda    # All Lambdas
./dev.sh deploy-lesson    # Lesson Lambda only
```

**TEST:**
```bash
./dev.sh test             # All tests
./dev.sh test-api         # API endpoints
./dev.sh test-lesson      # Lesson generation
./dev.sh test-validate    # Code validation
```

**MONITOR:**
```bash
./dev.sh logs             # Live logs (lesson)
./dev.sh logs-validation  # Validation logs
./dev.sh errors           # Recent errors
./dev.sh stats            # Lambda statistics
./dev.sh cost             # Current costs
```

**DEVELOP:**
```bash
./dev.sh new-lesson       # Create new lesson
./dev.sh validate-lessons # Validate all lessons
./dev.sh sync-lessons     # Upload to S3
```

**DEBUG:**
```bash
./dev.sh invoke-lesson    # Test locally
./dev.sh invoke-validate  # Test locally
./dev.sh check-config     # Verify config
./dev.sh urls             # Show all URLs
```

**UTILITY:**
```bash
./dev.sh backup           # Quick backup
./dev.sh clean            # Clean temp files
```

**When to use:**
- Daily development
- Quick deployments
- Rapid testing
- Frequent monitoring

**Time:** Instant (commands run in seconds)

---

### 4. **`quick-start-scripts.sh`** - Full Menu
**Interactive menu with 26 options covering everything**

```bash
./quick-start-scripts.sh
```

**Sections:**

**SETUP & DEPLOYMENT (7 options)**
1. Fresh Install
2. Deploy All
3. Deploy Frontend Only
4. Deploy Lambda Functions Only
5. Update Single Lambda

**DEVELOPMENT (4 options)**
6. Create New Static Lesson
7. Test Lesson Locally
8. Update API Configuration
9. Reset Database

**MONITORING & MAINTENANCE (5 options)**
10. Daily Health Check
11. View Dashboard
12. Check Costs
13. View Logs (Live)
14. Generate Weekly Report

**TESTING (4 options)**
15. Test All APIs
16. Test Authentication
17. Load Test
18. End-to-End Test

**TROUBLESHOOTING (4 options)**
19. Fix Common Issues
20. Emergency Cost Control
21. Restart All Services
22. View Error Logs

**UTILITIES (4 options)**
23. Backup All Data
24. Show All URLs
25. Clean Temporary Files
26. Update Configuration

**When to use:**
- Weekly maintenance
- Comprehensive operations
- When you don't remember commands
- Emergency situations
- Training new team members

**Time:** Varies by option (seconds to minutes)

---

## 🚀 Quick Start Workflow

### First Day (Setup)

```bash
# 1. Run this first
./start.sh

# 2. Follow prompts to run setup
# (or run directly)
./setup-dev.sh

# 3. Read the quick start guide
cat QUICKSTART.md

# 4. Deploy the platform
./quick-start-scripts.sh
# Choose option 1 (Fresh Install) or 2 (Deploy All)
```

**Time:** ~30-60 minutes (mostly waiting for AWS)

### Daily Development

```bash
# Morning routine
./dev.sh check-config     # Verify everything is running
./dev.sh cost            # Check overnight costs

# Make code changes
# (edit files in VSCode)

# Test locally (optional)
./dev.sh invoke-lesson

# Deploy
./dev.sh deploy-lesson   # Just what changed
# or
./dev.sh deploy         # Everything

# Test
./dev.sh test-lesson    # Quick
./dev.sh test          # Comprehensive

# Monitor
./dev.sh logs          # Watch for errors
```

**Time:** Deploy in ~30 seconds, test in ~1 minute

### Weekly Maintenance

```bash
# Run the full menu
./quick-start-scripts.sh

# Choose option 14: Generate Weekly Report
# Review costs and performance

# Choose option 10: Daily Health Check
# Verify all systems operational

# Backup if needed
# Option 23: Backup All Data
```

**Time:** ~5-10 minutes

### Emergency Procedures

```bash
# Costs too high?
./quick-start-scripts.sh
# Option 20: Emergency Cost Control

# API not working?
./quick-start-scripts.sh
# Option 19: Fix Common Issues

# Check what's wrong
./dev.sh errors         # Recent errors
./dev.sh logs          # Live logs
```

**Time:** ~2-5 minutes to diagnose and fix

---

## 📊 Command Comparison Matrix

| Task | Simple (`dev.sh`) | Full Menu | Manual |
|------|-------------------|-----------|--------|
| **Deploy all** | `./dev.sh deploy` | Option 2 | 10+ commands |
| **Deploy frontend** | `./dev.sh deploy-fe` | Option 3 | 3 commands |
| **Test API** | `./dev.sh test-api` | Option 15 | 1 command |
| **View logs** | `./dev.sh logs` | Option 13 | 1 command |
| **Check costs** | `./dev.sh cost` | Option 12 | 1 command |
| **New lesson** | `./dev.sh new-lesson` | Option 6 | 2 commands |
| **Backup** | `./dev.sh backup` | Option 23 | 5+ commands |
| **Weekly report** | N/A | Option 14 | 3 commands |
| **Fix issues** | N/A | Option 19 | Varies |
| **Fresh install** | N/A | Option 1 | 50+ commands |

**Legend:**
- ⚡ **Fast**: `dev.sh` - Use for quick, frequent tasks
- 🔧 **Comprehensive**: `quick-start-scripts.sh` - Use for full operations
- 📝 **Manual**: Direct commands - Use for custom/advanced operations

---

## 💡 Best Practices

### For Daily Development

**Use `dev.sh` shortcuts:**
```bash
# Quick workflow
./dev.sh deploy-lesson && ./dev.sh test && ./dev.sh logs
```

**Create aliases in `~/.bashrc` or `~/.zshrc`:**
```bash
alias cl='cd ~/Projects/codelearn-platform'
alias cld='cd ~/Projects/codelearn-platform && ./dev.sh'
alias clm='cd ~/Projects/codelearn-platform && ./quick-start-scripts.sh'
alias cls='cd ~/Projects/codelearn-platform && ./start.sh'
```

Then:
```bash
cl              # Go to project
cld deploy      # Quick deploy
cld test        # Quick test
clm             # Open full menu
cls             # Smart start
```

### For Operations

**Use the interactive menu:**
```bash
./quick-start-scripts.sh
```

**Bookmark common options:**
- Option 2: Deploy All (after major changes)
- Option 10: Daily Health Check (every morning)
- Option 12: Check Costs (daily)
- Option 14: Weekly Report (every Monday)
- Option 19: Fix Common Issues (when things break)

### For Troubleshooting

**Start with diagnostics:**
```bash
./dev.sh check-config   # Verify setup
./dev.sh errors        # Recent errors
./dev.sh logs          # Live logs
```

**Use the troubleshooter:**
```bash
./quick-start-scripts.sh
# Option 19: Fix Common Issues
```

---

## 🎓 Learning Path

### Week 1: Getting Started
**Day 1:** Setup
```bash
./setup-dev.sh
cat QUICKSTART.md
```

**Day 2-3:** Deploy and test
```bash
./quick-start-scripts.sh  # Option 2: Deploy All
./dev.sh test
```

**Day 4-5:** Create content
```bash
./dev.sh new-lesson  # Repeat 5-10 times
./dev.sh validate-lessons
./dev.sh sync-lessons
```

### Week 2: Daily Operations
**Daily:**
```bash
./dev.sh check-config
./dev.sh cost
# Make changes
./dev.sh deploy-lesson
./dev.sh test
```

**Weekly:**
```bash
./quick-start-scripts.sh  # Option 14: Weekly Report
```

### Week 3+: Optimization
- Create more static lessons
- Monitor cache hit rates
- Optimize Lambda functions
- Fine-tune costs

---

## 📚 Documentation Structure

```
codelearn-platform/
├── start.sh                           # ← Start here!
├── setup-dev.sh                       # First-time setup
├── dev.sh                            # Daily shortcuts
├── quick-start-scripts.sh            # Full menu
│
├── QUICKSTART.md                     # Quick reference
├── QUICK_START_SCRIPTS_README.md     # This file
│
├── Technical_Implementation_Guide_Enhanced.md  # Complete guide
│
├── docs/
│   ├── api-documentation.md
│   ├── authentication-flow.md
│   ├── operations-runbook.md
│   ├── lesson-creation-guide.md
│   └── dynamodb-schemas.md
│
└── tools/
    ├── test-api.sh
    ├── health-check.sh
    ├── dashboard.sh
    ├── lambda-stats.sh
    ├── weekly-report.sh
    └── ...
```

**Reading order for new developers:**
1. This file (QUICK_START_SCRIPTS_README.md)
2. QUICKSTART.md
3. Technical_Implementation_Guide_Enhanced.md (as needed)
4. Specific docs in `docs/` (as needed)

---

## 🔍 Troubleshooting Guide

### "Permission denied"
```bash
chmod +x start.sh setup-dev.sh dev.sh quick-start-scripts.sh
chmod +x tools/*.sh
```

### "Command not found: aws"
```bash
# Install AWS CLI
brew install awscli  # macOS
sudo apt install awscli  # Linux
```

### "AWS credentials not configured"
```bash
aws configure
# Enter your credentials
```

### "Config file not found"
```bash
# Run setup
./setup-dev.sh
```

### "Script does nothing"
```bash
# Make sure you're in project directory
cd ~/Projects/codelearn-platform

# Reload config
source config/dev-config.sh

# Try again
```

### "Cannot access AWS service"
```bash
# Check IAM permissions
# Your user needs access to:
# - Lambda
# - DynamoDB
# - S3
# - API Gateway
# - Cognito
# - CloudWatch
```

---

## 🎯 Cheat Sheet

### Most Common Commands

```bash
# Setup (first time only)
./setup-dev.sh

# Daily development
./dev.sh deploy          # Deploy changes
./dev.sh test           # Test
./dev.sh logs           # Monitor

# Create content
./dev.sh new-lesson     # New lesson
./dev.sh sync-lessons   # Upload

# Monitoring
./dev.sh cost           # Check costs
./dev.sh stats          # Performance
./dev.sh errors         # Problems

# Troubleshooting
./dev.sh check-config   # Verify setup
./quick-start-scripts.sh  # Full menu → Option 19

# Weekly
./quick-start-scripts.sh  # Option 14: Weekly Report

# Emergency
./quick-start-scripts.sh  # Option 20: Cost Control
```

### File Locations

```bash
# Configuration
config/dev-config.sh

# Logs
/aws/lambda/CodeLearn-Lesson
/aws/lambda/CodeLearn-Validation

# Data
static_lessons/           # Your lessons
backups/                  # Backups
reports/                  # Weekly reports

# Code
lesson_lambda/            # AI generation
validation_lambda/        # Code testing
frontend/                 # Web app
```

---

## 🚀 Next Steps

### After Setup

1. **Read Documentation**
   ```bash
   cat QUICKSTART.md
   ```

2. **Deploy Platform**
   ```bash
   ./quick-start-scripts.sh  # Option 2
   ```

3. **Create Lessons**
   ```bash
   ./dev.sh new-lesson  # Repeat 10-20 times
   ```

4. **Set Up Monitoring**
   ```bash
   ./quick-start-scripts.sh  # Option 10
   ```

### After First Week

1. **Review Costs**
   ```bash
   ./dev.sh cost
   ```

2. **Optimize**
   - Create more static lessons
   - Check cache hit rates
   - Review Lambda performance

3. **Automate**
   - Set up cron jobs for health checks
   - Schedule weekly reports
   - Configure cost alerts

---

## 📞 Getting Help

### In-Script Help
```bash
./dev.sh              # Shows all commands
./quick-start-scripts.sh  # Interactive menu
./start.sh            # Smart starter
```

### Documentation
```bash
cat QUICKSTART.md
cat QUICK_START_SCRIPTS_README.md
cat Technical_Implementation_Guide_Enhanced.md
```

### Troubleshooting
```bash
./dev.sh check-config
./dev.sh errors
./quick-start-scripts.sh  # Option 19
```

---

## ✅ Success Checklist

### Setup Complete When:
- [ ] `./start.sh` runs without errors
- [ ] `./dev.sh check-config` shows all green
- [ ] `./dev.sh test` passes
- [ ] Frontend URL loads in browser
- [ ] Can create and deploy a lesson
- [ ] Costs are under $1 for first week

### Platform Healthy When:
- [ ] Daily health check passes
- [ ] No errors in last 24 hours
- [ ] Costs under $25/month
- [ ] Cache hit rate > 90%
- [ ] All APIs responding in < 2 seconds

### Production Ready When:
- [ ] 20+ static lessons created
- [ ] All tests passing
- [ ] Cost monitoring active
- [ ] Backup schedule established
- [ ] Documentation reviewed
- [ ] Team trained on scripts

---

## 🎉 Summary

You now have **four powerful tools**:

1. **`start.sh`** - Smart entry point
2. **`setup-dev.sh`** - One-command setup
3. **`dev.sh`** - Daily development shortcuts
4. **`quick-start-scripts.sh`** - Comprehensive operations menu

**Use them wisely:**
- Start with `./start.sh`
- Set up with `./setup-dev.sh`
- Develop with `./dev.sh`
- Operate with `./quick-start-scripts.sh`

**Remember:**
- Scripts are designed to work together
- Start simple, get sophisticated later
- When in doubt, use the interactive menu
- Documentation is your friend

---

**Happy coding! 🚀**

