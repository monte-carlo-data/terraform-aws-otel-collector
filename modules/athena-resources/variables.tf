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
  description = "ARN of the SNS topic to subscribe the SQS queue to"
  type        = string
}

variable "telemetry_data_bucket_arn" {
  description = "ARN of the S3 bucket containing telemetry data"
  type        = string
}

