# Take Home Task - Internal Tool

This repository contains a small internal web application, designed for secure and cost-effective deployment using AWS infrastructure and containers.

The default branch is **develop**, and it is currently being deployed to AWS as the live service at:  **[hometask.leonidmaliuk.com](https://hometask.leonidmaliuk.com/)**

## Architecture Overview

- **ECS Fargate**: Runs containers in private subnets (no direct internet access)
- **VPC Endpoints**: All AWS service access is via VPC endpoints
- **ECR**: Docker images are pulled from a private Amazon ECR repository
- **ALB**: Application is only accessible securely over HTTPS
- **IAM**: Uses least-privilege IAM roles for tasks and execution

  Please review the architecture diagram - `./infrastructure-diagram.svg`


## Security Features

- Network isolation in private subnets
- Encrypted traffic via HTTPS (requires an AWS ACM certificate)
- Multi-layered security groups
- Least-privilege IAM roles

## CI/CD

The CI/CD consists of a main application script **deploy.sh** and a GitHub Actions workflow that implements basic **SAST** and **DAST** tests, performed respectively before and after deployment.

## Infrastructure stack deploy and destroy

To follow the **immutable infrastructure** principle, the entire Terraform stack is updated every time the deployment pipeline runs, or created if it doesn’t exist (the corresponding stack state is stored in **S3** with locking handled via **DynamoDB**).
Credentials for connecting to AWS and all necessary Terraform variables are stored in the **secrets and variables** of the **GitHub Actions** develop environment.
If you need to delete the existing infrastructure, simply uncomment `# terraform destroy -auto-approve` in **deploy.sh**, comment out the following `terraform apply -auto-approve`, and push the changes.
Feel free to make changes into **index.html** file and create pull request to **develop** branch, just to check deployment process.

## Estimated Monthly Costs

| Service Category | Component Details | Monthly Cost (USD) |
|-----------------|-------------------|-------------------|
| **Compute** | ECS Fargate (0.25 vCPU, 512MB memory) | $9.01 |
| **Load Balancing** | Application Load Balancer + Data Processing | $17.00 |
| **Networking** | VPC Endpoints (6 Interface + 1 Gateway) | $43.80 |
| **Container Registry** | ECR Storage (~10GB) | $1.00 |
| **Monitoring** | CloudWatch Logs + Container Insights | $3.00 |
| **Data Transfer** | Estimated usage | $2.00 |
| **SSL Certificate** | AWS Certificate Manager | $0.00 (Free) |
| | **Total Estimated Monthly Cost** | **$75.81** |

## Additional options

The **modules** branch presents an approach using modular Terraform configuration.
This setup is more complex to implement and maintain, but it’s justified if you have many internal services that follow the same deployment pattern.
However, if the service is standalone, as in our case, and the infrastructure is relatively small,
a monolithic configuration (as currently used in the develop branch) is sufficient.

The **cognito** branch demonstrates an approach with authentication via AWS Cognito (free for up to 10,000 logins),
if this is relevant for our service.
There is also an option to restrict ingress traffic in the security group based on IP address.

## Cost optimization options

We can remove logs, saving around $10.30 per month.

If the number of users is small and the application is not mission-critical,
we can place both ECR and ECS in public, restrict access by IP, and integrate Cognito as described above.
This would allow us to eliminate the load balancer and VPC with endpoints,
reducing the monthly cost to approximately $14 instead of the current $76.

## To add

Alerts for metrics and logs

Health checks for ECS tasks
