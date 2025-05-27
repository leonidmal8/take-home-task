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
sed -i 's/^aws_region *= *".*"/aws_region = "'"$AWS_REGION"'"/' terraform.tfvars
sed -i 's/^environment *= *".*"/environment = "'"$APP_ENV"'"/' terraform.tfvars
sed -i 's/^app_name *= *".*"/app_name = "'"$APP_NAME"'"/' terraform.tfvars
sed -i 's/^certificate_arn *= *".*"/certificate_arn = "'"$CERT_ARN"'"/' terraform.tfvars
terraform init
terraform plan
# terraform destroy -auto-approve
terraform apply -auto-approve

# Get outputs from Terraform
ECR_URL=$(terraform output -raw ecr_repository_url)
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(terraform output -raw ecs_service_name)
APP_URL=$(terraform output -raw application_url)

echo "✅ Infrastructure deployed successfully!"
echo "📋 ECR Repository: $ECR_URL"

# Step 2: Build and push Docker image
echo "🐳 Building and pushing Docker image..."

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
