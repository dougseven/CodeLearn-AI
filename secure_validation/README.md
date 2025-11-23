# Secure Code Validation Solutions

This directory contains two secure alternatives to the vulnerable direct code execution approach:

## 🚀 Option 1: AWS CodeBuild (Recommended)

**Pros:**
- Managed service with built-in isolation
- Easy to configure and maintain
- Cost-effective for sporadic usage
- Built-in logging and monitoring

**Files:**
- `codebuild_validator.py` - Lambda orchestrator
- `codebuild-project.yml` - CloudFormation template
- Deploys in minutes

### Setup Instructions:

1. **Deploy CodeBuild project:**
   ```bash
   aws cloudformation create-stack \
     --stack-name codelearn-validation \
     --template-body file://secure_validation/codebuild-project.yml \
     --parameters ParameterKey=ValidationBucket,ParameterValue=codelearn-validation \
     --capabilities CAPABILITY_IAM
   ```

2. **Update Lambda function:**
   ```bash
   # Replace validation_lambda/handler.py with codebuild_validator.py
   # Deploy with environment variables:
   export VALIDATION_PROJECT=codelearn-validation
   export VALIDATION_BUCKET=codelearn-validation
   ```

---

## 🔒 Option 2: ECS Fargate (Maximum Security)

**Pros:**
- Complete container isolation
- Read-only filesystem
- Dropped Linux capabilities
- Network isolation
- Resource limits

**Files:**
- `ecs_fargate_validator.py` - Lambda orchestrator  
- `Dockerfile` - Secure container image
- `validator_script.py` - Container execution script
- `ecs-task-definition.json` - Task configuration

### Setup Instructions:

1. **Build and push container:**
   ```bash
   # Build image
   docker build -t codelearn-validator .
   
   # Tag and push to ECR
   aws ecr create-repository --repository-name codelearn-validator
   docker tag codelearn-validator ACCOUNT.dkr.ecr.REGION.amazonaws.com/codelearn-validator:latest
   docker push ACCOUNT.dkr.ecr.REGION.amazonaws.com/codelearn-validator:latest
   ```

2. **Create ECS resources:**
   ```bash
   # Create cluster
   aws ecs create-cluster --cluster-name codelearn-validation
   
   # Register task definition (update account/region in JSON first)
   aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json
   ```

3. **Deploy Lambda:**
   ```bash
   # Environment variables:
   export VALIDATION_CLUSTER=codelearn-validation
   export VALIDATION_TASK_DEF=codelearn-validator
   export VALIDATION_SUBNETS=subnet-xxx,subnet-yyy
   export VALIDATION_SECURITY_GROUPS=sg-xxx
   ```

---

## 🛡️ Security Features

Both solutions provide:

### Input Validation
- Code length limits (10KB max)
- Forbidden imports/functions detection
- Syntax validation

### Execution Isolation
- **CodeBuild:** Isolated build environment per execution
- **Fargate:** Complete container isolation with security constraints

### Resource Limits
- Memory: 512MB max
- CPU: Limited compute
- Time: 5 minutes max execution
- Network: No internet access (Fargate)

### Security Constraints
- Non-root user execution
- Read-only filesystem (Fargate)
- Dropped Linux capabilities (Fargate)
- Minimal container image
- No dangerous tools available

---

## 📊 Comparison

| Feature | CodeBuild | ECS Fargate |
|---------|-----------|-------------|
| **Setup Complexity** | Simple | Moderate |
| **Security Level** | High | Maximum |
| **Cost** | Pay per build minute | Pay per task minute |
| **Scaling** | Automatic | Automatic |
| **Maintenance** | Minimal | Moderate |
| **Network Isolation** | Limited | Complete |

---

## 🚨 Migration from Vulnerable Code

**NEVER deploy the original validation_lambda/handler.py in production.**

Replace it with either solution above:

1. **Quick migration** → Use CodeBuild approach
2. **Maximum security** → Use Fargate approach

Both are infinitely safer than direct code execution in Lambda.

---

## 💡 Additional Security Recommendations

1. **VPC Isolation:** Deploy in private subnets with no internet access
2. **IAM Policies:** Use minimal permissions (examples provided)
3. **Monitoring:** Set up CloudWatch alarms for unusual usage
4. **Rate Limiting:** Implement API throttling
5. **Code Scanning:** Consider static analysis before execution
6. **Audit Logging:** Log all execution requests and results

---

## 🧪 Testing

Test the security of your implementation:

1. Try to import `os` - should be blocked
2. Try to execute shell commands - should fail
3. Try infinite loops - should timeout
4. Try large memory allocation - should be limited
5. Try network access - should be denied (Fargate)

Both solutions will safely reject or contain these attempts.