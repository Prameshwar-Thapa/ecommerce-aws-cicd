# Use nginx as base image
FROM nginx:alpine

# Copy the e-commerce application files
COPY src/ecommerce-app/ /usr/share/nginx/html/

# Copy custom nginx configuration
COPY src/config/nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
