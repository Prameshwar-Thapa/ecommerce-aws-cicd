#!/bin/bash

set -e  # Exit on any error

echo "Starting application_start phase..."

# Get AWS region and account ID with better error handling
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region || echo "us-east-1")
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region $AWS_REGION)

echo "Using AWS Region: $AWS_REGION"
echo "Using AWS Account ID: $AWS_ACCOUNT_ID"

# ECR repository name (should match your ECR repo)
IMAGE_REPO_NAME="ecommerce-app"
IMAGE_TAG="latest"

# Check if ECR repository exists
echo "Checking ECR repository..."
if ! aws ecr describe-repositories --repository-names $IMAGE_REPO_NAME --region $AWS_REGION >/dev/null 2>&1; then
    echo "❌ ECR repository $IMAGE_REPO_NAME does not exist"
    exit 1
fi

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | sudo docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Pull the latest image from ECR
echo "Pulling Docker image from ECR..."
sudo docker pull $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG

# Run the container
echo "Starting Docker container..."
sudo docker run -d \
  --name ecommerce-app \
  -p 80:80 \
  --restart unless-stopped \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG

# Pull the latest image from ECR
echo "Pulling Docker image from ECR..."
sudo docker pull $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG

# Run the container
echo "Starting Docker container..."
sudo docker run -d \
  --name ecommerce-app \
  -p 80:80 \
  --restart unless-stopped \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG

# Wait for container to be ready
echo "Waiting for container to start..."
sleep 10

# Verify container is running
if sudo docker ps | grep -q ecommerce-app; then
    echo "✅ Container started successfully"
else
    echo "❌ Container failed to start"
    sudo docker logs ecommerce-app
    exit 1
fi

echo "Application start phase completed successfully"
