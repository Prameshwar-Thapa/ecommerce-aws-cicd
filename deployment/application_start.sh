#!/bin/bash

echo "Starting application_start phase..."

# Hardcoded values to avoid AWS CLI issues
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="142595748980"
IMAGE_REPO_NAME="ecommerce-app"
IMAGE_TAG="latest"

echo "Using AWS Region: $AWS_REGION"
echo "Using AWS Account ID: $AWS_ACCOUNT_ID"

# Stop and remove existing container
echo "Cleaning up existing containers..."
sudo docker stop ecommerce-app 2>/dev/null || true
sudo docker rm ecommerce-app 2>/dev/null || true

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
