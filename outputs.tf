# Outputs for Monte Carlo's OpenTelemetry Collector Service

output "opentelemetry_collector_grpc_endpoint" {
  description = "The gRPC endpoint for the OpenTelemetry Collector"
  value       = var.deploy_otel_collector ? module.otel_collector[0].grpc_endpoint : null
}

output "opentelemetry_collector_http_endpoint" {
  description = "The HTTP endpoint for the OpenTelemetry Collector"
  value       = var.deploy_otel_collector ? module.otel_collector[0].http_endpoint : null
}

output "opentelemetry_collector_external_access_role_arn" {
  description = "The ARN of the IAM role for external access to the OpenTelemetry S3 bucket"
  value       = module.otel_storage.external_access_role_arn
}

output "opentelemetry_collector_external_access_role_name" {
  description = "The name of the IAM role for external access to the OpenTelemetry S3 bucket"
  value       = module.otel_storage.external_access_role_name
}

output "opentelemetry_collector_security_group_id" {
  description = "The ID of the security group for the OpenTelemetry Collector"
  value       = var.deploy_otel_collector ? module.otel_collector[0].security_group_id : null
}

output "telemetry_data_bucket_arn" {
  description = "The ARN of the telemetry S3 bucket (created or provided)."
  value       = module.otel_storage.telemetry_data_bucket_arn
}

output "athena_glue_classifier_name" {
  description = "The name of the Glue classifier for Athena"
  value       = var.deploy_athena_resources ? module.athena_resources[0].glue_classifier_name : null
}

output "athena_sqs_queue_arn" {
  description = "The ARN of the SQS queue for the Glue crawler"
  value       = var.deploy_athena_resources ? module.athena_resources[0].sqs_queue_arn : null
}

output "athena_sqs_queue_url" {
  description = "The URL of the SQS queue for the Glue crawler"
  value       = var.deploy_athena_resources ? module.athena_resources[0].sqs_queue_url : null
}

output "athena_glue_crawler_role_arn" {
  description = "The ARN of the IAM role for the Glue crawler"
  value       = var.deploy_athena_resources ? module.athena_resources[0].glue_crawler_role_arn : null
}

output "athena_glue_crawler_role_name" {
  description = "The name of the IAM role for the Glue crawler"
  value       = var.deploy_athena_resources ? module.athena_resources[0].glue_crawler_role_name : null
}

output "athena_glue_crawler_name" {
  description = "The name of the Glue crawler"
  value       = var.deploy_athena_resources ? module.athena_resources[0].glue_crawler_name : null
}

output "athena_glue_database_name" {
  description = "The name of the Glue catalog database"
  value       = var.deploy_athena_resources ? module.athena_resources[0].glue_database_name : null
}

output "athena_sns_topic_arn" {
  description = "The ARN of the SNS topic used for notifications (either provided or created)"
  value       = var.deploy_athena_resources ? module.athena_resources[0].sns_topic_arn : null
}

output "athena_lambda_udf_function_arn" {
  description = "The ARN of the Lambda UDF function for Athena"
  value       = var.deploy_athena_resources ? module.athena_resources[0].lambda_udf_function_arn : null
}

output "athena_lambda_udf_function_name" {
  description = "The name of the Lambda UDF function for Athena"
  value       = var.deploy_athena_resources ? module.athena_resources[0].lambda_udf_function_name : null
}

output "athena_lambda_udf_role_arn" {
  description = "The ARN of the IAM role for the Lambda UDF function"
  value       = var.deploy_athena_resources ? module.athena_resources[0].lambda_udf_role_arn : null
}
