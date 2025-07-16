# terraform/modules/ecs-app/main.tf

# -----------------------------------------------------
# 2. ECR Repository
# -----------------------------------------------------
data "aws_ecr_repository" "app" {
  name = "healthy-api-${var.env}" # <-- 指定要引用的 ECR Repository 名稱
}
data "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/healthy-api-${var.env}"
}


# -----------------------------------------------------
# 5. ECS Task Definition
# -----------------------------------------------------
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.env}-healthy-api-task"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "healthy-api"
      image     = "${data.aws_ecr_repository.app.repository_url}:${var.image_tag}"
      cpu       = var.container_cpu
      memory    = var.container_memory
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "NODE_ENV"
          value = var.env
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = data.aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.env}-task-definition"
    Environment = var.env
  }
}

