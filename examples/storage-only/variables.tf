variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "deployment_name" {
  description = "Name of the deployment (used for naming resources)"
  type        = string
  default     = "example-otel-storage"
}

variable "telemetry_data_bucket_arn" {
  description = "ARN of the S3 bucket to store OpenTelemetry data"
  type        = string
}

variable "mcd_otel_collector_task_role_arn" {
  description = "ARN of the role that should be granted write access to the telemetry S3 bucket"
  type        = string
}

variable "vpc_endpoint_id" {
  description = "Optional VPC endpoint ID to restrict S3 writes to that endpoint"
  type        = string
  default     = ""
}
