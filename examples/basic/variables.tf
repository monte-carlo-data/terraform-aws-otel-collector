variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "deployment_name" {
  description = "Name of the deployment (used for naming resources)"
  type        = string
  default     = "example-otel-collector"
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
