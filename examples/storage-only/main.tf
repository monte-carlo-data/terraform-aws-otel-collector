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

  deployment_name             = var.deployment_name
  deploy_otel_collector       = false
  telemetry_data_bucket_arn   = var.telemetry_data_bucket_arn
  mcd_otel_collector_role_arn = var.mcd_otel_collector_role_arn
  vpc_endpoint_id             = var.vpc_endpoint_id
}
