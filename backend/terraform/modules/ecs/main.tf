variable "stage" { type = string }
variable "ecr_repository_url" { type = string }
variable "route53_name" { type = string }

module "values" {
  source = "../../values"
}

data "aws_caller_identity" "current" {}

locals {
  # review の SSM parameter は Terraform の管理外。scripts/review_backend/put_ssm_parameters.sh が同じ名前で書く。
  ssm_parameter_arn_prefix = "arn:aws:ssm:ap-northeast-1:${data.aws_caller_identity.current.account_id}:parameter/${module.values.appname}/${var.stage}"
  db_name_arn              = "${local.ssm_parameter_arn_prefix}/DB_NAME"
  db_host_arn              = "${local.ssm_parameter_arn_prefix}/DB_HOST"
  db_port_arn              = "${local.ssm_parameter_arn_prefix}/DB_PORT"
  db_user_arn              = "${local.ssm_parameter_arn_prefix}/DB_USER"
  db_pass_arn              = "${local.ssm_parameter_arn_prefix}/DB_PASS"
  rails_master_key_arn     = "${local.ssm_parameter_arn_prefix}/RAILS_MASTER_KEY"

  cluster_name      = "${module.values.appname}-${var.stage}"
  service_name      = "${module.values.appname}_service_${var.stage}"
  backend_prod_host = "review-backend-nanitabe.${var.route53_name}"
  container_port    = 18101
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

data "aws_subnets" "vpc_link" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  # API Gateway VPC link V2 が対応する Tokyo の AZ ID だけを使う。
  filter {
    name   = "availability-zone-id"
    values = ["apne1-az1", "apne1-az2", "apne1-az4"]
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

resource "aws_security_group" "vpc_link" {
  name        = "${local.cluster_name}_vpc_link_sg"
  description = "API Gateway private integration interfaces"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "task" {
  name = "${local.cluster_name}_task_sg"
  # Host 検査とは独立に、VPC link の ENI からだけ受信する。
  # descriptionは不変属性のため既存値を維持する。受信制御は以下のSG参照で定義する。
  description = "review backend task security group. Direct IP access is blocked by Rails config.hosts."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = local.container_port
    to_port         = local.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc_link.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_service_discovery_private_dns_namespace" "backend" {
  name = "${local.cluster_name}.internal"
  vpc  = data.aws_vpc.default.id
}

resource "aws_service_discovery_service" "backend" {
  name = "backend"

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.backend.id
    routing_policy = "MULTIVALUE"
    dns_records {
      ttl  = 10
      type = "SRV"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
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
          local.db_name_arn,
          local.db_host_arn,
          local.db_port_arn,
          local.db_user_arn,
          local.db_pass_arn,
          local.rails_master_key_arn,
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

      healthCheck = {
        command     = ["CMD-SHELL", "ruby -rsocket -e 'TCPSocket.new(\"127.0.0.1\", Integer(ENV.fetch(\"PORT\"))).close'"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      environment = [
        { name = "RAILS_ENV", value = "production" },
        { name = "RAILS_LOG_TO_STDOUT", value = "1" },
        { name = "PORT", value = tostring(local.container_port) },
        { name = "BACKEND_PROD_HOST", value = local.backend_prod_host },
      ]

      secrets = [
        { name = "DB_NAME", valueFrom = local.db_name_arn },
        { name = "DB_HOST", valueFrom = local.db_host_arn },
        { name = "DB_PORT", valueFrom = local.db_port_arn },
        { name = "DB_USER", valueFrom = local.db_user_arn },
        { name = "DB_PASS", valueFrom = local.db_pass_arn },
        { name = "RAILS_MASTER_KEY", valueFrom = local.rails_master_key_arn },
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

  service_registries {
    registry_arn   = aws_service_discovery_service.backend.arn
    container_name = "backend"
    container_port = local.container_port
  }

  network_configuration {
    subnets          = data.aws_subnets.public.ids
    security_groups  = [aws_security_group.task.id]
    assign_public_ip = true
  }

  # 正常起動後は停止scheduleを作り、起動途中の失敗はscriptがrollbackで停止を試みる。
  # deployment circuit breaker は従来どおり設けない。
  # lifecycle.ignore_changes[desired_count] も付けない。terraform applyが常に停止側へ倒れる挙動を意図している
}

output "cluster_name" { value = aws_ecs_cluster.this.name }
output "cluster_arn" { value = aws_ecs_cluster.this.arn }
output "service_name" { value = aws_ecs_service.this.name }
output "service_arn" { value = aws_ecs_service.this.id }
output "log_group_name" { value = aws_cloudwatch_log_group.task.name }
output "backend_prod_host" { value = local.backend_prod_host }
output "vpc_link_security_group_id" { value = aws_security_group.vpc_link.id }
output "vpc_link_subnet_ids" { value = data.aws_subnets.vpc_link.ids }
output "discovery_service_arn" { value = aws_service_discovery_service.backend.arn }
