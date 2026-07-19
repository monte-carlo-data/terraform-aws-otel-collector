variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "deployment_name" {
  description = "Name of the deployment (used for naming resources)"
  type        = string
  default     = "example-otel-collector-athena"
}

variable "existing_vpc_id" {
  description = "VPC ID to deploy the OpenTelemetry Collector into"
  type        = string
}

variable "existing_subnet_ids" {
  description = "List of private subnet IDs (at least 2) for deploying the OpenTelemetry Collector"
  type        = list(string)
}

variable "telemetry_data_bucket_arn" {
  description = "ARN of the S3 bucket to store OpenTelemetry data"
  type        = string
}

variable "telemetry_data_bucket_notification_sns_topic_arn" {
  description = "ARN of an existing SNS topic that will publish notifications when new data is written to the telemetry S3 bucket. If not provided, the module will create a new SNS topic and configure S3 bucket notifications automatically."
  type        = string
  default     = ""
}

variable "existing_security_group_id" {
  description = "Optional additional security group ID to attach to the OpenTelemetry Collector resources"
  type        = string
  default     = "N/A"
}

variable "task_desired_count" {
  description = "Desired number of running tasks for the OpenTelemetry Collector service"
  type        = number
  default     = 2
}

variable "task_cpu" {
  description = "CPU units for the task (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Memory for the task in MB"
  type        = number
  default     = 2048
}

variable "enable_partition_projection" {
  description = "Declare the traces Glue table with Athena partition projection enabled (recommended). Requires telemetry_service_names."
  type        = bool
  default     = false
}

variable "telemetry_service_names" {
  description = "OpenTelemetry service.name values your agents emit. Required when enable_partition_projection is true."
  type        = list(string)
  default     = []
}

variable "projection_year_range" {
  description = "Inclusive year range for Athena partition projection, as \"min,max\"."
  type        = string
  default     = "2025,2032"
}

