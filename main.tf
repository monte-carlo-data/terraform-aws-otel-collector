# Monte Carlo's OpenTelemetry Collector Service - Terraform Configuration
# Copyright 2025 Monte Carlo Data, Inc.

locals {
  common_tags = {
    Service  = "mcd-otel-collector"
    Provider = "monte-carlo"
  }

  collector_role_arn = var.deploy_otel_collector ? module.otel_collector[0].task_role_arn : var.mcd_otel_collector_task_role_arn
}

module "otel_collector" {
  source = "./modules/otel-collector"
  count  = var.deploy_otel_collector ? 1 : 0

  deployment_name            = var.deployment_name
  existing_vpc_id            = var.existing_vpc_id
  existing_subnet_ids        = var.existing_subnet_ids
  telemetry_data_bucket_arn  = var.telemetry_data_bucket_arn
  existing_security_group_id = var.existing_security_group_id
  grpc_port                  = var.grpc_port
  http_port                  = var.http_port
  task_desired_count         = var.task_desired_count
  task_cpu                   = var.task_cpu
  task_memory                = var.task_memory
  container_image            = var.container_image
  batch_timeout              = var.batch_timeout
  batch_size                 = var.batch_size
  memory_limit_mib           = var.memory_limit_mib
  memory_spike_limit_mib     = var.memory_spike_limit_mib
  common_tags                = local.common_tags
}

module "otel_storage" {
  source = "./modules/otel-storage"

  deployment_name                  = var.deployment_name
  telemetry_data_bucket_arn        = var.telemetry_data_bucket_arn
  external_id                      = var.external_id
  external_access_principal        = var.external_access_principal
  external_access_principal_type   = var.external_access_principal_type
  external_access_role_name        = var.external_access_role_name
  mcd_otel_collector_task_role_arn = local.collector_role_arn
  vpc_endpoint_id                  = var.vpc_endpoint_id
  common_tags                      = local.common_tags
}

module "athena_resources" {
  source = "./modules/athena-resources"
  count  = var.deploy_athena_resources ? 1 : 0

  deployment_name           = var.deployment_name
  common_tags               = local.common_tags
  sns_topic_arn             = var.telemetry_data_bucket_notification_sns_topic_arn
  telemetry_data_bucket_arn = var.telemetry_data_bucket_arn
}


