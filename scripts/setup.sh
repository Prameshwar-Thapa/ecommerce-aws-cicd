#!/bin/bash

# CI/CD E-Commerce Pipeline Setup Helper Script
# This script provides guidance and helper commands for setting up the pipeline

set -e  # Exit on any error

# Configuration
PROJECT_NAME="cicd-ecommerce-pipeline"
REGION="us-east-1"

echo "🚀 CI/CD E-Commerce Pipeline Setup Helper"
echo "=========================================="
echo "Project: $PROJECT_NAME"
echo "Region: $REGION"
echo ""

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

echo "📋 Setup Checklist:"
echo "==================="
echo ""
echo "This script will guide you through the CI/CD pipeline setup process."
echo "Follow the aws-console-guide.md for detailed step-by-step instructions."
echo ""

echo "1. ✅ Infrastructure Setup"
echo "   - Create VPC with public subnets"
echo "   - Configure Security Groups"
echo "   - Launch EC2 instances with CodeDeploy agent"
echo ""

echo "2. ✅ Source Control Setup"
echo "   - Create GitHub repository"
echo "   - Configure GitHub personal access token"
echo "   - Push application code to repository"
echo ""

echo "3. ✅ IAM Roles Configuration"
echo "   - CodePipeline service role"
echo "   - CodeBuild service role"
echo "   - CodeDeploy service role"
echo "   - EC2 instance profile"
echo ""

echo "4. ✅ CodeDeploy Setup"
echo "   - Create CodeDeploy application"
echo "   - Configure deployment group"
echo "   - Test CodeDeploy agent on EC2 instances"
echo ""

echo "5. ✅ CodeBuild Setup"
echo "   - Create S3 bucket for artifacts"
echo "   - Create CodeBuild project"
echo "   - Configure buildspec.yml"
echo ""

echo "6. ✅ CodePipeline Setup"
echo "   - Create pipeline with source, build, and deploy stages"
echo "   - Configure GitHub integration"
echo "   - Test end-to-end pipeline"
echo ""

echo "🔧 Helper Commands:"
echo "=================="
echo ""

# Function to check VPC configuration
check_vpc() {
    echo "Checking VPC configuration..."
    aws ec2 describe-vpcs --query 'Vpcs[?Tags[?Key==`Name` && contains(Value, `ECommerce`)]].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table
}

# Function to check EC2 instances
check_ec2_instances() {
    echo "Checking EC2 instances..."
    aws ec2 describe-instances --query 'Reservations[].Instances[?Tags[?Key==`Name` && contains(Value, `ECommerce`)]].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' --output table
}

# Function to check CodeDeploy setup
check_codedeploy() {
    echo "Checking CodeDeploy configuration..."
    echo "Applications:"
    aws deploy list-applications --output table
    
    echo ""
    echo "Deployment Groups:"
    aws deploy list-deployment-groups --application-name ECommerce-App --output table 2>/dev/null || echo "No deployment groups found or application doesn't exist"
}

# Function to check CodeBuild projects
check_codebuild() {
    echo "Checking CodeBuild projects..."
    aws codebuild list-projects --query 'projects[?contains(@, `ECommerce`)]' --output table
}

# Function to check CodePipeline
check_codepipeline() {
    echo "Checking CodePipeline..."
    aws codepipeline list-pipelines --query 'pipelines[?contains(name, `ECommerce`)].[name,created,updated]' --output table
}

# Function to check IAM roles
check_iam_roles() {
    echo "Checking IAM roles..."
    aws iam list-roles --query 'Roles[?contains(RoleName, `CodePipeline`) || contains(RoleName, `CodeBuild`) || contains(RoleName, `CodeDeploy`) || contains(RoleName, `EC2CodeDeploy`)].[RoleName,CreateDate]' --output table
}

