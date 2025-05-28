# Take Home Task - Internal Tool

This repository contains a small internal web application, designed for secure and cost-effective deployment using AWS infrastructure and containers.

## Architecture Overview

- **ECS Fargate**: Runs containers in private subnets (no direct internet access)
- **VPC Endpoints**: All AWS service access is via VPC endpoints
- **ECR**: Docker images are pulled from a private Amazon ECR repository
- **ALB**: Application is only accessible securely over HTTPS
- **IAM**: Uses least-privilege IAM roles for tasks and execution


## Security Features

- Network isolation in private subnets
- Encrypted traffic via HTTPS (requires an AWS ACM certificate)
- Multi-layered security groups
- Least-privilege IAM roles

## Infrastructure stack deploy and destroy

To follow the **immutable infrastructure** principle, the entire Terraform stack is updated every time the deployment pipeline runs, or created if it doesn’t exist (the corresponding stack state is stored in **S3** with locking handled via **DynamoDB**).
Credentials for connecting to AWS and all necessary Terraform variables are stored in the **secrets and variables** of the **GitHub Actions** develop environment.
If you need to delete the existing infrastructure, simply uncomment `# terraform destroy -auto-approve in deploy.sh`, comment out the following `terraform apply -auto-approve`, and push the changes.

## Estimated Monthly Costs

| Service Category | Component Details | Monthly Cost (USD) |
|-----------------|-------------------|-------------------|
| **Compute** | ECS Fargate (0.25 vCPU, 512MB memory) | $9.01 |
| **Load Balancing** | Application Load Balancer + Data Processing | $17.00 |
| **Networking** | VPC Endpoints (5 Interface + 1 Gateway) | $38.50 |
| **Container Registry** | ECR Storage (~10GB) | $1.00 |
| **Monitoring** | CloudWatch Logs + Container Insights | $3.00 |
| **Data Transfer** | Estimated usage | $2.00 |
| **SSL Certificate** | AWS Certificate Manager | $0.00 (Free) |
| | **Total Estimated Monthly Cost** | **$70.51** |

