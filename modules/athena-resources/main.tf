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
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.glue_crawler_role.arn
        }
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

# Glue Table for traces (declared only when partition projection is enabled).
#
# Without this resource the crawler creates and owns the table, and Athena enumerates
# every crawler-registered partition (one per minute of telemetry) when planning a
# query — enumeration cost grows unboundedly with data age. Declaring the table lets
# us attach Athena partition-projection parameters so partition locations are computed
# from the ranges below instead. The crawler still runs against the same table: its
# Tables.AddOrUpdateBehavior=MergeNewColumns update path only adds columns and never
# removes table parameters, so projection settings and the crawler coexist.
resource "aws_glue_catalog_table" "traces" {
  count = var.enable_partition_projection ? 1 : 0

  name          = "traces"
  database_name = aws_glue_catalog_database.telemetry_database.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    classification = "traces"

    "projection.enabled" = "true"
    # The collector writes traces under a bare <service.name> path segment; the
    # crawler surfaces it as the leading string partition column partition_0.
    "projection.partition_0.type"   = "enum"
    "projection.partition_0.values" = join(",", var.telemetry_service_names)
    "projection.year.type"          = "integer"
    "projection.year.range"         = var.projection_year_range
    "projection.month.type"         = "integer"
    "projection.month.range"        = "1,12"
    "projection.month.digits"       = "2"
    "projection.day.type"           = "integer"
    "projection.day.range"          = "1,31"
    "projection.day.digits"         = "2"
    "projection.hour.type"          = "integer"
    "projection.hour.range"         = "0,23"
    "projection.hour.digits"        = "2"
    "projection.minute.type"        = "integer"
    "projection.minute.range"       = "0,59"
    "projection.minute.digits"      = "2"
    # $${...} renders literal ${...} — Athena substitutes these, not Terraform.
    "storage.location.template" = "${local.s3_traces_path}$${partition_0}/year=$${year}/month=$${month}/day=$${day}/hour=$${hour}/minute=$${minute}"
  }

  storage_descriptor {
    location      = local.s3_traces_path
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "com.amazonaws.glue.serde.GrokSerDe"
      parameters = {
        "input.format" = local.grok_pattern
      }
    }

    columns {
      name = "value"
      type = "string"
    }
  }

  partition_keys {
    name = "partition_0" # service.name path segment
    type = "string"
  }
  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }
  partition_keys {
    name = "hour"
    type = "string"
  }
  partition_keys {
    name = "minute"
    type = "string"
  }

  lifecycle {
    # The crawler keeps updating table statistics on every run and may add columns
    # via MergeNewColumns; don't fight it on plan. Projection parameters stay
    # Terraform-managed.
    ignore_changes = [
      storage_descriptor[0].columns,
      parameters["averageRecordSize"],
      parameters["compressionType"],
      parameters["CrawlerSchemaDeserializerVersion"],
      parameters["CrawlerSchemaSerializerVersion"],
      parameters["CRAWL_RUN_ID"],
      parameters["grokPattern"],
      parameters["objectCount"],
      parameters["partition_filtering.enabled"],
      parameters["recordCount"],
      parameters["sizeKey"],
      parameters["typeOfData"],
      parameters["UPDATED_BY_CRAWLER"],
    ]
  }
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

  schedule = "cron(*/30 * * * ? *)"

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
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

  # When the traces table is declared (partition projection), it must exist before
  # the first crawl so the crawler takes its update path instead of creating the table.
  depends_on = [aws_glue_catalog_table.traces]
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
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-*",
          "arn:aws:bedrock:*:*:inference-profile/*anthropic.claude-*"
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

