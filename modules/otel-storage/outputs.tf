output "external_access_role_arn" {
  description = "The ARN of the IAM role for external access to the OpenTelemetry S3 bucket"
  value       = aws_iam_role.external_access_role.arn
}

output "external_access_role_name" {
  description = "The name of the IAM role for external access to the OpenTelemetry S3 bucket"
  value       = aws_iam_role.external_access_role.name
}
