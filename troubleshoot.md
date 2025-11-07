# Troubleshooting Guide - CI/CD Pipeline for E-Commerce Platform

## 🚨 Systematic Troubleshooting Methodology

This guide provides a structured approach to diagnosing and resolving issues in CI/CD pipelines using AWS CodePipeline, CodeBuild, and CodeDeploy.

---

## 1. Pipeline Overview and Common Failure Points

### Pipeline Flow Analysis
```
GitHub → CodePipeline → CodeBuild → CodeDeploy → EC2 Instances
   ↓         ↓            ↓           ↓            ↓
Source    Orchestration  Build     Deploy    Application
Stage      Engine        Stage     Stage      Runtime
```

### Common Failure Categories
1. **Source Stage Issues**: GitHub integration, webhook problems
2. **Build Stage Issues**: CodeBuild configuration, buildspec.yml errors
3. **Deploy Stage Issues**: CodeDeploy configuration, EC2 instance problems
4. **Application Issues**: Runtime errors, configuration problems
5. **Infrastructure Issues**: Network, security, permissions

---

## 2. Source Stage Troubleshooting

### Problem: Pipeline not triggering on code commits

**Symptoms:**
- Code pushed to GitHub but pipeline doesn't start
- Pipeline shows "Source" stage as not executed
- No recent executions in pipeline history

**Diagnosis Steps:**

#### Check GitHub Integration
```bash
# Verify CodePipeline source configuration
aws codepipeline get-pipeline --name ECommerce-CICD-Pipeline \
  --query 'pipeline.stages[0].actions[0].configuration'

# Check GitHub webhook delivery
# Go to GitHub → Repository → Settings → Webhooks
# Check recent deliveries and response codes
```

#### Verify AWS Connection
```bash
# Check CodeStar connections
aws codestar-connections list-connections

# Verify connection status
aws codestar-connections get-connection --connection-arn <connection-arn>
```

**Common Solutions:**

1. **Reconnect GitHub Integration:**
   - Go to CodePipeline console
   - Edit pipeline → Edit source stage
   - Reconnect to GitHub with proper permissions

2. **Check Branch Configuration:**
   - Verify pipeline is monitoring correct branch (usually 'main')
   - Ensure branch name matches exactly (case-sensitive)

3. **Webhook Issues:**
   ```bash
   # Re-create webhook if needed
   # Delete existing webhook in GitHub
   # Update pipeline source configuration to recreate webhook
   ```

### Problem: Source stage fails with access denied

**Symptoms:**
- Pipeline starts but source stage fails
- Error messages about repository access
- Authentication or authorization failures

**Solutions:**

1. **Update GitHub Permissions:**
   - Ensure GitHub app has repository access
   - Check organization permissions if repository is in an organization
   - Verify personal access token hasn't expired

2. **AWS IAM Permissions:**
   ```bash
   # Check CodePipeline service role permissions
   aws iam get-role-policy --role-name CodePipelineServiceRole --policy-name <policy-name>
   
   # Ensure role has codestar-connections permissions
   ```

---

## 3. Build Stage Troubleshooting (CodeBuild)

### Problem: Build fails during install phase

**Symptoms:**
- Build starts but fails in install phase
- Dependency installation errors
- Runtime version issues

**Diagnosis:**
```bash
# Check CodeBuild project configuration
aws codebuild batch-get-projects --names ECommerce-Build

# Get detailed build logs
aws codebuild batch-get-builds --ids <build-id>

# View CloudWatch logs
aws logs get-log-events \
  --log-group-name /aws/codebuild/ECommerce-Build \
  --log-stream-name <log-stream-name>
```

**Common Solutions:**

1. **Runtime Version Issues:**
   ```yaml
   # Fix in buildspec.yml
   phases:
     install:
       runtime-versions:
         nodejs: 18  # Ensure supported version
   ```

2. **Dependency Installation:**
   ```yaml
   # Add explicit dependency installation
   phases:
     install:
       commands:
         - yum update -y
         - yum install -y nodejs npm
   ```

3. **Environment Configuration:**
   ```bash
   # Check available runtimes in build environment
   # Update CodeBuild project environment if needed
   aws codebuild update-project \
     --name ECommerce-Build \
     --environment type=LINUX_CONTAINER,image=aws/codebuild/amazonlinux2-x86_64-standard:4.0
   ```

### Problem: Build fails during build phase

**Symptoms:**
- Install phase succeeds but build phase fails
- Test failures or validation errors
- Application-specific build issues

