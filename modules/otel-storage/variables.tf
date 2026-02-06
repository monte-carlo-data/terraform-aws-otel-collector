variable "deployment_name" {
  description = "Name of the deployment (used for naming resources)"
  type        = string
}

variable "telemetry_data_bucket_arn" {
  description = "ARN of the S3 bucket to store OpenTelemetry data such as traces, metrics, and logs."
  type        = string
}

variable "external_id" {
  description = "External ID to access the S3 bucket. Update this value later after the stack is created."
  type        = string
  default     = "N/A"
}

variable "external_access_principal" {
  description = "Principal (AWS ARN/account ID or Federated identifier) allowed to assume the external access role."
  type        = string
  default     = "N/A"
}

variable "external_access_principal_type" {
  description = "Type of principal for external access role"
  type        = string
  default     = "AWS"
  validation {
    condition     = contains(["AWS", "Federated"], var.external_access_principal_type)
    error_message = "External access principal type must be either 'AWS' or 'Federated'."
  }
}

variable "external_access_role_name" {
  description = "Custom name of the external access role. If left empty, will use the default name."
  type        = string
  default     = "N/A"
}

variable "mcd_otel_collector_role_arn" {
  description = "ARN of the role that should be granted write access to the telemetry S3 bucket."
  type        = string
}

variable "vpc_endpoint_id" {
  description = "Optional VPC endpoint ID to restrict S3 writes to that endpoint."
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
