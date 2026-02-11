output "grpc_endpoint" {
  description = "The gRPC endpoint for the OpenTelemetry Collector"
  value       = "${aws_lb.network_load_balancer.dns_name}:${var.grpc_port}"
}

output "http_endpoint" {
  description = "The HTTP endpoint for the OpenTelemetry Collector"
  value       = "http://${aws_lb.network_load_balancer.dns_name}:${var.http_port}"
}

output "security_group_id" {
  description = "The ID of the security group for the OpenTelemetry Collector"
  value       = aws_security_group.security_group.id
}

output "task_role_arn" {
  description = "The ARN of the task role used by the OpenTelemetry Collector"
  value       = aws_iam_role.task_role.arn
}
