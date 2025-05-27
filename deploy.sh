#!/bin/bash

# Deployment script for Secure Internal Web Application
set -e

echo "🚀 Starting deployment of Secure Internal Web Application..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Step 1: Deploy infrastructure
echo "📦 Deploying infrastructure with Terraform..."
terraform init
terraform plan
read -p "Do you want to apply these changes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform apply -auto-approve
else
    echo "❌ Deployment cancelled"
    exit 1
fi

# Get outputs from Terraform
ECR_URL=$(terraform output -raw ecr_repository_url)
AWS_REGION=$(terraform output -raw aws_region || echo "us-west-2")
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(terraform output -raw ecs_service_name)
APP_URL=$(terraform output -raw application_url)

echo "✅ Infrastructure deployed successfully!"
echo "📋 ECR Repository: $ECR_URL"

# Step 2: Build and push Docker image
echo "🐳 Building and pushing Docker image..."

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    echo "⚠️  No Dockerfile found. Creating example Dockerfile..."
    cat > Dockerfile << 'EOF'
FROM nginx:alpine
RUN echo '<!DOCTYPE html>
<html><head><title>Internal App</title></head>
<body style="font-family:Arial;padding:50px;text-align:center;">
<h1>🔒 Secure Internal Web Application</h1>
<p>✅ Running successfully on ECS Fargate!</p>
<p><small>Private ECR + VPC Endpoints Architecture</small></p>
</body></html>' > /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
fi

# Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL

# Build image
echo "🔨 Building Docker image..."
docker build -t internal-webapp .

# Tag image
echo "🏷️  Tagging image..."
docker tag internal-webapp:latest $ECR_URL:latest

# Push image
echo "📤 Pushing image to ECR..."
docker push $ECR_URL:latest

# Step 3: Force ECS service update
echo "🔄 Updating ECS service..."
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --force-new-deployment \
    --region $AWS_REGION > /dev/null

echo "⏳ Waiting for service to stabilize..."
aws ecs wait services-stable \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --region $AWS_REGION

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📊 Deployment Summary:"
echo "   • Infrastructure: ✅ Deployed"
echo "   • Container Image: ✅ Built and pushed to ECR"
echo "   • ECS Service: ✅ Updated and running"
echo ""
echo "🌐 Application URL: $APP_URL"
echo ""
echo "📝 Next Steps:"
echo "   1. Wait 2-3 minutes for the application to fully start"
echo "   2. Access your application at: $APP_URL"
echo "   3. Monitor logs: aws logs tail /ecs/internal-webapp --follow"
echo ""
echo "💰 Cost Optimization:"
echo "   • No NAT Gateway costs (saves ~$90/month)"
echo "   • VPC Endpoints: ~$10-15/month"
echo "   • Maximum security with minimal cost!"
echo ""