# terraform/modules/ecs-app/variables.tf

variable "env" {
  description = "The environment name (e.g., staging, production)."
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the ECS app will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "A list of public subnet IDs for the ECS app."
  type        = list(string)
}

variable "image_tag" {
  description = "The Docker image tag to deploy."
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the ECS task (e.g., '256', '512', '1024')."
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory (in MiB) for the ECS task (e.g., '512', '1024', '2048')."
  type        = string
  default     = "512"
}

variable "container_cpu" {
  description = "CPU units for the container."
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory (in MiB) for the container."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of tasks to run."
  type        = number
  default     = 1
}
