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
If you need to delete the existing infrastructure, simply uncomment \`\`\`# terraform destroy -auto-approve in deploy.sh\`\`\`, comment out the following \`\`\`terraform apply -auto-approve\`\`\`, and push the changes.

