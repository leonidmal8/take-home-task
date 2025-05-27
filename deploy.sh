#!/bin/bash

# Deployment script for Secure Internal Web Application (Modular Architecture)
set -e

echo "🚀 Starting deployment of Secure Internal Web Application (Modular)..."

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}"
MODULES_DIR="${TERRAFORM_DIR}/modules"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi

    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        print_info "Visit: https://learn.hashicorp.com/tutorials/terraform/install-cli"
        exit 1
    fi

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        print_info "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi

    # Check Terraform version
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    print_info "Terraform version: $TERRAFORM_VERSION"

    # Check if modules directory exists
    if [ ! -d "$MODULES_DIR" ]; then
        print_error "Modules directory not found at: $MODULES_DIR"
        print_info "Please ensure the modular Terraform structure is in place."
        exit 1
    fi

    # Validate required modules exist
    REQUIRED_MODULES=("vpc" "ecr" "alb" "ecs" "iam")
    for module in "${REQUIRED_MODULES[@]}"; do
        if [ ! -d "$MODULES_DIR/$module" ]; then
            print_error "Required module '$module' not found in $MODULES_DIR"
            exit 1
        fi
    done

    print_status "Prerequisites check passed"
}

# Function to validate Terraform configuration
validate_terraform() {
    echo "🔍 Validating Terraform configuration..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    print_info "Initializing Terraform..."
    terraform init -upgrade
    
    # Validate configuration
    print_info "Validating Terraform configuration..."
    terraform validate
    
    # Format check
    print_info "Checking Terraform formatting..."
    if ! terraform fmt -check -recursive; then
        print_warning "Terraform files are not properly formatted. Running terraform fmt..."
        terraform fmt -recursive
        print_status "Terraform files formatted"
    fi
    
    print_status "Terraform configuration is valid"
}

# Function to create terraform.tfvars if it doesn't exist
create_tfvars() {
    local tfvars_file="$TERRAFORM_DIR/terraform.tfvars"
    
    if [ ! -f "$tfvars_file" ]; then
        print_warning "terraform.tfvars not found. Creating example file..."
        
        cat > "$tfvars_file" << 'EOF'
# terraform.tfvars - Customize these values for your deployment

# AWS Configuration
aws_region = "us-west-2"

# Application Configuration
app_name    = "internal-webapp"
environment = "dev"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# Container Configuration
image_tag = "latest"

# SSL Certificate ARN (REQUIRED - Update with your actual certificate ARN)
# You can create a certificate in AWS Certificate Manager (ACM)
certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"
EOF

        print_warning "Please update terraform.tfvars with your actual values, especially the certificate_arn!"
        print_info "You can create an SSL certificate in AWS Certificate Manager (ACM)"
        
        read -p "Do you want to continue with the example values? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Please update terraform.tfvars and run the script again."
            exit 1
        fi
    fi
}

# Function to deploy infrastructure
deploy_infrastructure() {
    echo "📦 Deploying infrastructure with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Create terraform.tfvars if needed
    create_tfvars
    
    # Plan deployment
    print_info "Creating Terraform plan..."
    terraform plan -out=tfplan
    
    echo
    print_warning "Review the Terraform plan above carefully!"
    read -p "Do you want to apply these changes? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Applying Terraform changes..."
        terraform apply tfplan
        
        # Clean up plan file
        rm -f tfplan
        
        print_status "Infrastructure deployed successfully!"
    else
        print_error "Deployment cancelled by user"
        rm -f tfplan
        exit 1
    fi
}

# Function to get Terraform outputs
get_terraform_outputs() {
    cd "$TERRAFORM_DIR"
    
    print_info "Retrieving Terraform outputs..."
    
    # Check if outputs are available
    if ! terraform output &> /dev/null; then
        print_error "No Terraform outputs found. Please ensure infrastructure is deployed."
        exit 1
    fi
    
    ECR_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
    AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-west-2")
    CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
    SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")
    APP_URL=$(terraform output -raw application_url 2>/dev/null || echo "")
    
    if [ -z "$ECR_URL" ] || [ -z "$CLUSTER_NAME" ] || [ -z "$SERVICE_NAME" ]; then
        print_error "Failed to retrieve required Terraform outputs"
        exit 1
    fi
    
    print_info "ECR Repository: $ECR_URL"
    print_info "ECS Cluster: $CLUSTER_NAME"
    print_info "ECS Service: $SERVICE_NAME"
}

