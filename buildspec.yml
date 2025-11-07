FROM public.ecr.aws/nginx/nginx:alpine

# Copy the e-commerce application files
COPY src/ecommerce-app/ /usr/share/nginx/html/

# Copy custom nginx configuration
COPY src/config/nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80


# Start nginx
CMD ["nginx", "-g", "daemon off;"]
