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
