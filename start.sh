#!/bin/bash
# CodeLearn Platform - Smart Starter
# Automatically determines what you need and guides you there

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

echo "CodeLearn Platform - Smart Starter"
echo "==================================="
echo ""

# Check if this is first run
if [ ! -f ".setup-complete" ]; then
    echo -e "${YELLOW}👋 Welcome! It looks like this is your first time here.${NC}"
    echo ""
    echo "Let me help you get started..."
    echo ""
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo -e "${YELLOW}⚠️  AWS CLI is not installed.${NC}"
        echo ""
        echo "Please install it first:"
        echo "  macOS: brew install awscli"
        echo "  Linux: sudo apt install awscli"
        echo ""
        exit 1
    fi
    
    # Check if AWS is configured
    if ! aws sts get-caller-identity &> /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  AWS credentials not configured.${NC}"
        echo ""
        echo "Let's configure AWS now:"
        aws configure
        echo ""
    fi
    
    echo -e "${GREEN}✅ Prerequisites look good!${NC}"
    echo ""
    echo "I recommend starting with the setup script:"
    echo ""
    echo -e "${BLUE}./setup-dev.sh${NC}"
    echo ""
    echo "This will:"
    echo "  • Create the project structure"
    echo "  • Install dependencies"
    echo "  • Set up configuration files"
    echo "  • Create helper scripts"
    echo ""
    read -p "Run setup now? (y/n): " run_setup
    
    if [ "$run_setup" = "y" ]; then
        ./setup-dev.sh
        exit 0
    else
        echo ""
        echo "No problem! Run ./setup-dev.sh when you're ready."
        exit 0
    fi
fi

# Setup is complete, determine what user wants to do
echo "What would you like to do?"
echo ""
echo "  1. 💻 Development (quick commands)"
echo "  2. 📋 Operations (full menu)"
echo "  3. 📚 Read documentation"
echo "  4. 🧪 Run tests"
echo "  5. 📊 Check status"
echo "  6. 💰 Check costs"
echo "  7. 🆘 Get help"
echo ""
read -p "Choose (1-7): " choice

case $choice in
    1)
        echo ""
        echo "Opening development shortcuts..."
        echo ""
        ./dev.sh
        ;;
    2)
        echo ""
        echo "Opening operations menu..."
        echo ""
        ./quick-start-scripts.sh
        ;;
    3)
        echo ""
        echo "Available documentation:"
        echo ""
        ls -1 docs/*.md QUICKSTART.md QUICK_START_SCRIPTS_README.md 2>/dev/null
        echo ""
        read -p "Which file? " doc_file
        if [ -f "$doc_file" ]; then
            cat "$doc_file" | less
        else
            echo "File not found. Try: cat $doc_file"
        fi
        ;;
    4)
        echo ""
        echo "Running tests..."
        echo ""
        ./dev.sh test
        ;;
    5)
        echo ""
        echo "Checking platform status..."
        echo ""
        ./dev.sh check-config
        ;;
    6)
        echo ""
        echo "Checking costs..."
        echo ""
        ./dev.sh cost
        ;;
    7)
        echo ""
        echo "📚 Help Resources"
        echo "================="
        echo ""
        echo "Quick Start Guide:"
        echo "  cat QUICKSTART.md"
        echo ""
        echo "Script Documentation:"
        echo "  cat QUICK_START_SCRIPTS_README.md"
        echo ""
        echo "Development Commands:"
        echo "  ./dev.sh                    (shows all commands)"
        echo ""
        echo "Interactive Menu:"
        echo "  ./quick-start-scripts.sh    (full menu)"
        echo ""
        echo "Common Commands:"
        echo "  ./dev.sh deploy             Deploy everything"
        echo "  ./dev.sh deploy-fe          Deploy frontend only"
        echo "  ./dev.sh test               Run tests"
        echo "  ./dev.sh logs               View live logs"
        echo "  ./dev.sh cost               Check costs"
        echo "  ./dev.sh new-lesson         Create new lesson"
        echo ""
        ;;
    *)
        echo ""
        echo "Invalid choice. Try running:"
        echo "  ./dev.sh                 for development commands"
        echo "  ./quick-start-scripts.sh for full menu"
        ;;
esac

echo ""
echo -e "${BLUE}Tip: Run './start.sh' anytime for this menu${NC}"
