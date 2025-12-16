# Redshift Example

This example demonstrates the usage of the OpenTelemetry Collector Terraform module with the Redshift Lambda UDF enabled for invoking Bedrock models. This Lambda is required for Monte Carlo Agent Observability when AI Agent traces are written to Redshift. This Lambda will be invoked via an external function in Redshift queries.

## Overview

This example deploys:
- The standard OpenTelemetry Collector infrastructure
- A Lambda function that can be used as a Redshift External Function to invoke Claude models via AWS Bedrock

## Usage

1. Set the required variables in `terraform.tfvars`:

```hcl
existing_vpc_id           = "vpc-12345678"
existing_subnet_ids       = ["subnet-12345678", "subnet-87654321"]
telemetry_data_bucket_arn = "arn:aws:s3:::my-telemetry-bucket"
```

2. Run Terraform:

```bash
terraform init
terraform plan
terraform apply
```

## Variables

- `existing_vpc_id`: Your VPC ID where the collector will be deployed
- `existing_subnet_ids`: List of at least 2 private subnet IDs
- `telemetry_data_bucket_arn`: ARN of your S3 bucket for storing telemetry data
- `deployment_name`: (Optional) Name for the deployment (default: "example-otel-collector-redshift")
- `task_desired_count`: (Optional) Number of tasks to run (default: 2)
- `task_cpu`: (Optional) CPU units for each task (default: 1024)
- `task_memory`: (Optional) Memory in MB for each task (default: 2048)

## Outputs

### OpenTelemetry Collector
- `grpc_endpoint`: gRPC endpoint URL for sending telemetry data
- `http_endpoint`: HTTP endpoint URL for sending telemetry data
- `external_access_role_arn`: IAM role ARN for external access to S3 bucket
- `security_group_id`: Security group ID for the OpenTelemetry Collector

### Redshift Lambda UDF
- `redshift_bedrock_udf_lambda_arn`: ARN of the Lambda function for Redshift Bedrock UDF
- `redshift_bedrock_udf_lambda_function_name`: Name of the Lambda function

## Using the Lambda with Redshift

After deployment, you can create a Redshift External Function that uses this Lambda:

```sql
CREATE EXTERNAL FUNCTION invoke_bedrock_claude(
    model_id VARCHAR(255),
    prompt VARCHAR(MAX),
    model_params VARCHAR(MAX),
    tool_config VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
STABLE
LAMBDA '<lambda_function_name>'
IAM_ROLE '<redshift_cluster_iam_role_arn>';
```

The Lambda function expects:
- `model_id`: The Claude Bedrock model ID (e.g., "anthropic.claude-3-sonnet-20240229-v1:0")
- `prompt`: The prompt text to send to the model
- `model_params`: (Optional) JSON string with model parameters (maxTokens, temperature, topP)
- `tool_config`: (Optional) JSON string with tool configuration

## IAM Permissions

The Lambda execution role has permissions to:
- Invoke Bedrock models matching `arn:aws:bedrock:*::foundation-model/anthropic.claude-*`
- Write logs to CloudWatch

Your Redshift cluster's IAM role needs permission to invoke the Lambda function.

