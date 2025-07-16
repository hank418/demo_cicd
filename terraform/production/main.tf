# terraform/production/main.tf

provider "aws" {
  region = "ap-southeast-1"
}

module "ecs_app" {
  source = "../modules/ecs-app" # 相對路徑到 ECS 應用程式模組

  env           = "production"
  aws_region    = "ap-southeast-1"
  image_tag     = var.image_tag
  desired_count = 1
  task_cpu      = "512"
  task_memory   = "1024"
}

variable "image_tag" {
  description = "The Docker image tag to deploy for production."
  type        = string
}