**Diagnosis Framework:**

#### Check buildspec.yml Syntax
```bash
# Validate YAML syntax locally
python -c "import yaml; yaml.safe_load(open('buildspec.yml'))"

# Check for common issues:
# - Incorrect indentation
# - Missing commands
# - Invalid phase names
```

#### Review Build Commands
```yaml
# Common build phase issues in buildspec.yml
build:
  commands:
    # Ensure all commands have proper error handling
    - command1 || exit 1
    - command2 || exit 1
    
    # Check file existence before operations
    - |
      if [ ! -f "src/ecommerce-app/index.html" ]; then
        echo "ERROR: Required file not found"
        exit 1
      fi
```

**Solutions:**

1. **Fix Validation Errors:**
   ```bash
   # HTML validation
   - grep -q "<!DOCTYPE html>" src/ecommerce-app/index.html || (echo "Invalid HTML" && exit 1)
   
   # JavaScript syntax check
   - node -c src/ecommerce-app/script.js || (echo "JS syntax error" && exit 1)
   
   # JSON validation
   - python -m json.tool src/ecommerce-app/products.json > /dev/null || (echo "Invalid JSON" && exit 1)
   ```

2. **Improve Error Handling:**
   ```yaml
   build:
     commands:
       - set -e  # Exit on any error
       - echo "Starting build validation..."
       - |
         # Comprehensive error checking
         for file in index.html styles.css script.js; do
           if [ ! -f "src/ecommerce-app/$file" ]; then
             echo "ERROR: Missing file $file"
             exit 1
           fi
         done
   ```

### Problem: Build succeeds but artifacts are incorrect

**Symptoms:**
- Build phase completes successfully
- Deployment fails due to missing or incorrect files
- Artifact structure issues

**Diagnosis:**
```bash
# Check artifact configuration in buildspec.yml
# Verify S3 bucket contents
aws s3 ls s3://your-artifacts-bucket/ECommerce-Build/ --recursive

# Download and inspect artifacts
aws s3 cp s3://your-artifacts-bucket/ECommerce-Build/latest.zip ./
unzip -l latest.zip
```

**Solutions:**

1. **Fix Artifact Configuration:**
   ```yaml
   artifacts:
     files:
       - '**/*'
     exclude-paths:
       - '.git/**/*'
       - 'node_modules/**/*'
       - '*.md'
     name: ecommerce-build-$(date +%Y-%m-%d-%H-%M-%S)
   ```

2. **Verify File Structure:**
   ```bash
   # Add artifact verification in post_build
   post_build:
     commands:
       - echo "Verifying artifact structure..."
       - find . -type f -not -path "./.git/*" | sort
       - ls -la src/ecommerce-app/
   ```

---

## 4. Deploy Stage Troubleshooting (CodeDeploy)

### Problem: CodeDeploy application not found

**Symptoms:**
- Deploy stage fails immediately
- Error about missing CodeDeploy application
- Configuration issues

**Diagnosis:**
```bash
# Check CodeDeploy application exists
aws deploy list-applications

# Get application details
aws deploy get-application --application-name ECommerce-App

# Check deployment groups
aws deploy list-deployment-groups --application-name ECommerce-App
```

**Solutions:**

1. **Create Missing Application:**
   ```bash
   aws deploy create-application \
     --application-name ECommerce-App \
     --compute-platform EC2
   ```

2. **Verify Deployment Group:**
   ```bash
   # Check deployment group configuration
   aws deploy get-deployment-group \
     --application-name ECommerce-App \
     --deployment-group-name ECommerce-Production
   ```

### Problem: No instances available for deployment

**Symptoms:**
- CodeDeploy starts but finds no target instances
- "No instances found" error messages
- Deployment group configuration issues

**Diagnosis:**
```bash
# Check EC2 instances and tags
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=Production" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags]'

# Verify CodeDeploy agent status
# SSH into instances and check:
sudo service codedeploy-agent status
```

**Solutions:**

1. **Fix Instance Tagging:**
   ```bash
   # Add required tags to EC2 instances
   aws ec2 create-tags \
     --resources i-1234567890abcdef0 \
     --tags Key=Environment,Value=Production
   ```

2. **Install/Start CodeDeploy Agent:**
   ```bash
   # On EC2 instances
   sudo yum install -y ruby wget
   cd /home/ec2-user
   wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
   chmod +x ./install
   sudo ./install auto
   sudo service codedeploy-agent start
   sudo chkconfig codedeploy-agent on
   ```

