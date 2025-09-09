output "grpc_endpoint" {
  description = "The gRPC endpoint for the OpenTelemetry Collector"
  value       = module.otel_collector.opentelemetry_collector_grpc_endpoint
}

output "http_endpoint" {
  description = "The HTTP endpoint for the OpenTelemetry Collector"
  value       = module.otel_collector.opentelemetry_collector_http_endpoint
}

output "external_access_role_arn" {
  description = "The ARN of the IAM role for external access to the OpenTelemetry S3 bucket"
  value       = module.otel_collector.opentelemetry_collector_external_access_role_arn
}

output "external_access_role_name" {
  description = "The name of the IAM role for external access to the OpenTelemetry S3 bucket"
  value       = module.otel_collector.opentelemetry_collector_external_access_role_name
}

output "security_group_id" {
  description = "The ID of the security group for the OpenTelemetry Collector"
  value       = module.otel_collector.opentelemetry_collector_security_group_id
}
