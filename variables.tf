# variables.tf
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "home-task"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS (update with your actual certificate)"
  type        = string
  default     = ""
}