3. **Update Deployment Group:**
   ```bash
   # Update deployment group with correct tags
   aws deploy update-deployment-group \
     --application-name ECommerce-App \
     --current-deployment-group-name ECommerce-Production \
     --ec2-tag-filters Key=Environment,Value=Production,Type=KEY_AND_VALUE
   ```

### Problem: Deployment fails during application lifecycle events

**Symptoms:**
- Deployment starts but fails during specific lifecycle hooks
- BeforeInstall, ApplicationStart, or ValidateService failures
- Script execution errors

**Diagnosis Framework:**

#### Check Deployment Logs
```bash
# Get deployment details
aws deploy get-deployment --deployment-id <deployment-id>

# Check instance-specific logs
# SSH into EC2 instance
sudo tail -f /var/log/aws/codedeploy-agent/codedeploy-agent.log

# Check deployment logs
sudo ls -la /opt/codedeploy-agent/deployment-root/
sudo cat /opt/codedeploy-agent/deployment-root/<deployment-id>/logs/scripts.log
```

#### Verify appspec.yml Configuration
```yaml
# Check appspec.yml syntax and paths
version: 0.0
os: linux
files:
  - source: /src/ecommerce-app/
    destination: /var/www/html/ecommerce/
    overwrite: yes
permissions:
  - object: /var/www/html/ecommerce/
    owner: nginx
    group: nginx
    mode: 755
hooks:
  BeforeInstall:
    - location: deployment/before_install.sh
      timeout: 300
      runas: root
```

**Common Solutions:**

1. **Fix Script Permissions:**
   ```bash
   # Ensure deployment scripts are executable
   chmod +x deployment/*.sh
   
   # Check script syntax
   bash -n deployment/before_install.sh
   ```

2. **Debug Script Execution:**
   ```bash
   # Add debugging to deployment scripts
   #!/bin/bash
   set -x  # Enable debug output
   set -e  # Exit on error
   
   echo "Starting BeforeInstall at $(date)"
   # ... rest of script
   ```

3. **Verify File Paths:**
   ```bash
   # Check source paths in appspec.yml match artifact structure
   # Verify destination paths exist and are writable
   # Ensure file permissions are correct
   ```

### Problem: Deployment succeeds but application not accessible

**Symptoms:**
- CodeDeploy reports successful deployment
- Application files are deployed correctly
- But application not accessible via load balancer or direct access

**Diagnosis:**

#### Check Application Status
```bash
# SSH into EC2 instances
ssh -i keypair.pem ec2-user@<instance-ip>

# Check nginx status
sudo systemctl status nginx

# Check if nginx is listening
sudo netstat -tlnp | grep :80

# Test local access
curl -I http://localhost/
curl -I http://localhost/health
```

#### Check Load Balancer Health
```bash
# Check ALB target group health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>

# Check ALB configuration
aws elbv2 describe-load-balancers --names ECommerce-ALB
```

**Solutions:**

1. **Fix nginx Configuration:**
   ```bash
   # Check nginx configuration
   sudo nginx -t
   
   # Restart nginx if needed
   sudo systemctl restart nginx
   
   # Check nginx error logs
   sudo tail -f /var/log/nginx/error.log
   ```

2. **Fix Application Files:**
   ```bash
   # Verify file permissions
   sudo chown -R nginx:nginx /var/www/html/ecommerce/
   sudo chmod -R 755 /var/www/html/ecommerce/
   
   # Check file existence
   ls -la /var/www/html/ecommerce/
   ```

3. **Fix Health Check Issues:**
   ```bash
   # Create health check endpoint if missing
   echo "healthy" | sudo tee /var/www/html/ecommerce/health
   
   # Update nginx configuration for health checks
   sudo nano /etc/nginx/conf.d/ecommerce.conf
   ```

---

## 5. Application Runtime Issues

### Problem: Application loads but functionality broken

**Symptoms:**
- Web page loads but JavaScript errors
- Features not working correctly
- Console errors in browser

**Diagnosis:**

#### Check Browser Console
```javascript
// Open browser developer tools (F12)
// Check Console tab for JavaScript errors
// Check Network tab for failed resource loads
// Check Sources tab for file loading issues
```

#### Verify File Loading
```bash
# Check if all files are accessible
curl -I http://<server-ip>/styles.css
curl -I http://<server-ip>/script.js
curl -I http://<server-ip>/products.json

# Check file contents
curl http://<server-ip>/products.json | python -m json.tool
```

