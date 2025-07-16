# terraform/modules/ecs-app/main.tf

# -----------------------------------------------------
# 1. ECS Cluster
# -----------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.env}-healthy-api-cluster"

  tags = {
    Name        = "${var.env}-ecs-cluster"
    Environment = var.env
  }
}

# -----------------------------------------------------
# 2. ECR Repository
# -----------------------------------------------------
data "aws_ecr_repository" "app" {
  name = "healthy-api-${var.env}" # <-- 指定要引用的 ECR Repository 名稱
}

# -----------------------------------------------------
# 3. IAM Roles for ECS Tasks
# -----------------------------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.env}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name        = "${var.env}-ecs-execution-role"
    Environment = var.env
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -----------------------------------------------------
# 4. CloudWatch Log Group for ECS Task Logs
# -----------------------------------------------------
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
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
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

# -----------------------------------------------------
# 6. Application Load Balancer (ALB) and Target Group
# -----------------------------------------------------
resource "aws_lb" "app" {
  name               = "${var.env}-healthy-api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = var.subnet_ids # <-- 從 VPC 模組接收

  enable_deletion_protection = false

  tags = {
    Name        = "${var.env}-alb"
    Environment = var.env
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.env}-healthy-api-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id # <-- 從 VPC 模組接收
  target_type = "ip"

  health_check {
    path                = "/healthy"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.env}-target-group"
    Environment = var.env
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = {
    Name        = "${var.env}-listener"
    Environment = var.env
  }
}

# -----------------------------------------------------
# 7. Security Groups
# -----------------------------------------------------
resource "aws_security_group" "lb" {
  name        = "${var.env}-healthy-api-lb-sg"
  description = "Allow inbound HTTP traffic to ALB for ${var.env}"
  vpc_id      = var.vpc_id # <-- 從 VPC 模組接收

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-lb-sg"
    Environment = var.env
  }
}

resource "aws_security_group" "app" {
  name        = "${var.env}-healthy-api-app-sg"
  description = "Allow inbound traffic to app containers from ALB for ${var.env}"
  vpc_id      = var.vpc_id # <-- 從 VPC 模組接收

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-app-sg"
    Environment = var.env
  }
}

# -----------------------------------------------------
# 8. ECS Service
# -----------------------------------------------------
resource "aws_ecs_service" "app" {
  name            = "${var.env}-healthy-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids # <-- 從 VPC 模組接收
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "healthy-api"
    container_port   = 3000
  }

  force_new_deployment = true

  depends_on = [
    aws_lb_listener.http
  ]

  tags = {
    Name        = "${var.env}-ecs-service"
    Environment = var.env
  }
}
