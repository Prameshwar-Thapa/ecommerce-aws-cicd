#!/bin/bash

echo "Starting before_install phase..."

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo yum update -y
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -a -G docker ec2-user
else
    echo "Docker is already installed"
    sudo systemctl start docker
fi

# Install AWS CLI if not already installed
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
fi

# Stop and remove existing container
echo "Cleaning up existing containers..."
sudo docker stop ecommerce-app 2>/dev/null || true
sudo docker rm ecommerce-app 2>/dev/null || true

echo "Before install phase completed successfully"
