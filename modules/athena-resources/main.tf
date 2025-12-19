# Athena Resources Module
# Copyright 2025 Monte Carlo Data, Inc.

# Local values
locals {
  grok_pattern   = "%%{GREEDYDATA:value}"
  s3_bucket_name = split(":", var.telemetry_data_bucket_arn)[5]
  s3_traces_path = "s3://${local.s3_bucket_name}/mcd/otel-collector/traces"
}

# Glue Classifier
resource "aws_glue_classifier" "grok_classifier" {
  name = "${var.deployment_name}-grok-classifier"

  grok_classifier {
    classification = "grok"
    grok_pattern   = local.grok_pattern
  }

  tags = var.common_tags
}

# SQS Queue
resource "aws_sqs_queue" "crawler_queue" {
  name                      = "${var.deployment_name}-glue-crawler-queue"
  message_retention_seconds = 1209600 # 14 days
  receive_wait_time_seconds = 20      # Long polling

  tags = var.common_tags
}

# SQS Queue Policy for SNS subscription
resource "aws_sqs_queue_policy" "crawler_queue_policy" {
  queue_url = aws_sqs_queue.crawler_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.crawler_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = var.sns_topic_arn
          }
        }
      }
    ]
  })
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "sqs_subscription" {
  topic_arn = var.sns_topic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.crawler_queue.arn
}

# IAM Role for Glue Crawler
resource "aws_iam_role" "glue_crawler_role" {
  name = "${var.deployment_name}-glue-crawler-role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.common_tags
}

# Attach AWS managed policy for Glue Service Role
resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# IAM Policy for S3 access
resource "aws_iam_role_policy" "glue_crawler_s3_policy" {
  name = "${var.deployment_name}-glue-crawler-s3-policy"
  role = aws_iam_role.glue_crawler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.telemetry_data_bucket_arn,
          "${var.telemetry_data_bucket_arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy for SQS access
resource "aws_iam_role_policy" "glue_crawler_sqs_policy" {
  name = "${var.deployment_name}-glue-crawler-sqs-policy"
  role = aws_iam_role.glue_crawler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.crawler_queue.arn
      }
    ]
  })
}

# Glue Database
resource "aws_glue_catalog_database" "telemetry_database" {
  name        = "${var.deployment_name}-telemetry-db"
  description = "Database for OpenTelemetry telemetry data"

  tags = var.common_tags
}

# Glue Crawler
resource "aws_glue_crawler" "telemetry_crawler" {
  name          = "${var.deployment_name}-telemetry-crawler"
  role          = aws_iam_role.glue_crawler_role.arn
  database_name = aws_glue_catalog_database.telemetry_database.name
  classifiers   = [aws_glue_classifier.grok_classifier.name]

  s3_target {
    path            = local.s3_traces_path
    event_queue_arn = aws_sqs_queue.crawler_queue.arn
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  table_prefix = "traces"

  recrawl_policy {
    recrawl_behavior = "CRAWL_NEW_FOLDERS_ONLY"
  }

  tags = var.common_tags
}