**Solutions:**

1. **Fix File Paths:**
   ```html
   <!-- Ensure correct relative paths in HTML -->
   <link rel="stylesheet" href="styles.css">
   <script src="script.js"></script>
   ```

2. **Fix MIME Types:**
   ```nginx
   # In nginx configuration
   location ~* \.css$ {
       add_header Content-Type text/css;
   }
   location ~* \.js$ {
       add_header Content-Type application/javascript;
   }
   ```

3. **Fix CORS Issues:**
   ```nginx
   # Add CORS headers if needed
   add_header Access-Control-Allow-Origin *;
   add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
   ```

### Problem: Performance issues

**Symptoms:**
- Slow page load times
- High server response times
- Poor user experience

**Diagnosis:**
```bash
# Check server performance
top
free -m
df -h

# Test response times
curl -w "@curl-format.txt" -o /dev/null -s http://localhost/

# Create curl-format.txt:
cat > curl-format.txt << 'EOF'
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
EOF
```

**Solutions:**

1. **Optimize nginx Configuration:**
   ```nginx
   # Enable gzip compression
   gzip on;
   gzip_vary on;
   gzip_min_length 1024;
   gzip_comp_level 6;
   
   # Enable caching
   location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
       expires 1y;
       add_header Cache-Control "public, immutable";
   }
   ```

2. **Optimize Application:**
   ```javascript
   // Minimize JavaScript execution
   // Optimize image sizes
   // Use efficient CSS selectors
   // Implement lazy loading
   ```

---

## 6. Infrastructure and Network Issues

### Problem: Security group misconfigurations

**Symptoms:**
- Cannot access application from internet
- Load balancer health checks failing
- SSH access issues

**Diagnosis:**
```bash
# Check security group rules
aws ec2 describe-security-groups \
  --group-names ECommerce-WebServer-SG ECommerce-ALB-SG

# Test connectivity
telnet <instance-ip> 80
telnet <instance-ip> 22
```

**Solutions:**

1. **Fix Web Server Security Group:**
   ```bash
   # Allow HTTP from ALB
   aws ec2 authorize-security-group-ingress \
     --group-id sg-webserver \
     --protocol tcp \
     --port 80 \
     --source-group sg-alb
   
   # Allow SSH from your IP
   aws ec2 authorize-security-group-ingress \
     --group-id sg-webserver \
     --protocol tcp \
     --port 22 \
     --cidr <your-ip>/32
   ```

2. **Fix ALB Security Group:**
   ```bash
   # Allow HTTP from internet
   aws ec2 authorize-security-group-ingress \
     --group-id sg-alb \
     --protocol tcp \
     --port 80 \
     --cidr 0.0.0.0/0
   ```

### Problem: IAM permission issues

**Symptoms:**
- Services cannot access required AWS resources
- "Access Denied" errors in logs
- Pipeline stages failing due to permissions

**Diagnosis:**
```bash
# Check IAM roles and policies
aws iam get-role --role-name CodePipelineServiceRole
aws iam list-attached-role-policies --role-name CodePipelineServiceRole

# Check specific permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::account:role/CodePipelineServiceRole \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::bucket/*
```

**Solutions:**

1. **Add Missing Permissions:**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:GetObject",
           "s3:PutObject",
           "codebuild:BatchGetBuilds",
           "codebuild:StartBuild",
           "codedeploy:CreateDeployment",
           "codedeploy:GetApplication",
           "codedeploy:GetApplicationRevision",
           "codedeploy:GetDeployment",
           "codedeploy:GetDeploymentConfig",
           "codedeploy:RegisterApplicationRevision"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

---

## 7. Monitoring and Alerting Setup

### Comprehensive Monitoring Strategy

#### CloudWatch Alarms for Pipeline Health
```bash
# Pipeline failure alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "Pipeline-Execution-Failures" \
  --alarm-description "Alert on pipeline failures" \
  --metric-name PipelineExecutionFailure \
  --namespace AWS/CodePipeline \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --dimensions Name=PipelineName,Value=ECommerce-CICD-Pipeline

# Build duration alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "Build-Duration-High" \
  --alarm-description "Alert on long build times" \
  --metric-name Duration \
  --namespace AWS/CodeBuild \
  --statistic Average \
  --period 300 \
  --threshold 600 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=ProjectName,Value=ECommerce-Build
```

