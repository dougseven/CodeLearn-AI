# CodeLearn-AI
CodeLearn AI is a web-based learning platform that provides personalized, AI-generated coding lessons and challenges. The platform adapts to the user's programming language preference and skill level, offering an interactive learning experience with real-time code validation and feedback.

CodeLearn AI is an AI-powered, budget-optimized coding education platform that provides personalized lessons and real-time code validation.

## 🎯 Goals

- Stay under $25/month AWS costs
- Provide personalized AI-generated lessons
- Real-time code validation and feedback

## 🏗️ Architecture

- **Frontend**: Static site on S3 + CloudFront
- **Backend**: AWS Lambda (Python 3.12)
- **Database**: DynamoDB (on-demand)
- **AI**: Amazon Bedrock (Claude 3 Haiku)
- **Auth**: AWS Cognito with OAuth 2.0
- **Code Execution**: Lambda with containerized Python

## 📁 Project Structure
```
codelearn-platform/
├── lesson_lambda/          # AI lesson generation
├── validation_lambda/      # Code validation
├── auth_lambda/           # Authentication handling
├── user_lambda/           # User profile management
├── cost_monitor/          # Cost tracking
├── emergency_shutdown/    # Emergency cost controls
├── frontend/             # Web application
├── static_lessons/       # Pre-built lessons (cost savings)
├── tools/               # Helper scripts
├── tests/               # Test files
├── config/              # Configuration files
└── docs/                # Documentation
```

## 🚀 Quick Start

See [Technical_Implementation_Guide_Enhanced.md](./docs/Technical_Implementation_Guide_Enhanced.md) for step-by-step instructions to build CodeLearn AI.

## 💰 Cost Optimization

Target: $20-25/month
- Claude 3.5 Haiku (cheaper than Sonnet)
- 90%+ cache hit rate on lessons
- 30 static lessons for common topics
- Right-sized Lambda (512MB)
- On-demand DynamoDB

## 📊 Monitoring

Run `./check-costs.sh` anytime to see current AWS costs.

## 🔒 Security

- All credentials in AWS Secrets Manager
- OAuth 2.0 authentication only
- Code execution in isolated containers
- No sensitive data in git

## 👤 Author

Doug Seven

## 📅 Status

**Current Phase**: Initial Development  
**Started**: November 2025

## 📝 License

MIT License

Copyright (c) 2025 Doug Seven

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.