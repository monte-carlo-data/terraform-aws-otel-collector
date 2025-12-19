# Outputs for Athena Resources Module

output "glue_classifier_name" {
  description = "The name of the Glue classifier"
  value       = aws_glue_classifier.grok_classifier.name
}

output "sqs_queue_arn" {
  description = "The ARN of the SQS queue for the Glue crawler"
  value       = aws_sqs_queue.crawler_queue.arn
}

output "sqs_queue_url" {
  description = "The URL of the SQS queue for the Glue crawler"
  value       = aws_sqs_queue.crawler_queue.url
}

output "glue_crawler_role_arn" {
  description = "The ARN of the IAM role for the Glue crawler"
  value       = aws_iam_role.glue_crawler_role.arn
}

output "glue_crawler_role_name" {
  description = "The name of the IAM role for the Glue crawler"
  value       = aws_iam_role.glue_crawler_role.name
}

output "glue_crawler_name" {
  description = "The name of the Glue crawler"
  value       = aws_glue_crawler.telemetry_crawler.name
}

output "glue_database_name" {
  description = "The name of the Glue catalog database"
  value       = aws_glue_catalog_database.telemetry_database.name
}

