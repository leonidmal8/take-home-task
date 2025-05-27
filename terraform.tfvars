# terraform.tfvars.example
# Copy this file to terraform.tfvars and update with your actual values

# AWS region where you want to deploy
aws_region = "" 

# Environment name (dev, staging, prod)
environment = ""

# Application name (will be used for resource naming)
app_name = ""

# Docker image tag to deploy
image_tag = "latest"

# SSL certificate ARN from AWS Certificate Manager
# Replace with your actual certificate ARN
certificate_arn = ""
