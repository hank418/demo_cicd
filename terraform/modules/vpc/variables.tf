# terraform/modules/vpc/variables.tf

variable "env" {
  description = "The environment name (e.g., staging, production)."
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "subnet_cidr_public_1" {
  description = "CIDR block for the first public subnet."
  type        = string
}

variable "subnet_cidr_public_2" {
  description = "CIDR block for the second public subnet."
  type        = string
}
