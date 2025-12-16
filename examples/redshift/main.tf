terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "otel_collector" {
  source = "../../"

  deployment_name            = var.deployment_name
  existing_vpc_id            = var.existing_vpc_id
  existing_subnet_ids        = var.existing_subnet_ids
  telemetry_data_bucket_arn  = var.telemetry_data_bucket_arn
  existing_security_group_id = var.existing_security_group_id

  # Optional customizations
  task_desired_count = var.task_desired_count
  task_cpu           = var.task_cpu
  task_memory        = var.task_memory

  # Enable Redshift Lambda UDF and IAM Role for Redshift External Function
  deploy_redshift_resources = true

  # Optional Redshift Lambda UDF customizations
  redshift_lambda_timeout     = var.redshift_lambda_timeout != null ? var.redshift_lambda_timeout : 600
  redshift_lambda_memory_size = var.redshift_lambda_memory_size != null ? var.redshift_lambda_memory_size : 512
}

