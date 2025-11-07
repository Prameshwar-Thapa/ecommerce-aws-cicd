#!/bin/bash

# Application Stop Script for Docker Deployment
# This script stops the Docker container

set -e

echo "Starting application_stop phase..."

# Stop Docker container
echo "Stopping Docker container..."
sudo docker stop ecommerce-app 2>/dev/null || echo "Container was not running"

# Remove Docker container
echo "Removing Docker container..."
sudo docker rm ecommerce-app 2>/dev/null || echo "Container was already removed"

echo "Application stop phase completed successfully"
