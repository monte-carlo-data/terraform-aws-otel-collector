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
  default     = "404798114945.dkr.ecr.us-east-1.amazonaws.com/saas-otel-otel-aws-athena-lambda-udf:latest"
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