# Function to test CodeDeploy agent
test_codedeploy_agent() {
    echo "Testing CodeDeploy agent on EC2 instances..."
    
    # Get EC2 instances
    INSTANCES=$(aws ec2 describe-instances \
        --filters "Name=tag:Environment,Values=Production" "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress]' \
        --output text)
    
    if [ -z "$INSTANCES" ]; then
        echo "No running EC2 instances found with Environment=Production tag"
        return 1
    fi
    
    echo "Found instances:"
    echo "$INSTANCES"
    echo ""
    
    read -p "Do you want to test CodeDeploy agent on these instances? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "To test CodeDeploy agent, SSH into each instance and run:"
        echo "sudo service codedeploy-agent status"
        echo ""
        echo "If not running, start it with:"
        echo "sudo service codedeploy-agent start"
        echo "sudo chkconfig codedeploy-agent on"
    fi
}

# Function to create sample GitHub repository structure
create_github_structure() {
    echo "Creating sample GitHub repository structure..."
    
    read -p "Enter your GitHub username: " github_username
    read -p "Enter repository name (default: ecommerce-cicd-pipeline): " repo_name
    repo_name=${repo_name:-ecommerce-cicd-pipeline}
    
    echo ""
    echo "📋 GitHub Repository Setup Instructions:"
    echo "========================================"
    echo "1. Create a new repository on GitHub:"
    echo "   - Go to https://github.com/new"
    echo "   - Repository name: $repo_name"
    echo "   - Make it public or private as needed"
    echo "   - Initialize with README"
    echo ""
    echo "2. Clone the repository locally:"
    echo "   git clone https://github.com/$github_username/$repo_name.git"
    echo "   cd $repo_name"
    echo ""
    echo "3. Copy the project files to your repository:"
    echo "   cp -r /path/to/this/project/* ."
    echo "   git add ."
    echo "   git commit -m 'Initial commit: Add e-commerce application and CI/CD configuration'"
    echo "   git push origin main"
    echo ""
    echo "4. Create GitHub Personal Access Token:"
    echo "   - Go to GitHub Settings → Developer settings → Personal access tokens"
    echo "   - Generate new token with 'repo' and 'admin:repo_hook' permissions"
    echo "   - Save the token securely for CodePipeline configuration"
}

# Function to validate buildspec.yml
validate_buildspec() {
    echo "Validating buildspec.yml..."
    
    if [ -f "buildspec.yml" ]; then
        echo "✅ buildspec.yml found"
        
        # Check YAML syntax
        if command -v python3 &> /dev/null; then
            python3 -c "import yaml; yaml.safe_load(open('buildspec.yml'))" 2>/dev/null && echo "✅ YAML syntax is valid" || echo "❌ YAML syntax error"
        fi
        
        # Check required sections
        grep -q "version:" buildspec.yml && echo "✅ Version specified" || echo "❌ Missing version"
        grep -q "phases:" buildspec.yml && echo "✅ Phases section found" || echo "❌ Missing phases section"
        grep -q "artifacts:" buildspec.yml && echo "✅ Artifacts section found" || echo "❌ Missing artifacts section"
        
    else
        echo "❌ buildspec.yml not found in current directory"
        echo "Make sure you're in the project root directory"
    fi
}

# Function to validate appspec.yml
validate_appspec() {
    echo "Validating appspec.yml..."
    
    if [ -f "appspec.yml" ]; then
        echo "✅ appspec.yml found"
        
        # Check YAML syntax
        if command -v python3 &> /dev/null; then
            python3 -c "import yaml; yaml.safe_load(open('appspec.yml'))" 2>/dev/null && echo "✅ YAML syntax is valid" || echo "❌ YAML syntax error"
        fi
        
        # Check required sections
        grep -q "version:" appspec.yml && echo "✅ Version specified" || echo "❌ Missing version"
        grep -q "files:" appspec.yml && echo "✅ Files section found" || echo "❌ Missing files section"
        grep -q "hooks:" appspec.yml && echo "✅ Hooks section found" || echo "❌ Missing hooks section"
        
        # Check deployment scripts exist
        if [ -d "deployment" ]; then
            echo "✅ Deployment directory found"
            for script in before_install.sh application_stop.sh application_start.sh validate_service.sh; do
                if [ -f "deployment/$script" ]; then
                    echo "✅ $script found"
                    if [ -x "deployment/$script" ]; then
                        echo "✅ $script is executable"
                    else
                        echo "⚠️  $script is not executable (run: chmod +x deployment/$script)"
                    fi
                else
                    echo "❌ $script not found"
                fi
            done
        else
            echo "❌ Deployment directory not found"
        fi
        
    else
        echo "❌ appspec.yml not found in current directory"
    fi
}

# Function to test pipeline end-to-end
test_pipeline() {
    echo "Testing pipeline end-to-end..."
    
    # Check if pipeline exists
    PIPELINE_EXISTS=$(aws codepipeline get-pipeline --name ECommerce-CICD-Pipeline 2>/dev/null && echo "true" || echo "false")
    
    if [ "$PIPELINE_EXISTS" = "true" ]; then
        echo "✅ Pipeline exists"
        
        # Get pipeline status
        echo "📊 Pipeline Status:"
        aws codepipeline get-pipeline-state --name ECommerce-CICD-Pipeline --query 'stageStates[].[stageName,latestExecution.status]' --output table
        
        read -p "Do you want to start a new pipeline execution? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🚀 Starting pipeline execution..."
            EXECUTION_ID=$(aws codepipeline start-pipeline-execution --name ECommerce-CICD-Pipeline --query 'pipelineExecutionId' --output text)
            echo "Pipeline execution started with ID: $EXECUTION_ID"
            echo "Monitor progress in AWS Console: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/ECommerce-CICD-Pipeline/view"
        fi
    else
        echo "❌ Pipeline not found. Please create the pipeline first."
    fi
}

# Interactive menu
while true; do
    echo ""
    echo "Choose an option:"
    echo "1. Check VPC configuration"
    echo "2. Check EC2 instances"
    echo "3. Check IAM roles"
    echo "4. Check CodeDeploy setup"
    echo "5. Check CodeBuild projects"
    echo "6. Check CodePipeline"
    echo "7. Test CodeDeploy agent"
    echo "8. GitHub repository setup guide"
    echo "9. Validate buildspec.yml"
    echo "10. Validate appspec.yml"
    echo "11. Test pipeline end-to-end"
    echo "12. Exit"
    echo ""
    read -p "Enter your choice (1-12): " choice

    case $choice in
        1)
            check_vpc
            ;;
        2)
            check_ec2_instances
            ;;
        3)
            check_iam_roles
            ;;
        4)
            check_codedeploy
            ;;
        5)
            check_codebuild
            ;;
        6)
            check_codepipeline
            ;;
        7)
            test_codedeploy_agent
            ;;
        8)
            create_github_structure
            ;;
        9)
            validate_buildspec
            ;;
        10)
            validate_appspec
            ;;
        11)
            test_pipeline
            ;;
        12)
            echo "Exiting setup helper..."
            break
            ;;
        *)
            echo "Invalid option. Please choose 1-12."
            ;;
    esac
done

echo ""
echo "📚 Next Steps:"
echo "=============="
echo "1. Follow the detailed guide in aws-console-guide.md"
echo "2. Use the AWS Console to create resources manually"
echo "3. Test each component as you build it"
echo "4. Monitor costs in the AWS Billing dashboard"
echo ""
echo "🔗 Useful Links:"
echo "- AWS Console: https://console.aws.amazon.com"
echo "- CodePipeline: https://console.aws.amazon.com/codesuite/codepipeline"
echo "- CodeBuild: https://console.aws.amazon.com/codesuite/codebuild"
echo "- CodeDeploy: https://console.aws.amazon.com/codesuite/codedeploy"
echo "- EC2: https://console.aws.amazon.com/ec2"
echo ""
echo "💡 Tips:"
echo "- Always test each stage of the pipeline individually"
echo "- Monitor CloudWatch logs for detailed error information"
echo "- Keep your GitHub personal access token secure"
echo "- Use tags consistently for resource management"
echo ""
echo "🧹 Cleanup:"
echo "Run './cleanup.sh' when you're done to delete all resources"
