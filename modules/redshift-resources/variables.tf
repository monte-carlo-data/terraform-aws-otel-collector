# Variables for Redshift Lambda UDF Module

variable "deployment_name" {
  description = "Name of the deployment (used for naming resources)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "lambda_timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  default     = 600 # 10 minutes
  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds (15 minutes)."
  }
}

variable "lambda_memory_size" {
  description = "Memory size for the Lambda function in MB"
  type        = number
  default     = 512 # 512 MB
  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240 && var.lambda_memory_size % 64 == 0
    error_message = "Lambda memory size must be between 128 and 10240 MB, and must be a multiple of 64."
  }
}

variable "s3_bucket_name" {
  description = "S3 bucket name for Redshift auto-copy access"
  type        = string
}

