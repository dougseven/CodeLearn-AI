# CodeLearn Platform - Quick Reference Card
**Print this or keep it handy!**

## 🚀 THE FOUR SCRIPTS

```
┌─────────────────────────────────────────────────────────────────┐
│  ./start.sh              Smart entry point - USE FIRST!         │
│  ./setup-dev.sh          Complete setup - RUN ONCE              │
│  ./dev.sh <cmd>          Development shortcuts - USE DAILY      │
│  ./quick-start-scripts.sh  Full menu - USE WEEKLY              │
└─────────────────────────────────────────────────────────────────┘
```

## ⚡ TOP 10 COMMANDS

```bash
# 1. Smart start (when in doubt)
./start.sh

# 2. Deploy everything
./dev.sh deploy

# 3. Deploy just frontend
./dev.sh deploy-fe

# 4. Deploy just one Lambda
./dev.sh deploy-lesson

# 5. Run all tests
./dev.sh test

# 6. View live logs
./dev.sh logs

# 7. Check current costs
./dev.sh cost

# 8. Create new lesson
./dev.sh new-lesson

# 9. Check configuration
./dev.sh check-config

# 10. Full operations menu
./quick-start-scripts.sh
```

## 📊 DAILY WORKFLOW

```
Morning:
  ./dev.sh check-config  ✓ Verify all systems
  ./dev.sh cost         ✓ Check overnight costs

Development:
  (edit code)           ✓ Make changes
  ./dev.sh deploy-lesson ✓ Deploy
  ./dev.sh test         ✓ Verify
  ./dev.sh logs         ✓ Monitor

Evening:
  git add . && git commit && git push  ✓ Save work
```

## 🎯 COMMON TASKS

```
┌──────────────────────────────────┬────────────────────────────┐
│ TASK                             │ COMMAND                    │
├──────────────────────────────────┼────────────────────────────┤
│ Deploy all changes               │ ./dev.sh deploy            │
│ Deploy frontend only             │ ./dev.sh deploy-fe         │
│ Deploy Lambda only               │ ./dev.sh deploy-lesson     │
│ Test everything                  │ ./dev.sh test              │
│ Test just the API                │ ./dev.sh test-api          │
│ View logs live                   │ ./dev.sh logs              │
│ See recent errors                │ ./dev.sh errors            │
│ Check costs                      │ ./dev.sh cost              │
│ Create new lesson                │ ./dev.sh new-lesson        │
│ Upload lessons to S3             │ ./dev.sh sync-lessons      │
│ Show all URLs                    │ ./dev.sh urls              │
│ Backup everything                │ ./dev.sh backup            │
└──────────────────────────────────┴────────────────────────────┘
```

## 🚨 EMERGENCY

```
┌──────────────────────────────────┬────────────────────────────┐
│ PROBLEM                          │ SOLUTION                   │
├──────────────────────────────────┼────────────────────────────┤
│ API not working                  │ ./dev.sh check-config      │
│                                  │ ./dev.sh errors            │
│                                  │ ./quick-start-scripts.sh   │
│                                  │   → Option 19              │
├──────────────────────────────────┼────────────────────────────┤
│ Costs too high                   │ ./quick-start-scripts.sh   │
│                                  │   → Option 20              │
├──────────────────────────────────┼────────────────────────────┤
│ Something broke                  │ ./dev.sh errors            │
│                                  │ ./dev.sh logs              │
├──────────────────────────────────┼────────────────────────────┤
│ Don't know what's wrong          │ ./quick-start-scripts.sh   │
│                                  │   → Option 19              │
└──────────────────────────────────┴────────────────────────────┘
```

## 📁 IMPORTANT FILES

```
Configuration:
  config/dev-config.sh       # All settings
  
Documentation:
  QUICKSTART.md              # Quick reference
  QUICK_START_INDEX.md       # Main index
  
Code:
  lesson_lambda/handler.py   # Lesson generation
  frontend/index.html        # Web app
  static_lessons/            # Pre-built lessons
```

## 🔗 IMPORTANT URLS

```bash
# View all URLs
./dev.sh urls

# Should show:
Frontend:    http://codelearn-frontend-XXXX.s3-website...
API:         https://XXXXX.execute-api.us-east-1...
Cognito:     https://codelearn-XXXX.auth.us-east-1...
```

## 📈 MONITORING

```
Daily:   ./dev.sh cost
         ./dev.sh errors
         
Weekly:  ./quick-start-scripts.sh
           → Option 14 (Weekly Report)
           
Monthly: Check AWS Cost Explorer
         Review cache hit rates
```

## 🎓 LEARNING PATH

```
Day 1:    ./setup-dev.sh
          cat QUICKSTART.md
          
Day 2-3:  ./quick-start-scripts.sh → Option 2
          ./dev.sh test
          
Day 4-5:  ./dev.sh new-lesson (repeat 5-10 times)
          
Week 2+:  ./dev.sh deploy (daily)
          ./dev.sh test (daily)
          ./quick-start-scripts.sh → Option 14 (weekly)
```

## ⚙️ SCRIPT CAPABILITIES

```
dev.sh:                    quick-start-scripts.sh:
  Deploy (4 commands)        Setup & Deploy (7 options)
  Test (4 commands)          Development (4 options)
  Monitor (5 commands)       Monitoring (5 options)
  Develop (3 commands)       Testing (4 options)
  Debug (4 commands)         Troubleshooting (4 options)
  Utility (2 commands)       Utilities (4 options)
```

## 💡 PRO TIPS

```bash
# Create aliases (add to ~/.bashrc or ~/.zshrc)
alias cl='cd ~/Projects/codelearn-platform'
alias cld='cd ~/Projects/codelearn-platform && ./dev.sh'
alias clm='cd ~/Projects/codelearn-platform && ./quick-start-scripts.sh'

# Then use:
cl              # Go to project
cld deploy      # Quick deploy
cld test        # Quick test
clm             # Open menu

# Chain commands
./dev.sh deploy && ./dev.sh test && ./dev.sh logs

# Get help
./dev.sh                    # Show all dev.sh commands
./quick-start-scripts.sh    # Interactive menu
./start.sh                  # Smart guidance
```

## 📞 HELP

```
Stuck?           ./start.sh
Need reference?  cat QUICKSTART.md
Full guide?      cat QUICK_START_COMPLETE_GUIDE.md
Technical docs?  cat Technical_Implementation_Guide_Enhanced.md
```

## ✅ CHECKLIST

```
Setup:
  [ ] Run ./setup-dev.sh
  [ ] ./dev.sh check-config shows all green
  [ ] ./dev.sh test passes
  [ ] Frontend URL loads
  
Daily:
  [ ] Morning: ./dev.sh check-config
  [ ] Morning: ./dev.sh cost
  [ ] After changes: ./dev.sh deploy
  [ ] After deploy: ./dev.sh test
  [ ] Monitor: ./dev.sh logs
  
Weekly:
  [ ] Generate report (Option 14)
  [ ] Check costs
  [ ] Create new lessons
  [ ] Review errors
```

## 🎯 MOST USED

```
90% of the time:           10% of the time:
  ./dev.sh deploy            ./quick-start-scripts.sh
  ./dev.sh test              ./dev.sh backup
  ./dev.sh logs              ./dev.sh clean
  ./dev.sh cost              
```

---

**REMEMBER:** When in doubt, run `./start.sh`

**Version:** 1.0 | **Date:** Nov 2025 | **Print & Keep Handy!**

