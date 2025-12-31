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

