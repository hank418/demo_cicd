# terraform/staging/main.tf

provider "aws" {
  region = "ap-southeast-1"
  profile = var.aws_profile
}
terraform {
  backend "s3" {
    bucket = "democicd-terraform"
    key    = "healthy-api-staging/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

# 1. 建立 VPC 基礎設施
module "vpc" {
  source = "../modules/vpc" # 相對路徑到 VPC 模組

  env              = "staging"
  aws_region       = "ap-southeast-1"
  vpc_cidr_block   = "10.1.0.0/16"
  subnet_cidr_public_1 = "10.1.1.0/24"
  subnet_cidr_public_2 = "10.1.2.0/24"
}

# 2. 建立 ECS 應用程式相關資源，並將 VPC 模組的輸出傳入
module "ecs_app" {
  source = "../modules/ecs-app" # 相對路徑到 ECS 應用程式模組

  env           = "staging"
  aws_region    = "ap-southeast-1"
  vpc_id        = module.vpc.vpc_id         # 從 VPC 模組獲取 VPC ID
  subnet_ids    = module.vpc.public_subnet_ids # 從 VPC 模組獲取子網路 ID 列表
  image_tag     = var.image_tag
  desired_count = 1
}

variable "image_tag" {
  description = "The Docker image tag to deploy for staging."
  type        = string
}

output "alb_staging_dns_name" {
  value = module.ecs_app.alb_dns_name
}

variable "aws_profile" {
  description = "AWS CLI profile name for local development"
  type        = string
  default     = ""
}

variable "iam_role_arn" {
  description = "ARN of the IAM role for ECS task execution."
  type        = string
  default = ""
}