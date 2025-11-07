#!/bin/bash

# CI/CD E-Commerce Pipeline Cleanup Script
# This script helps identify and clean up resources created for the project

set -e  # Exit on any error

# Configuration
PROJECT_NAME="cicd-ecommerce-pipeline"
REGION="us-east-1"

echo "🧹 CI/CD E-Commerce Pipeline Cleanup Helper"
echo "============================================"
echo "Project: $PROJECT_NAME"
echo "Region: $REGION"
echo ""

# Warning message
echo "⚠️  WARNING: This will help you identify and delete resources created for the CI/CD pipeline project!"
echo ""
echo "Resources that may need cleanup:"
echo "- CodePipeline and associated executions"
echo "- CodeBuild projects and build history"
echo "- CodeDeploy applications and deployments"
echo "- EC2 instances and launch templates"
echo "- Application Load Balancer and target groups"
echo "- S3 buckets for artifacts"
echo "- IAM roles and policies"
echo "- VPC and associated networking components"
echo "- CloudWatch log groups and alarms"
echo ""

read -p "Do you want to proceed with the cleanup helper? (yes/no): " confirm

if [[ $confirm != "yes" ]]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

echo ""
echo "🔍 Scanning for resources to cleanup..."
echo ""

# Function to cleanup CodePipeline
cleanup_codepipeline() {
    echo "🔄 CodePipeline:"
    echo "================"
    
    PIPELINES=$(aws codepipeline list-pipelines \
        --query 'pipelines[?contains(name, `ECommerce`)].[name]' \
        --output text 2>/dev/null || echo "")
    
    if [[ -n "$PIPELINES" ]]; then
        echo "Found CodePipelines:"
        for pipeline in $PIPELINES; do
            echo "  - $pipeline"
            
            # Show recent executions
            echo "    Recent executions:"
            aws codepipeline list-pipeline-executions \
                --pipeline-name "$pipeline" \
                --max-items 3 \
                --query 'pipelineExecutionSummaries[].[pipelineExecutionId,status,startTime]' \
                --output table 2>/dev/null || echo "    No executions found"
        done
        echo ""
        
        read -p "Delete these CodePipelines? (yes/no): " delete_pipelines
        if [[ $delete_pipelines == "yes" ]]; then
            for pipeline in $PIPELINES; do
                echo "🗑️  Deleting pipeline: $pipeline"
                
                # Stop any running executions first
                RUNNING_EXECUTIONS=$(aws codepipeline list-pipeline-executions \
                    --pipeline-name "$pipeline" \
                    --query 'pipelineExecutionSummaries[?status==`InProgress`].pipelineExecutionId' \
                    --output text 2>/dev/null || echo "")
                
                for execution in $RUNNING_EXECUTIONS; do
                    echo "   Stopping execution: $execution"
                    aws codepipeline stop-pipeline-execution \
                        --pipeline-name "$pipeline" \
                        --pipeline-execution-id "$execution" \
                        --abandon 2>/dev/null || echo "   Could not stop execution"
                done
                
                # Delete the pipeline
                aws codepipeline delete-pipeline --name "$pipeline" >/dev/null
            done
            echo "✅ CodePipelines deleted"
        fi
    else
        echo "No CodePipelines found with ECommerce prefix"
    fi
    echo ""
}