#### Application Health Monitoring
```bash
# EC2 instance health
aws cloudwatch put-metric-alarm \
  --alarm-name "EC2-High-CPU" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0

# ALB target health
aws cloudwatch put-metric-alarm \
  --alarm-name "ALB-Unhealthy-Targets" \
  --metric-name UnHealthyHostCount \
  --namespace AWS/ApplicationELB \
  --statistic Average \
  --period 60 \
  --threshold 0 \
  --comparison-operator GreaterThanThreshold
```

### Log Analysis and Debugging

#### Centralized Log Analysis
```bash
# CodePipeline logs
aws logs filter-log-events \
  --log-group-name /aws/codepipeline/ECommerce-CICD-Pipeline \
  --filter-pattern "ERROR"

# CodeBuild logs
aws logs filter-log-events \
  --log-group-name /aws/codebuild/ECommerce-Build \
  --filter-pattern "FAILED"

# Application logs
aws logs filter-log-events \
  --log-group-name /aws/ec2/nginx \
  --filter-pattern "[timestamp, request_id, ERROR]"
```

#### Custom Metrics for Business Logic
```javascript
// Custom metrics in application
const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch();

function publishMetric(metricName, value, unit = 'Count') {
    const params = {
        Namespace: 'ECommerce/Application',
        MetricData: [{
            MetricName: metricName,
            Value: value,
            Unit: unit,
            Timestamp: new Date()
        }]
    };
    
    cloudwatch.putMetricData(params, (err, data) => {
        if (err) console.error('Metric error:', err);
    });
}

// Usage
publishMetric('PageViews', 1);
publishMetric('CartAdditions', 1);
publishMetric('CheckoutAttempts', 1);
```

---

## 8. Emergency Procedures and Rollback

### Immediate Response Procedures

#### Pipeline Emergency Stop
```bash
# Stop running pipeline execution
aws codepipeline stop-pipeline-execution \
  --pipeline-name ECommerce-CICD-Pipeline \
  --pipeline-execution-id <execution-id> \
  --abandon

# Stop running CodeBuild
aws codebuild stop-build --id <build-id>

# Stop CodeDeploy deployment
aws deploy stop-deployment --deployment-id <deployment-id> --auto-rollback-enabled
```

#### Quick Rollback Procedures
```bash
# Manual rollback via CodeDeploy
aws deploy create-deployment \
  --application-name ECommerce-App \
  --deployment-group-name ECommerce-Production \
  --s3-location bucket=artifacts-bucket,key=previous-version.zip,bundleType=zip

# Emergency instance replacement
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0
# Launch new instances from launch template
```

### Disaster Recovery

#### Infrastructure Recreation
```bash
# Backup current configuration
aws codepipeline get-pipeline --name ECommerce-CICD-Pipeline > pipeline-backup.json
aws codebuild batch-get-projects --names ECommerce-Build > build-backup.json
aws deploy get-application --application-name ECommerce-App > deploy-backup.json

# Document recovery procedures
# 1. Recreate VPC and security groups
# 2. Launch new EC2 instances
# 3. Recreate CodePipeline, CodeBuild, CodeDeploy
# 4. Restore from last known good state
```

---

## 📊 Troubleshooting Checklist

### Pre-Deployment Checklist
- [ ] GitHub repository accessible and webhook configured
- [ ] CodePipeline service role has required permissions
- [ ] CodeBuild project configuration is correct
- [ ] buildspec.yml syntax is valid
- [ ] CodeDeploy application and deployment group exist
- [ ] EC2 instances are tagged correctly and CodeDeploy agent is running
- [ ] appspec.yml and deployment scripts are correct
- [ ] Security groups allow required traffic
- [ ] Load balancer and target group configured properly

### Post-Deployment Checklist
- [ ] Pipeline execution completed successfully
- [ ] All stages show green status
- [ ] Application accessible via load balancer
- [ ] Health checks passing
- [ ] No errors in application logs
- [ ] Performance metrics within acceptable ranges
- [ ] Monitoring and alerts configured
- [ ] Rollback procedures tested and documented

### Performance Checklist
- [ ] Build time under 5 minutes
- [ ] Deployment time under 10 minutes
- [ ] Application response time under 2 seconds
- [ ] No memory leaks or resource exhaustion
- [ ] Error rates under 1%
- [ ] All health checks passing consistently

This comprehensive troubleshooting guide provides systematic approaches to diagnosing and resolving issues in CI/CD pipelines, ensuring reliable and efficient software delivery.
