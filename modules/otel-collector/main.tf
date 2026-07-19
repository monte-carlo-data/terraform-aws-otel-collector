# OpenTelemetry Collector resources (ECS + NLB + IAM)

data "aws_region" "current" {}

locals {
  has_additional_security_group = var.existing_security_group_id != "N/A" && var.existing_security_group_id != ""
  external_s3_bucket_name       = split(":", var.telemetry_data_bucket_arn)[5]
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/ecs/${var.deployment_name}-otel-collector"
  retention_in_days = 14

  tags = var.common_tags
}

resource "aws_security_group" "security_group" {
  name_prefix = "${var.deployment_name}-otel-collector-"
  description = "Security group for OpenTelemetry Collector containers"
  vpc_id      = var.existing_vpc_id

  tags = var.common_tags
}

resource "aws_security_group_rule" "security_group_ingress" {
  type                     = "ingress"
  from_port                = 4317
  to_port                  = 4318
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.security_group.id
  security_group_id        = aws_security_group.security_group.id
  description              = "Allow TCP ingress on ports 4317 and 4318 from other resources associated with the security group within the VPC"
}

resource "aws_lb" "network_load_balancer" {
  name               = "${var.deployment_name}-otel-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.existing_subnet_ids

  security_groups = local.has_additional_security_group ? [
    aws_security_group.security_group.id,
    var.existing_security_group_id
  ] : [aws_security_group.security_group.id]

  tags = var.common_tags
}

resource "aws_lb_target_group" "target_group_grpc" {
  name        = "${var.deployment_name}-otel-grpc-tg"
  port        = var.grpc_port
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = var.existing_vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = var.common_tags
}

resource "aws_lb_target_group" "target_group_http" {
  name        = "${var.deployment_name}-otel-http-tg"
  port        = var.http_port
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = var.existing_vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = var.common_tags
}

resource "aws_lb_listener" "listener_grpc" {
  load_balancer_arn = aws_lb.network_load_balancer.arn
  port              = var.grpc_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_grpc.arn
  }
}

resource "aws_lb_listener" "listener_http" {
  load_balancer_arn = aws_lb.network_load_balancer.arn
  port              = var.http_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_http.arn
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.deployment_name}-otel-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.common_tags
}

resource "aws_iam_role" "task_execution_role" {
  name = "${var.deployment_name}-otel-task-execution-role"
  path = "/"

  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task_role" {
  name = "${var.deployment_name}-otel-task-role"
  path = "/"

  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "task_role_s3_policy" {
  name = "${var.deployment_name}-S3Export"
  role = aws_iam_role.task_role.id

  policy = jsonencode({
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketLocation"
        ]
        Effect = "Allow"
        Resource = [
          "${var.telemetry_data_bucket_arn}/mcd/otel-collector/*",
          var.telemetry_data_bucket_arn
        ]
      }
    ]
  })
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "${var.deployment_name}-otel-collector"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "otel-collector"
      image     = var.container_image
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.log_group.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "otel-collector"
        }
      }

      portMappings = [
        {
          containerPort = var.grpc_port
          protocol      = "tcp"
        },
        {
          containerPort = var.http_port
          protocol      = "tcp"
        }
      ]

      command = [
        "--config",
        "env:OTEL_CONFIG_CONTENT"
      ]

      environment = [
        {
          name  = "AWS_REGION"
          value = data.aws_region.current.name
        },
        {
          name  = "OTEL_CONFIG_CONTENT"
          value = <<-EOT
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:${var.grpc_port}
      http:
        endpoint: 0.0.0.0:${var.http_port}

processors:
  batch:
    timeout: ${var.batch_timeout}
    send_batch_size: ${var.batch_size}
  memory_limiter:
    check_interval: 1s
    limit_mib: ${var.memory_limit_mib}
    spike_limit_mib: ${var.memory_spike_limit_mib}

exporters:
  debug:
    verbosity: detailed
  awss3/traces:
    s3uploader:
      region: ${data.aws_region.current.name}
      s3_bucket: ${local.external_s3_bucket_name}
      s3_base_prefix: mcd/otel-collector/traces
      file_prefix: traces
      # Pin the exporter default: downstream Glue/Athena resources (partition
      # projection) depend on this exact layout, so don't let it drift with
      # collector upgrades.
      s3_partition_format: 'year=%Y/month=%m/day=%d/hour=%H/minute=%M'
    resource_attrs_to_s3:
      s3_prefix: "service.name"
  awss3/metrics:
    s3uploader:
      region: ${data.aws_region.current.name}
      s3_bucket: ${local.external_s3_bucket_name}
      s3_base_prefix: mcd/otel-collector/metrics
      file_prefix: metrics
      s3_partition_format: 'year=%Y/month=%m/day=%d/hour=%H/minute=%M'
    resource_attrs_to_s3:
      s3_prefix: "service.name"
  awss3/logs:
    s3uploader:
      region: ${data.aws_region.current.name}
      s3_bucket: ${local.external_s3_bucket_name}
      s3_base_prefix: mcd/otel-collector/logs
      file_prefix: logs
      s3_partition_format: 'year=%Y/month=%m/day=%d/hour=%H/minute=%M'
    resource_attrs_to_s3:
      s3_prefix: "service.name"

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [debug, awss3/traces]
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [debug, awss3/metrics]
    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [debug, awss3/logs]
EOT
        }
      ]
    }
  ])

  tags = var.common_tags
}

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.deployment_name}-otel-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = var.task_desired_count
  launch_type     = "FARGATE"

  enable_ecs_managed_tags = true

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group_grpc.arn
    container_name   = "otel-collector"
    container_port   = var.grpc_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group_http.arn
    container_name   = "otel-collector"
    container_port   = var.http_port
  }

  network_configuration {
    assign_public_ip = false
    security_groups = local.has_additional_security_group ? [
      aws_security_group.security_group.id,
      var.existing_security_group_id
    ] : [aws_security_group.security_group.id]
    subnets = var.existing_subnet_ids
  }

  depends_on = [
    aws_lb_listener.listener_grpc,
    aws_lb_listener.listener_http
  ]

  tags = var.common_tags
}
