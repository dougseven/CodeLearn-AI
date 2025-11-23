# Operations Runbook

## Daily Tasks

### Health Check
```bash
./tools/health-check.sh
```

Run every morning. If failures occur:
1. Check AWS Service Health Dashboard
2. Review Lambda logs: `aws logs tail /aws/lambda/CodeLearn-Lesson --follow`
3. Run diagnostics: `./tools/e2e-test.sh`

### Cost Check
```bash
./check-costs.sh
```

If over budget:
1. Run: `./tools/optimize-costs.sh`
2. Check cache hit rate
3. Review Bedrock usage in CloudWatch
4. Consider enabling EMERGENCY_MODE if critical

## Weekly Tasks

### Generate Report
```bash
./tools/weekly-report.sh > reports/week-$(date +%Y-%m-%d).txt
```

### Review and Optimize
1. Check cache hit rate (target: 90%+)
2. Review most requested lessons
3. Convert popular AI lessons to static
4. Update Lambda memory if needed

## Monthly Tasks

### Cost Review
1. AWS Cost Explorer → Last 30 days
2. Identify cost spikes
3. Optimize accordingly

### User Cleanup
```bash
# Remove inactive users (no login in 90 days)
# TODO: Create cleanup script
```

### Backup
```bash
# Export DynamoDB tables
aws dynamodb scan --table-name $USERS_TABLE > backup/users-$(date +%Y-%m-%d).json
```

## Emergency Procedures

### Cost Spike
If costs suddenly spike above $40:

1. **Immediate:** Enable emergency mode
```bash
aws lambda update-function-configuration \
    --function-name CodeLearn-Lesson \
    --environment Variables="{EMERGENCY_MODE=true,...}"
```

2. **Investigate:** Check CloudWatch for unusual activity
3. **Fix:** Identify and resolve issue
4. **Re-enable:** Set EMERGENCY_MODE=false

### API Down
If API returns 5xx errors:

1. Check Lambda logs
2. Verify IAM roles have permissions
3. Check DynamoDB tables are accessible
4. Re-deploy if needed: `./tools/update-lambda.sh all`

### Frontend Inaccessible
1. Check S3 bucket is accessible
2. Verify bucket policy allows public read
3. Check CloudFront (if using)
4. Re-deploy: `aws s3 sync frontend/ s3://$FRONTEND_BUCKET/`

## Monitoring Dashboards

### AWS Console
- CloudWatch: Custom dashboard (if created)
- Cost Explorer: Monthly costs
- Lambda: Function metrics

### CLI Tools
- `./tools/dashboard.sh` - Complete overview
- `./tools/lambda-stats.sh` - Lambda performance
- `./check-costs.sh` - Current costs

## Common Issues

### "Cache miss rate too high"
**Solution:** Generate more static lessons
```bash
python3 tools/generate_lesson_template.py python beginner "new topic"
# Fill in content
./tools/s3-manager.sh sync-lessons
```

### "Lambda timeout errors"
**Solution:** Increase timeout or optimize code
```bash
aws lambda update-function-configuration \
    --function-name CodeLearn-Lesson \
    --timeout 90
```

### "DynamoDB throttling"
**Solution:** Check for hot partition keys
- Review access patterns
- Consider using DAX (if budget allows)

## Scaling Considerations

### Under 500 users
- Current configuration is optimal
- Stay on on-demand DynamoDB pricing

### 500-1000 users  
- Consider provisioned DynamoDB capacity
- Increase Lambda reserved concurrency
- Budget: $30-40/month

### 1000+ users
- Need revenue/monetization
- Consider Aurora Serverless for database
- Add CloudFront for better performance
- Budget: $50-100+/month

## Contact & Support

**Documentation:** `/docs` directory  
**Logs:** CloudWatch Logs  
**Costs:** AWS Cost Explorer  

**Emergency Contact:** [Your contact info]