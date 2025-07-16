# terraform/modules/ecs-app/outputs.tf

output "ecr_repository_url" {
  description = "The URL of the ECR repository."
  value       = data.aws_ecr_repository.app.repository_url
}
