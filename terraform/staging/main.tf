# terraform/staging/main.tf
provider "aws" {
  region = "ap-southeast-1"
  profile = var.aws_profile
}

module "ecs_app" {
  source = "../modules/ecs-app" # 相對路徑到 ECS 應用程式模組

  env           = "staging"
  aws_region    = "ap-southeast-1"
  image_tag     = var.image_tag
  desired_count = 1
}

variable "image_tag" {
  description = "The Docker image tag to deploy for staging."
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile name for local development"
  type        = string
  default     = ""
}