# Function to create Dockerfile if it doesn't exist
create_dockerfile() {
    if [ ! -f "Dockerfile" ]; then
        print_warning "No Dockerfile found. Creating example Dockerfile..."
        cat > Dockerfile << 'EOF'
FROM nginx:alpine

# Create a simple HTML page
RUN echo '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Internal Web Application</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            margin: 0;
            padding: 50px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-align: center;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
        }
        h1 {
            font-size: 3rem;
            margin-bottom: 1rem;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .status {
            font-size: 1.5rem;
            margin: 2rem 0;
            padding: 1rem;
            background: rgba(255,255,255,0.1);
            border-radius: 10px;
            backdrop-filter: blur(10px);
        }
        .architecture {
            font-size: 1rem;
            opacity: 0.8;
            margin-top: 2rem;
        }
        .features {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin-top: 2rem;
        }
        .feature {
            background: rgba(255,255,255,0.1);
            padding: 1rem;
            border-radius: 8px;
            backdrop-filter: blur(5px);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Secure Internal Web Application</h1>
        <div class="status">
            ✅ Running successfully on ECS Fargate!
        </div>
        <div class="features">
            <div class="feature">
                <h3>🏗️ Modular Architecture</h3>
                <p>Terraform modules for maintainable infrastructure</p>
            </div>
            <div class="feature">
                <h3>🔐 Private ECR</h3>
                <p>Container registry with VPC endpoints</p>
            </div>
            <div class="feature">
                <h3>🛡️ Secure Networking</h3>
                <p>No NAT Gateway, VPC endpoints only</p>
            </div>
            <div class="feature">
                <h3>💰 Cost Optimized</h3>
                <p>~$10-15/month vs ~$90+ with NAT</p>
            </div>
        </div>
        <div class="architecture">
            <small>Modular Terraform • Private ECR • VPC Endpoints • ECS Fargate • Application Load Balancer</small>
        </div>
    </div>
</body>
</html>' > /usr/share/nginx/html/index.html

# Add health check endpoint
RUN echo '{"status": "healthy", "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > /usr/share/nginx/html/health

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
        print_status "Example Dockerfile created"
    fi
}

# Function to build and push Docker image
build_and_push_image() {
    echo "🐳 Building and pushing Docker image..."
    
    create_dockerfile
    
    # Login to ECR
    print_info "Logging into ECR..."
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URL"
    
    # Build image
    print_info "Building Docker image..."
    docker build -t internal-webapp .
    
    # Tag image
    print_info "Tagging image..."
    docker tag internal-webapp:latest "$ECR_URL:latest"
    
    # Push image
    print_info "Pushing image to ECR..."
    docker push "$ECR_URL:latest"
    
    print_status "Docker image built and pushed successfully!"
}

# Function to update ECS service
update_ecs_service() {
    echo "🔄 Updating ECS service..."
    
    print_info "Forcing ECS service deployment..."
    aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$SERVICE_NAME" \
        --force-new-deployment \
        --region "$AWS_REGION" > /dev/null
    
    print_info "Waiting for service to stabilize (this may take a few minutes)..."
    aws ecs wait services-stable \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --region "$AWS_REGION"
    
    print_status "ECS service updated successfully!"
}

# Function to show deployment summary
show_summary() {
    echo
    echo "🎉 Deployment completed successfully!"
    echo
    echo "📊 Deployment Summary:"
    echo "   • Infrastructure: ✅ Deployed (Modular Terraform)"
    echo "   • Container Image: ✅ Built and pushed to ECR"
    echo "   • ECS Service: ✅ Updated and running"
    echo
    if [ -n "$APP_URL" ]; then
        echo "🌐 Application URL: $APP_URL"
    fi
    echo
    echo "📝 Next Steps:"
    echo "   1. Wait 2-3 minutes for the application to fully start"
    if [ -n "$APP_URL" ]; then
        echo "   2. Access your application at: $APP_URL"
    fi
    echo "   3. Monitor logs: aws logs tail /ecs/internal-webapp --follow --region $AWS_REGION"
    echo "   4. Check ECS service: aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $AWS_REGION"
    echo
    echo "🔧 Management Commands:"
    echo "   • Scale service: aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count <N> --region $AWS_REGION"
    echo "   • View logs: aws logs tail /ecs/internal-webapp --follow --region $AWS_REGION"
    echo "   • Destroy infrastructure: terraform destroy"
    echo
    echo "💰 Cost Optimization:"
    echo "   • No NAT Gateway costs (saves ~$90/month)"
    echo "   • VPC Endpoints: ~$10-15/month"
    echo "   • Modular architecture for easy maintenance!"
    echo
}

# Main deployment flow
main() {
    check_prerequisites
    validate_terraform
    deploy_infrastructure
    get_terraform_outputs
    build_and_push_image
    update_ecs_service
    show_summary
}

# Parse command line arguments
case "${1:-}" in
    --validate-only)
        echo "🔍 Running validation only..."
        check_prerequisites
        validate_terraform
        print_status "Validation completed successfully!"
        ;;
    --infrastructure-only)
        echo "🏗️ Deploying infrastructure only..."
        check_prerequisites
        validate_terraform
        deploy_infrastructure
        get_terraform_outputs
        echo "📊 Infrastructure deployed. Use './deploy.sh --app-only' to deploy the application."
        ;;
    --app-only)
        echo "🐳 Deploying application only..."
        check_prerequisites
        get_terraform_outputs
        build_and_push_image
        update_ecs_service
        show_summary
        ;;
    --help|-h)
        echo "Usage: $0 [OPTION]"
        echo "Deploy Secure Internal Web Application with modular Terraform architecture"
        echo
        echo "Options:"
        echo "  --validate-only       Validate Terraform configuration only"
        echo "  --infrastructure-only Deploy infrastructure only"
        echo "  --app-only           Deploy application only (requires existing infrastructure)"
        echo "  --help, -h           Show this help message"
        echo
        echo "Default: Full deployment (infrastructure + application)"
        ;;
    *)
        main
        ;;
esac