# OpenTelemetry storage access resources (bucket policy + external access role)

data "aws_caller_identity" "current" {}

locals {
  use_current_account                  = var.external_access_principal == "N/A"
  use_aws_principal                    = var.external_access_principal_type == "AWS"
  use_custom_external_access_role_name = var.external_access_role_name != "N/A"
  external_access_role_name            = local.use_custom_external_access_role_name ? var.external_access_role_name : "${var.deployment_name}-EAR"
  telemetry_bucket_name                = var.telemetry_data_bucket_arn != "" ? split(":", var.telemetry_data_bucket_arn)[5] : "${var.deployment_name}-otel-storage"
  telemetry_bucket_arn                 = var.telemetry_data_bucket_arn != "" ? var.telemetry_data_bucket_arn : aws_s3_bucket.telemetry[0].arn
}

resource "aws_s3_bucket" "telemetry" {
  count  = var.telemetry_data_bucket_arn == "" ? 1 : 0
  bucket = local.telemetry_bucket_name

  tags = var.common_tags
}

resource "aws_iam_role" "external_access_role" {
  name = local.external_access_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = local.use_current_account ? {
          AWS = [data.aws_caller_identity.current.account_id]
          } : (local.use_aws_principal ? {
            AWS = [
              var.external_access_principal,
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.external_access_role_name}"
            ]
            } : {
            Federated = [var.external_access_principal]
        })
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_policy" "external_access_s3_read_only_policy" {
  name = "${var.deployment_name}-OpenTelemetryS3ExternalAccessReadOnly"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetObjectVersion"
        ]
        Resource = [
          local.telemetry_bucket_arn,
          "${local.telemetry_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_access_policy_attachment" {
  role       = aws_iam_role.external_access_role.name
  policy_arn = aws_iam_policy.external_access_s3_read_only_policy.arn
}

data "aws_iam_policy_document" "collector_bucket_policy" {
  statement {
    sid    = "DenyActionsWithoutSSL"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["*"]

    resources = [
      local.telemetry_bucket_arn,
      "${local.telemetry_bucket_arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowCollectorWrite"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.mcd_otel_collector_task_role_arn]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetBucketLocation"
    ]

    resources = [
      local.telemetry_bucket_arn,
      "${local.telemetry_bucket_arn}/mcd/otel-collector/*"
    ]

    dynamic "condition" {
      for_each = var.vpc_endpoint_id == null || var.vpc_endpoint_id == "" ? [] : [var.vpc_endpoint_id]
      content {
        test     = "StringEquals"
        variable = "aws:sourceVpce"
        values   = [condition.value]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "collector_write_policy" {
  bucket = local.telemetry_bucket_name
  policy = data.aws_iam_policy_document.collector_bucket_policy.json
}
