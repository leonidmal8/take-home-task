# Example Dockerfile for testing the infrastructure
FROM nginx:alpine

# Create a simple HTML page
RUN cat << 'EOF' > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Internal Web Application</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .status {
            color: #28a745;
            font-weight: bold;
        }
        .info {
            background-color: #e9ecef;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Secure Internal Web Application</h1>
        <p class="status">✅ Application is running successfully!</p>
        
        <div class="info">
            <h3>Architecture Details:</h3>
            <ul>
                <li>Running on ECS Fargate in private subnets</li>
                <li>No direct internet access - using VPC endpoints</li>
                <li>Container pulled from private ECR repository</li>
                <li>HTTPS-only access via Application Load Balancer</li>
                <li>Maximum security with minimal cost</li>
            </ul>
        </div>
        
        <div class="info">
            <h3>Security Features:</h3>
            <ul>
                <li>Private network isolation</li>
                <li>Encrypted communication (HTTPS)</li>
                <li>Least-privilege IAM roles</li>
                <li>Multi-layered security groups</li>
            </ul>
        </div>
        
        <footer>
            <p><small>Internal application for employee use only</small></p>
        </footer>
    </div>
</body>
</html>
EOF

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
