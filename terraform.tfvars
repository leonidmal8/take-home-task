# terraform.tfvars.example
# Copy this file to terraform.tfvars and update with your actual values

# AWS region where you want to deploy
aws_region = "us-east-1" 

# Environment name (dev, staging, prod)
environment = "dev"

# Application name (will be used for resource naming)
app_name = "home-task"

# Docker image tag to deploy
image_tag = "latest"

# SSL certificate ARN from AWS Certificate Manager
# Replace with your actual certificate ARN
certificate_arn = "arn:aws:acm:us-east-1:578449232691:certificate/cde61e76-1d6f-4107-91bf-58a9be0cb2dc"
