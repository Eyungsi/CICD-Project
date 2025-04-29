# Use a lightweight Nginx image
FROM nginx:alpine

# Remove default Nginx HTML files
RUN rm -rf /usr/share/nginx/html/*

# Copy your static files into the Nginx public directory
COPY . /usr/share/nginx/html

# Optional: Expose port 80 (already handled by nginx, but good for clarity)
EXPOSE 8080

# Nginx runs automatically with the base image as the entrypoint
