# Outputs for Redshift Lambda UDF Module

output "lambda_arn" {
  description = "The ARN of the Lambda function for Redshift Bedrock UDF"
  value       = aws_lambda_function.redshift_bedrock_udf.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function for Redshift Bedrock UDF"
  value       = aws_lambda_function.redshift_bedrock_udf.function_name
}

output "lambda_execution_role_arn" {
  description = "The ARN of the IAM role for the Lambda function"
  value       = aws_iam_role.lambda_execution_role.arn
}

