# Athena Resources Module
# Copyright 2025 Monte Carlo Data, Inc.

# Local values
locals {
  grok_pattern     = "%%{GREEDYDATA:value}"
  s3_bucket_name   = split(":", var.telemetry_data_bucket_arn)[5]
  s3_traces_path   = "s3://${local.s3_bucket_name}/mcd/otel-collector/traces/"
  use_existing_sns = var.sns_topic_arn != ""
  sns_topic_arn    = local.use_existing_sns ? var.sns_topic_arn : aws_sns_topic.telemetry_notifications[0].arn
}

# Glue Classifier
resource "aws_glue_classifier" "grok_classifier" {
  name = "${var.deployment_name}-grok-classifier"

  grok_classifier {
    classification = "grok"
    grok_pattern   = local.grok_pattern
  }
}

# SNS Topic (only if not provided)
resource "aws_sns_topic" "telemetry_notifications" {
  count = local.use_existing_sns ? 0 : 1

  name = "${var.deployment_name}-telemetry-notifications"

  tags = var.common_tags
}

# SNS Topic Policy to allow S3 to publish (only if SNS topic was created)
resource "aws_sns_topic_policy" "telemetry_notifications_policy" {
  count = local.use_existing_sns ? 0 : 1

  arn = aws_sns_topic.telemetry_notifications[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.telemetry_notifications[0].arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = var.telemetry_data_bucket_arn
          }
        }
      }
    ]
  })
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
            "aws:SourceArn" = local.sns_topic_arn
          }
        }
      }
    ]
  })
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "sqs_subscription" {
  topic_arn = local.sns_topic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.crawler_queue.arn
}

# S3 Bucket Notification Configuration for OpenTelemetry Collector - SNS (only if SNS topic was created)
resource "aws_s3_bucket_notification" "storage_notification_sns" {
  count = local.use_existing_sns ? 0 : 1

  bucket = local.s3_bucket_name

  topic {
    id            = "${var.deployment_name}-glue-crawler-sns-notification"
    topic_arn     = aws_sns_topic.telemetry_notifications[0].arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = "mcd/otel-collector/"
  }

  depends_on = [
    aws_sns_topic.telemetry_notifications,
    aws_sns_topic_policy.telemetry_notifications_policy
  ]
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
        Sid    = "VisualEditor0"
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
          "sqs:GetQueueAttributes",
          "sqs:SetQueueAttributes",
          "sqs:PurgeQueue"
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

  recrawl_policy {
    recrawl_behavior = "CRAWL_EVENT_MODE"
  }


  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Tables = {
        AddOrUpdateBehavior = "MergeNewColumns",
        TableThreshold      = 1
      }
    }
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })

  tags = var.common_tags
}

# Lambda UDF Resources
# IAM Role for Lambda UDF
resource "aws_iam_role" "lambda_udf_role" {
  name = "${var.deployment_name}-lambda-udf-role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.common_tags
}

# Attach AWS managed policy for Lambda basic execution
resource "aws_iam_role_policy_attachment" "lambda_udf_basic_execution" {
  role       = aws_iam_role.lambda_udf_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Policy for Bedrock access
resource "aws_iam_role_policy" "lambda_udf_bedrock_policy" {
  name = "${var.deployment_name}-lambda-udf-bedrock-policy"
  role = aws_iam_role.lambda_udf_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowInvokeBedrock"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-*"
        ]
      }
    ]
  })
}

# Lambda Function for Athena UDF
resource "aws_lambda_function" "athena_udf" {
  # The function name must not be changed.
  function_name = "mcd-agent-observability-bedrock-udf"
  role          = aws_iam_role.lambda_udf_role.arn
  package_type  = "Image"
  image_uri     = var.lambda_udf_image_uri

  timeout     = var.lambda_udf_timeout
  memory_size = var.lambda_udf_memory_size

  image_config {
    command = ["handler.lambda_handler"]
  }

  tags = var.common_tags
}

