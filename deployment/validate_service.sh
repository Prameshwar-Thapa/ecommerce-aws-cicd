#!/bin/bash

# Validate Service Script for Docker Deployment
# This script validates that the Docker container is running correctly

set -e

echo "Starting validate_service phase..."

# Wait for application to be fully ready
echo "Waiting for application to be ready..."
sleep 15

# Check if Docker container is running
echo "Checking Docker container status..."
if sudo docker ps | grep -q ecommerce-app; then
    echo "✅ Docker container is running"
else
    echo "❌ Docker container is not running"
    sudo docker ps -a | grep ecommerce-app || echo "Container not found"
    exit 1
fi

# Check container health
echo "Checking container health..."
CONTAINER_STATUS=$(sudo docker inspect --format='{{.State.Status}}' ecommerce-app)
if [ "$CONTAINER_STATUS" = "running" ]; then
    echo "✅ Container status: $CONTAINER_STATUS"
else
    echo "❌ Container status: $CONTAINER_STATUS"
    sudo docker logs ecommerce-app
    exit 1
fi

# Test HTTP response
echo "Testing HTTP response..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ HTTP response: $HTTP_CODE"
else
    echo "❌ HTTP response: $HTTP_CODE"
    sudo docker logs ecommerce-app
    exit 1
fi

# Test application content
echo "Testing application content..."
RESPONSE=$(curl -s http://localhost/ | grep -i "ecommerce\|shop\|product" | head -1)
if [ -n "$RESPONSE" ]; then
    echo "✅ Application content validated"
else
    echo "❌ Application content validation failed"
    curl -s http://localhost/ | head -10
    exit 1
fi

# Check Docker logs for errors
echo "Checking Docker logs for errors..."
ERROR_COUNT=$(sudo docker logs ecommerce-app 2>&1 | grep -i "error\|fail\|exception" | wc -l)
if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✅ No errors found in container logs"
else
    echo "⚠️  Found $ERROR_COUNT potential errors in logs"
    sudo docker logs ecommerce-app 2>&1 | grep -i "error\|fail\|exception" | tail -5
fi

# Performance check
echo "Running performance check..."
RESPONSE_TIME=$(curl -s -w "%{time_total}" -o /dev/null http://localhost/)
echo "Response time: ${RESPONSE_TIME}s"

# Final validation
echo "Running final validation..."
if curl -f -s http://localhost/ > /dev/null; then
    echo "✅ Final validation passed"
    echo "🎉 Application deployment validated successfully!"
else
    echo "❌ Final validation failed"
    exit 1
fi

echo "Validate service phase completed successfully"