# Function to cleanup CodeBuild projects
cleanup_codebuild() {
    echo "🔨 CodeBuild Projects:"
    echo "====================="
    
    PROJECTS=$(aws codebuild list-projects \
        --query 'projects[?contains(@, `ECommerce`)]' \
        --output text 2>/dev/null || echo "")
    
    if [[ -n "$PROJECTS" ]]; then
        echo "Found CodeBuild projects:"
        for project in $PROJECTS; do
            echo "  - $project"
            
            # Show recent builds
            echo "    Recent builds:"
            aws codebuild list-builds-for-project \
                --project-name "$project" \
                --sort-order DESCENDING \
                --query 'ids[0:3]' \
                --output table 2>/dev/null || echo "    No builds found"
        done
        echo ""
        
        read -p "Delete these CodeBuild projects? (yes/no): " delete_projects
        if [[ $delete_projects == "yes" ]]; then
            for project in $PROJECTS; do
                echo "🗑️  Deleting CodeBuild project: $project"
                
                # Stop any running builds first
                RUNNING_BUILDS=$(aws codebuild list-builds-for-project \
                    --project-name "$project" \
                    --query 'ids' \
                    --output text 2>/dev/null || echo "")
                
                if [[ -n "$RUNNING_BUILDS" ]]; then
                    for build in $RUNNING_BUILDS; do
                        BUILD_STATUS=$(aws codebuild batch-get-builds \
                            --ids "$build" \
                            --query 'builds[0].buildStatus' \
                            --output text 2>/dev/null || echo "")
                        
                        if [[ "$BUILD_STATUS" == "IN_PROGRESS" ]]; then
                            echo "   Stopping build: $build"
                            aws codebuild stop-build --id "$build" >/dev/null 2>&1 || echo "   Could not stop build"
                        fi
                    done
                fi
                
                # Delete the project
                aws codebuild delete-project --name "$project" >/dev/null
            done
            echo "✅ CodeBuild projects deleted"
        fi
    else
        echo "No CodeBuild projects found with ECommerce prefix"
    fi
    echo ""
}

# Function to cleanup CodeDeploy applications
cleanup_codedeploy() {
    echo "🚀 CodeDeploy Applications:"
    echo "=========================="
    
    APPLICATIONS=$(aws deploy list-applications \
        --query 'applications[?contains(@, `ECommerce`)]' \
        --output text 2>/dev/null || echo "")
    
    if [[ -n "$APPLICATIONS" ]]; then
        echo "Found CodeDeploy applications:"
        for app in $APPLICATIONS; do
            echo "  - $app"
            
            # Show deployment groups
            DEPLOYMENT_GROUPS=$(aws deploy list-deployment-groups \
                --application-name "$app" \
                --query 'deploymentGroups' \
                --output text 2>/dev/null || echo "")
            
            if [[ -n "$DEPLOYMENT_GROUPS" ]]; then
                echo "    Deployment groups:"
                for dg in $DEPLOYMENT_GROUPS; do
                    echo "      - $dg"
                done
            fi
            
            # Show recent deployments
            echo "    Recent deployments:"
            aws deploy list-deployments \
                --application-name "$app" \
                --max-items 3 \
                --query 'deployments' \
                --output table 2>/dev/null || echo "    No deployments found"
        done
        echo ""
        
        read -p "Delete these CodeDeploy applications? (yes/no): " delete_apps
        if [[ $delete_apps == "yes" ]]; then
            for app in $APPLICATIONS; do
                echo "🗑️  Deleting CodeDeploy application: $app"
                
                # Stop any running deployments first
                RUNNING_DEPLOYMENTS=$(aws deploy list-deployments \
                    --application-name "$app" \
                    --include-only-statuses InProgress \
                    --query 'deployments' \
                    --output text 2>/dev/null || echo "")
                
                for deployment in $RUNNING_DEPLOYMENTS; do
                    echo "   Stopping deployment: $deployment"
                    aws deploy stop-deployment \
                        --deployment-id "$deployment" \
                        --auto-rollback-enabled 2>/dev/null || echo "   Could not stop deployment"
                done
                
                # Delete the application (this also deletes deployment groups)
                aws deploy delete-application --application-name "$app" >/dev/null
            done
            echo "✅ CodeDeploy applications deleted"
        fi
    else
        echo "No CodeDeploy applications found with ECommerce prefix"
    fi
    echo ""
}

