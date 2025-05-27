# terraform.tfvars.example
# Copy this file to terraform.tfvars and update with your actual values

# AWS region where you want to deploy
aws_region = ${{ vars.AWS_REGION }}

# Environment name (dev, staging, prod)
environment = ${{ vars.APP_ENV }}

# Application name (will be used for resource naming)
app_name = ${{ vars.APP_NAME }}

# Docker image tag to deploy
image_tag = "latest"

# SSL certificate ARN from AWS Certificate Manager
# Replace with your actual certificate ARN
certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"
