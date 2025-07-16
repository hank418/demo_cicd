# terraform/production/main.tf

provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  backend "s3" {
    bucket = "democicd-terraform"
    key    = "healthy-api-production/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

# 1. 建立 VPC 基礎設施
module "vpc" {
  source = "../modules/vpc" # 相對路徑到 VPC 模組

  env              = "production"
  aws_region       = "ap-southeast-1"
  vpc_cidr_block   = "10.2.0.0/16"
  subnet_cidr_public_1 = "10.2.1.0/24"
  subnet_cidr_public_2 = "10.2.2.0/24"
}

# 2. 建立 ECS 應用程式相關資源，並將 VPC 模組的輸出傳入
module "ecs_app" {
  source = "../modules/ecs-app" # 相對路徑到 ECS 應用程式模組

  env           = "production"
  aws_region    = "ap-southeast-1"
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.public_subnet_ids
  image_tag     = var.image_tag
  desired_count = 1
  task_cpu      = "512"
  task_memory   = "1024"
}

variable "image_tag" {
  description = "The Docker image tag to deploy for production."
  type        = string
}

output "alb_production_dns_name" {
  value = module.ecs_app.alb_dns_name
}