# Function to cleanup EC2 instances
cleanup_ec2_instances() {
    echo "💻 EC2 Instances:"
    echo "================="
    
    INSTANCES=$(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running,stopped" \
        --query 'Reservations[].Instances[?Tags[?Key==`Name` && contains(Value, `ECommerce`)]].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' \
        --output text 2>/dev/null || echo "")
    
    if [[ -n "$INSTANCES" ]]; then
        echo "Found EC2 instances:"
        echo "$INSTANCES" | while read -r instance_id state name; do
            echo "  - $name ($instance_id) - $state"
        done
        echo ""
        
        read -p "Terminate these EC2 instances? (yes/no): " terminate_instances
        if [[ $terminate_instances == "yes" ]]; then
            echo "$INSTANCES" | while read -r instance_id state name; do
                echo "🗑️  Terminating instance: $name ($instance_id)"
                aws ec2 terminate-instances --instance-ids "$instance_id" >/dev/null
            done
            echo "✅ EC2 instances termination initiated"
        fi
    else
        echo "No EC2 instances found with ECommerce tag"
    fi
    echo ""
}

# Function to cleanup Launch Templates
cleanup_launch_templates() {
    echo "🚀 Launch Templates:"
    echo "==================="
    
    TEMPLATES=$(aws ec2 describe-launch-templates \
        --query 'LaunchTemplates[?contains(LaunchTemplateName, `ECommerce`)].[LaunchTemplateId,LaunchTemplateName]' \
        --output text 2>/dev/null || echo "")
    
    if [[ -n "$TEMPLATES" ]]; then
        echo "Found Launch Templates:"
        echo "$TEMPLATES" | while read -r template_id template_name; do
            echo "  - $template_name ($template_id)"
        done
        echo ""
        
        read -p "Delete these Launch Templates? (yes/no): " delete_templates
        if [[ $delete_templates == "yes" ]]; then
            echo "$TEMPLATES" | while read -r template_id template_name; do
                echo "🗑️  Deleting Launch Template: $template_name"
                aws ec2 delete-launch-template --launch-template-id "$template_id" >/dev/null
            done
            echo "✅ Launch Templates deleted"
        fi
    else
        echo "No Launch Templates found with ECommerce prefix"
    fi
    echo ""
}

# Function to cleanup Load Balancers
cleanup_load_balancers() {
    echo "⚖️  Application Load Balancers:"
    echo "=============================="
    
    ALBS=$(aws elbv2 describe-load-balancers \
        --query 'LoadBalancers[?contains(LoadBalancerName, `ECommerce`)].[LoadBalancerArn,LoadBalancerName,State.Code]' \
        --output text 2>/dev/null || echo "")
    
    if [[ -n "$ALBS" ]]; then
        echo "Found Load Balancers:"
        echo "$ALBS" | while read -r alb_arn alb_name state; do
            echo "  - $alb_name - $state"
        done
        echo ""
        
        read -p "Delete these Load Balancers? (yes/no): " delete_alb
        if [[ $delete_alb == "yes" ]]; then
            echo "$ALBS" | while read -r alb_arn alb_name state; do
                echo "🗑️  Deleting Load Balancer: $alb_name"
                aws elbv2 delete-load-balancer --load-balancer-arn "$alb_arn" >/dev/null
            done
            echo "✅ Load Balancers deletion initiated"
        fi
    else
        echo "No Load Balancers found with ECommerce prefix"
    fi
    
    # Target Groups
    TGS=$(aws elbv2 describe-target-groups \
        --query 'TargetGroups[?contains(TargetGroupName, `ECommerce`)].[TargetGroupArn,TargetGroupName]' \
        --output text 2>/dev/null || echo "")
    
    if [[ -n "$TGS" ]]; then
        echo ""
        echo "Found Target Groups:"
        echo "$TGS" | while read -r tg_arn tg_name; do
            echo "  - $tg_name"
        done
        echo ""
        
        read -p "Delete these Target Groups? (yes/no): " delete_tg
        if [[ $delete_tg == "yes" ]]; then
            echo "$TGS" | while read -r tg_arn tg_name; do
                echo "🗑️  Deleting Target Group: $tg_name"
                aws elbv2 delete-target-group --target-group-arn "$tg_arn" >/dev/null
            done
            echo "✅ Target Groups deleted"
        fi
    fi
    echo ""
}

# Function to cleanup S3 buckets
cleanup_s3_buckets() {
    echo "📦 S3 Buckets:"
    echo "=============="
    
    BUCKETS=$(aws s3api list-buckets \
        --query 'Buckets[?contains(Name, `ecommerce`) && contains(Name, `artifacts`)].[Name,CreationDate]' \
        --output text 2>/dev/null || echo "")
    
    if [[ -n "$BUCKETS" ]]; then
        echo "Found S3 buckets (artifacts):"
        echo "$BUCKETS" | while read -r bucket_name creation_date; do
            echo "  - $bucket_name (created: $creation_date)"
            
            # Show bucket size
            BUCKET_SIZE=$(aws s3 ls s3://"$bucket_name" --recursive --summarize 2>/dev/null | grep "Total Size" | awk '{print $3, $4}' || echo "Unknown")
            echo "    Size: $BUCKET_SIZE"
        done
        echo ""
        
        read -p "Delete these S3 buckets and all contents? (yes/no): " delete_buckets
        if [[ $delete_buckets == "yes" ]]; then
            echo "$BUCKETS" | while read -r bucket_name creation_date; do
                echo "🗑️  Emptying and deleting bucket: $bucket_name"
                
                # Empty bucket first
                aws s3 rm s3://"$bucket_name" --recursive 2>/dev/null || echo "   Bucket already empty or error occurred"
                
                # Delete bucket
                aws s3 rb s3://"$bucket_name" 2>/dev/null || echo "   Could not delete bucket (may have dependencies)"
            done
            echo "✅ S3 buckets cleanup attempted"
        fi
    else
        echo "No S3 buckets found with ecommerce-artifacts pattern"
    fi
    echo ""
}

# Function to cleanup IAM roles
cleanup_iam_roles() {
    echo "🔐 IAM Roles:"
    echo "============"
    
    ROLES=$(aws iam list-roles \
        --query 'Roles[?contains(RoleName, `CodePipeline`) || contains(RoleName, `CodeBuild`) || contains(RoleName, `CodeDeploy`) || contains(RoleName, `EC2CodeDeploy`)].[RoleName,CreateDate]' \
        --output text 2>/dev/null || echo "")
    
    if [[ -n "$ROLES" ]]; then
        echo "Found IAM roles:"
        echo "$ROLES" | while read -r role_name create_date; do
            echo "  - $role_name (created: $create_date)"
        done
        echo ""
        
        read -p "Delete these IAM roles? (yes/no): " delete_roles
        if [[ $delete_roles == "yes" ]]; then
            echo "$ROLES" | while read -r role_name create_date; do
                echo "🗑️  Detaching policies and deleting role: $role_name"
                
                # Detach managed policies
                ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name "$role_name" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null || echo "")
                for policy_arn in $ATTACHED_POLICIES; do
                    aws iam detach-role-policy --role-name "$role_name" --policy-arn "$policy_arn" 2>/dev/null || true
                done
                
                # Delete inline policies
                INLINE_POLICIES=$(aws iam list-role-policies --role-name "$role_name" --query 'PolicyNames' --output text 2>/dev/null || echo "")
                for policy_name in $INLINE_POLICIES; do
                    aws iam delete-role-policy --role-name "$role_name" --policy-name "$policy_name" 2>/dev/null || true
                done
                
                # Remove role from instance profiles
                INSTANCE_PROFILES=$(aws iam list-instance-profiles-for-role --role-name "$role_name" --query 'InstanceProfiles[].InstanceProfileName' --output text 2>/dev/null || echo "")
                for profile_name in $INSTANCE_PROFILES; do
                    aws iam remove-role-from-instance-profile --instance-profile-name "$profile_name" --role-name "$role_name" 2>/dev/null || true
                done
                
                # Delete the role
                aws iam delete-role --role-name "$role_name" 2>/dev/null || echo "   ⚠️  Could not delete $role_name (may have dependencies)"
            done
            echo "✅ IAM roles cleanup attempted"
        fi
    else
        echo "No IAM roles found with CodePipeline, CodeBuild, or CodeDeploy prefixes"
    fi
    echo ""
}

# Function to cleanup Security Groups
cleanup_security_groups() {
    echo "🔒 Security Groups:"
    echo "=================="
    
    SGS=$(aws ec2 describe-security-groups \
        --query 'SecurityGroups[?GroupName!=`default` && contains(GroupName, `ECommerce`)].[GroupId,GroupName,VpcId]' \
        --output text 2>/dev/null || echo "")
    
    if [[ -n "$SGS" ]]; then
        echo "Found Security Groups:"
        echo "$SGS" | while read -r sg_id sg_name vpc_id; do
            echo "  - $sg_name ($sg_id) in $vpc_id"
        done
        echo ""
        echo "⚠️  Note: Security groups will be deleted after other resources are removed"
        read -p "Delete these Security Groups? (yes/no): " delete_sg
        if [[ $delete_sg == "yes" ]]; then
            echo "Waiting 60 seconds for other resources to be deleted..."
            sleep 60
            echo "$SGS" | while read -r sg_id sg_name vpc_id; do
                echo "🗑️  Deleting Security Group: $sg_name"
                aws ec2 delete-security-group --group-id "$sg_id" 2>/dev/null || echo "   ⚠️  Could not delete $sg_name (may have dependencies)"
            done
            echo "✅ Security Groups cleanup attempted"
        fi
    else
        echo "No custom Security Groups found with ECommerce prefix"
    fi
    echo ""
}

# Function to cleanup CloudWatch resources
cleanup_cloudwatch() {
    echo "📊 CloudWatch Resources:"
    echo "======================="
    
    # Log Groups
    LOG_GROUPS=$(aws logs describe-log-groups \
        --query 'logGroups[?contains(logGroupName, `codebuild`) || contains(logGroupName, `codepipeline`) || contains(logGroupName, `ecommerce`)].[logGroupName]' \
        --output text 2>/dev/null || echo "")
    
    if [[ -n "$LOG_GROUPS" ]]; then
        echo "Found Log Groups:"
        for log_group in $LOG_GROUPS; do
            echo "  - $log_group"
        done
        echo ""
        read -p "Delete these Log Groups? (yes/no): " delete_logs
        if [[ $delete_logs == "yes" ]]; then
            for log_group in $LOG_GROUPS; do
                echo "🗑️  Deleting Log Group: $log_group"
                aws logs delete-log-group --log-group-name "$log_group" 2>/dev/null || echo "   ⚠️  Could not delete $log_group"
            done
            echo "✅ Log Groups deleted"
        fi
    else
        echo "No Log Groups found with relevant prefixes"
    fi
    
    # CloudWatch Alarms
    ALARMS=$(aws cloudwatch describe-alarms \
        --query 'MetricAlarms[?contains(AlarmName, `ECommerce`) || contains(AlarmName, `Pipeline`) || contains(AlarmName, `Build`)].AlarmName' \
        --output text 2>/dev/null || echo "")
    
    if [[ -n "$ALARMS" ]]; then
        echo ""
        echo "Found CloudWatch Alarms:"
        for alarm in $ALARMS; do
            echo "  - $alarm"
        done
        echo ""
        read -p "Delete these Alarms? (yes/no): " delete_alarms
        if [[ $delete_alarms == "yes" ]]; then
            aws cloudwatch delete-alarms --alarm-names $ALARMS
            echo "✅ CloudWatch Alarms deleted"
        fi
    else
        echo "No CloudWatch Alarms found with relevant prefixes"
    fi
    echo ""
}

# Function to cleanup VPC
cleanup_vpc() {
    echo "🌐 VPC and Networking:"
    echo "====================="
    
    VPCS=$(aws ec2 describe-vpcs \
        --query 'Vpcs[?Tags[?Key==`Name` && contains(Value, `ECommerce`)]].[VpcId,Tags[?Key==`Name`].Value|[0]]' \
        --output text 2>/dev/null || echo "")
    
    if [[ -n "$VPCS" ]]; then
        echo "Found VPCs:"
        echo "$VPCS" | while read -r vpc_id vpc_name; do
            echo "  - $vpc_name ($vpc_id)"
        done
        echo ""
        echo "⚠️  VPC deletion will also delete:"
        echo "   - Subnets"
        echo "   - Route Tables"
        echo "   - Internet Gateways"
        echo "   - NAT Gateways"
        echo "   - Network ACLs"
        echo ""
        read -p "Delete the VPC and all associated resources? (yes/no): " delete_vpc
        if [[ $delete_vpc == "yes" ]]; then
            echo "$VPCS" | while read -r vpc_id vpc_name; do
                echo "🗑️  Deleting VPC: $vpc_name ($vpc_id)"
                echo "   This may take several minutes..."
                
                # Delete NAT Gateways first
                NAT_GWS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$vpc_id" --query 'NatGateways[?State==`available`].NatGatewayId' --output text)
                for nat_gw in $NAT_GWS; do
                    echo "   🗑️  Deleting NAT Gateway: $nat_gw"
                    aws ec2 delete-nat-gateway --nat-gateway-id "$nat_gw" >/dev/null
                done
                
                # Wait for NAT Gateways to be deleted
                if [[ -n "$NAT_GWS" ]]; then
                    echo "   ⏳ Waiting for NAT Gateways to be deleted..."
                    sleep 60
                fi
                
                # Delete VPC
                aws ec2 delete-vpc --vpc-id "$vpc_id" 2>/dev/null || echo "   ⚠️  Could not delete VPC (may have dependencies)"
            done
            echo "✅ VPC deletion initiated"
        fi
    else
        echo "No VPCs found with ECommerce tag"
    fi
    echo ""
}

# Main cleanup sequence
echo "Starting cleanup process..."
echo ""

# Cleanup in proper order to handle dependencies
cleanup_codepipeline
cleanup_codebuild
cleanup_codedeploy
cleanup_ec2_instances
cleanup_launch_templates
cleanup_load_balancers
cleanup_s3_buckets

# Wait a bit for resources to be deleted
echo "⏳ Waiting 30 seconds for resources to be deleted..."
sleep 30

cleanup_iam_roles
cleanup_security_groups
cleanup_cloudwatch
cleanup_vpc

echo ""
echo "🎉 Cleanup process completed!"
echo "============================="
echo ""
echo "🔍 Verification Steps:"
echo "1. Check CodePipeline console - pipelines should be deleted"
echo "2. Check CodeBuild console - projects should be deleted"
echo "3. Check CodeDeploy console - applications should be deleted"
echo "4. Check EC2 console - instances should be terminated"
echo "5. Check ALB console - load balancers should be deleted"
echo "6. Check S3 console - artifact buckets should be deleted"
echo "7. Check IAM console - custom roles should be deleted"
echo "8. Check VPC console - custom VPC should be deleted"
echo "9. Check billing dashboard - charges should stop accruing"
echo ""
echo "💰 Cost Verification:"
echo "- Monitor your AWS bill for the next few days"
echo "- All resources should show $0.00 charges after cleanup"
echo "- If you see ongoing charges, check for missed resources"
echo ""
echo "⚠️  Manual Cleanup Required:"
echo "- GitHub repository (if you want to delete it)"
echo "- GitHub personal access tokens (revoke if no longer needed)"
echo "- Any custom CloudWatch dashboards"
echo "- Resources in other regions"
echo ""
echo "🎯 Final Steps:"
echo "1. Review AWS billing dashboard"
echo "2. Check for any remaining resources in other regions"
echo "3. Consider setting up billing alerts for future projects"
echo "4. Revoke GitHub personal access tokens if no longer needed"
echo ""
echo "Thank you for using the CI/CD E-Commerce Pipeline project!"
