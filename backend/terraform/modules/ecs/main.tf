variable "stage" { type = string }
variable "ecr_repository_url" { type = string }
variable "route53_name" { type = string }

variable "db_name_arn" { type = string }
variable "db_host_arn" { type = string }
variable "db_port_arn" { type = string }
variable "db_user_arn" { type = string }
variable "db_pass_arn" { type = string }
variable "rails_master_key_arn" { type = string }

module "values" {
  source = "../../values"
}

locals {
  cluster_name = "${module.values.appname}-${var.stage}"
  service_name = "${module.values.appname}_service_${var.stage}"
  backend_prod_host = "review-backend-nanitabe.${var.route53_name}"
  container_port = 18101
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name
  # Container Insights は有効にしない（費用対効果が低いため design.md 参照）
}

resource "aws_cloudwatch_log_group" "task" {
  name = "/ecs/${local.cluster_name}"
  # retention_in_days は設定しない（無期限保持）
}

resource "aws_security_group" "task" {
  name = "${local.cluster_name}_task_sg"
  # review backend task用。API Gatewayの送信元IPが固定されないため0.0.0.0/0を許可し、IP直アクセスはRailsのconfig.hostsで弾く
  description = "review backend task security group. Direct IP access is blocked by Rails config.hosts."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = local.container_port
    to_port     = local.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "task_execution_role" {
  name = "${local.cluster_name}_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_role_managed" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "task_execution_role_ssm" {
  name = "${local.cluster_name}_task_execution_ssm_policy"
  role = aws_iam_role.task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ssm:GetParameters"]
        Resource = [
          var.db_name_arn,
          var.db_host_arn,
          var.db_port_arn,
          var.db_user_arn,
          var.db_pass_arn,
          var.rails_master_key_arn,
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.cluster_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.task_execution_role.arn

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${var.ecr_repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = local.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "RAILS_ENV", value = "production" },
        { name = "RAILS_LOG_TO_STDOUT", value = "1" },
        { name = "PORT", value = tostring(local.container_port) },
        { name = "BACKEND_PROD_HOST", value = local.backend_prod_host },
      ]

      secrets = [
        { name = "DB_NAME", valueFrom = var.db_name_arn },
        { name = "DB_HOST", valueFrom = var.db_host_arn },
        { name = "DB_PORT", valueFrom = var.db_port_arn },
        { name = "DB_USER", valueFrom = var.db_user_arn },
        { name = "DB_PASS", valueFrom = var.db_pass_arn },
        { name = "RAILS_MASTER_KEY", valueFrom = var.rails_master_key_arn },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.task.name
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = local.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 0
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.public.ids
    security_groups  = [aws_security_group.task.id]
    assign_public_ip = true
  }

  # deployment circuit breaker は設けない。起動失敗は30分の自動停止で止まるため（design.md参照）
  # lifecycle.ignore_changes[desired_count] も付けない。terraform applyが常に停止側へ倒れる挙動を意図している
}

output "cluster_name" { value = aws_ecs_cluster.this.name }
output "cluster_arn" { value = aws_ecs_cluster.this.arn }
output "service_name" { value = aws_ecs_service.this.name }
output "service_arn" { value = aws_ecs_service.this.id }
output "log_group_name" { value = aws_cloudwatch_log_group.task.name }
output "backend_prod_host" { value = local.backend_prod_host }
