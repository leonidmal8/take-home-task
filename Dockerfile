# Use the official lightweight Nginx image
FROM nginx:alpine

# Copy your HTML file into the default nginx public directory
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# Start nginx when the container launches
CMD ["nginx", "-g", "daemon off;"]