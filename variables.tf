# variables.tf
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "home-task-webapp"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS (update with your actual certificate)"
  type        = string
  default     = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"
}

variable "cognito_domain_prefix" {
  description = "Prefix for the Cognito domain (must be globally unique)"
  type        = string
  default     = "your-app-auth"  # Change this to something unique
}

variable "callback_urls" {
  description = "List of callback URLs for Cognito"
  type        = list(string)
  default     = ["https://your-domain.com/oauth2/idpresponse"]  # Update with your actual domain
}

variable "logout_urls" {
  description = "List of logout URLs for Cognito"
  type        = list(string)
  default     = ["https://your-domain.com"]  # Update with your actual domain
}

