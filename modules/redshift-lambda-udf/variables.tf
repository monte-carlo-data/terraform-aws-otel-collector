# Variables for Redshift Lambda UDF Module

variable "deployment_name" {
  description = "Name of the deployment (used for naming resources)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

