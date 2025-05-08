# Use the official Apache httpd image
FROM httpd:alpine

# Remove default Apache files
RUN rm -rf /usr/local/apache2/htdocs/*

# Copy your static files into Apache's document root
COPY . /usr/local/apache2/htdocs

# Expose port 80 (Apache's default port)
EXPOSE 80

# Apache runs automatically with the base image as the entrypoint