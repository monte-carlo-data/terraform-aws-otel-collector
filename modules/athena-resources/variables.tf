# Variables for Athena Resources Module

variable "deployment_name" {
  description = "Name of the deployment (used for naming resources)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "sns_topic_arn" {
  description = "Optional ARN of the SNS topic to subscribe the SQS queue to. If not provided (empty string), a SNS topic will be created and S3 bucket notifications will be created to the new SNS topic."
  type        = string
  default     = ""
}

variable "telemetry_data_bucket_arn" {
  description = "ARN of the S3 bucket containing telemetry data"
  type        = string
}

variable "lambda_udf_image_uri" {
  description = "Full Docker image URI for the Lambda UDF function"
  type        = string
  default     = "752656882040.dkr.ecr.us-east-1.amazonaws.com/mcd-otel-aws-athena-lambda-udf:latest"
}

variable "lambda_udf_timeout" {
  description = "Timeout in seconds for the Lambda UDF function"
  type        = number
  default     = 300
}

variable "lambda_udf_memory_size" {
  description = "Memory size in MB for the Lambda UDF function"
  type        = number
  default     = 1024
}

variable "enable_partition_projection" {
  description = "Declare the traces Glue table with Athena partition projection enabled. Athena then computes partition locations from the projection ranges instead of enumerating the Glue catalog, keeping multi-day queries fast as minute-grained partitions accumulate. Requires telemetry_service_names."
  type        = bool
  default     = false
}

variable "telemetry_service_names" {
  description = "OpenTelemetry service.name values your agents emit (the collector writes each service's traces under its own S3 path segment). Used as the enum values for the service partition projection; required when enable_partition_projection is true."
  type        = list(string)
  default     = []

  validation {
    condition     = !var.enable_partition_projection || length(var.telemetry_service_names) > 0
    error_message = "telemetry_service_names must list at least one service.name value when enable_partition_projection is true."
  }
}

variable "projection_year_range" {
  description = "Inclusive year range for Athena partition projection, as \"min,max\" (e.g. \"2025,2032\"). Keep the range tight: every extra year adds ~526k virtual partitions to the unpruned enumeration space."
  type        = string
  default     = "2025,2032"

  validation {
    condition     = can(regex("^[0-9]{4},[0-9]{4}$", var.projection_year_range))
    error_message = "projection_year_range must be two 4-digit years separated by a comma, e.g. \"2025,2032\"."
  }
}


