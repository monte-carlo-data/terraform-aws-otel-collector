# Basic Example

This example demonstrates the basic usage of the OpenTelemetry Collector Terraform module.

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
- `deployment_name`: (Optional) Name for the deployment (default: "example-otel-collector")
- `task_desired_count`: (Optional) Number of tasks to run (default: 2)
- `task_cpu`: (Optional) CPU units for each task (default: 1024)
- `task_memory`: (Optional) Memory in MB for each task (default: 2048)

## Outputs

- `grpc_endpoint`: gRPC endpoint URL for sending telemetry data
- `http_endpoint`: HTTP endpoint URL for sending telemetry data
- `external_access_role_arn`: IAM role ARN for external access to S3 bucket
- `security_group_id`: Security group ID for the OpenTelemetry Collector
