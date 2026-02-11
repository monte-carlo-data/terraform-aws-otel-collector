output "external_access_role_arn" {
  description = "The ARN of the IAM role for external access to the OpenTelemetry S3 bucket"
  value       = module.otel_collector.opentelemetry_collector_external_access_role_arn
}

output "external_access_role_name" {
  description = "The name of the IAM role for external access to the OpenTelemetry S3 bucket"
  value       = module.otel_collector.opentelemetry_collector_external_access_role_name
}
