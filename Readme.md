# Take Home Task - Internal Tool

This repository contains a small internal web application, designed for secure and cost-effective deployment using AWS infrastructure and containers.

## Features

- Simple static web UI served by Nginx (see `index.html`)
- Dockerized for easy deployment (`Dockerfile`)
- Infrastructure as Code using Terraform (`main.tf` and modules)
- Secure deployment architecture leveraging AWS ECS Fargate, private subnets, VPC endpoints, and Application Load Balancer (ALB) with HTTPS

## Architecture Overview

- **ECS Fargate**: Runs containers in private subnets (no direct internet access)
- **VPC Endpoints**: All AWS service access is via VPC endpoints
- **ECR**: Docker images are pulled from a private Amazon ECR repository
- **ALB**: Application is only accessible securely over HTTPS
- **IAM**: Uses least-privilege IAM roles for tasks and execution
- **Terraform Modules**: Modular setup for VPC, ECR, ALB, IAM, and ECS

## Security Features

- Network isolation in private subnets
- Encrypted traffic via HTTPS (requires an AWS ACM certificate)
- Multi-layered security groups
- Least-privilege IAM roles

## Getting Started

### Prerequisites

- Docker
- AWS CLI
- Terraform >= 1.0
- Access to AWS with permissions to create VPC, ECS, ECR, ALB, IAM, and ACM resources

### Build and Run Locally

```sh
docker build -t internal-webapp .
docker run -p 8080:80 internal-webapp
# Visit http://localhost:8080
