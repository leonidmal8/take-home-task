terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  app_name               = var.app_name
  environment           = var.environment
  aws_region            = var.aws_region
  vpc_cidr              = var.vpc_cidr
  availability_zones    = data.aws_availability_zones.available.names
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"
  
  app_name     = var.app_name
  environment  = var.environment
}

# ALB Module
module "alb" {
  source = "./modules/alb"
  
  app_name          = var.app_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  certificate_arn   = var.certificate_arn
}

# IAM Module  
module "iam" {
  source = "./modules/iam"
  
  app_name    = var.app_name
  environment = var.environment
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"
  
  app_name                       = var.app_name
  environment                    = var.environment
  aws_region                     = var.aws_region
  vpc_id                         = module.vpc.vpc_id
  private_subnet_ids             = module.vpc.private_subnet_ids
  alb_security_group_id          = module.alb.alb_security_group_id
  target_group_arn               = module.alb.target_group_arn
  ecr_repository_url             = module.ecr.repository_url
  vpc_endpoint_security_group_id = module.vpc.vpc_endpoint_security_group_id
  image_tag                      = var.image_tag
  execution_role_arn             = module.iam.ecs_execution_role_arn
  task_role_arn                  = module.iam.ecs_task_role_arn
}