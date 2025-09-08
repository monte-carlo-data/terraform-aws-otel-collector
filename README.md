# Monte Carlo AWS OpenTelemetry Collector Module

A Terraform module that deploys Monte Carlo's OpenTelemetry Collector Service on AWS ECS Fargate.

## Architecture

This module creates:
- ECS Fargate cluster and service
- Network Load Balancer with gRPC and HTTP listeners
- Security groups and IAM roles
- CloudWatch log group
- External access role for S3 bucket access

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- Existing VPC with at least 2 private subnets
- S3 bucket for storing telemetry data

## Usage

### Basic Example

```hcl
module "otel_collector" {
  source = "monte-carlo-data/terraform-aws-otel-collector"

  deployment_name           = "my-otel-collector"
  existing_vpc_id           = "vpc-12345678"
  existing_subnet_ids       = ["subnet-12345678", "subnet-87654321"]
  telemetry_data_bucket_arn = "arn:aws:s3:::my-telemetry-bucket"
}
```

### Advanced Example

```hcl
module "otel_collector" {
  source = "monte-carlo-data/terraform-aws-otel-collector"

  # Required variables
  deployment_name           = "production-otel-collector"
  existing_vpc_id           = "vpc-12345678"
  existing_subnet_ids       = ["subnet-12345678", "subnet-87654321"]
  telemetry_data_bucket_arn = "arn:aws:s3:::my-telemetry-bucket"

  # Optional customizations
  existing_security_group_id = "sg-12345678"
  task_desired_count         = 3
  task_cpu                   = 2048
  task_memory                = 4096

  # External access configuration
  external_id                        = "secure-random-string"
  external_access_principal          = "arn:aws:iam::123456789012:root"
  external_access_principal_type     = "AWS"
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](https://developer.hashicorp.com/terraform/install) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](https://registry.terraform.io/providers/hashicorp/aws/latest) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#https://registry.terraform.io/providers/hashicorp/aws/latest) | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.external_access_s3_read_only_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.external_access_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.task_role_s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.external_access_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_execution_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb.network_load_balancer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.listener_grpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.listener_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.target_group_grpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.target_group_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.security_group_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | Name of the deployment (used for naming resources) | `string` | n/a | yes |
| <a name="input_existing_subnet_ids"></a> [existing\_subnet\_ids](#input\_existing\_subnet\_ids) | List of private subnet IDs (at least 2) for deploying the OpenTelemetry Collector. | `list(string)` | n/a | yes |
| <a name="input_existing_vpc_id"></a> [existing\_vpc\_id](#input\_existing\_vpc\_id) | VPC ID to deploy the OpenTelemetry Collector into. | `string` | n/a | yes |
| <a name="input_telemetry_data_bucket_arn"></a> [telemetry\_data\_bucket\_arn](#input\_telemetry\_data\_bucket\_arn) | ARN of the S3 bucket to store OpenTelemetry data such as traces, metrics, and logs. | `string` | n/a | yes |
| <a name="input_batch_size"></a> [batch\_size](#input\_batch\_size) | Batch size for sending telemetry data | `number` | `1024` | no |
| <a name="input_batch_timeout"></a> [batch\_timeout](#input\_batch\_timeout) | Timeout for batch processor in seconds | `string` | `"10s"` | no |
| <a name="input_container_image"></a> [container\_image](#input\_container\_image) | OpenTelemetry Collector container image | `string` | `"otel/opentelemetry-collector-contrib:latest"` | no |
| <a name="input_existing_security_group_id"></a> [existing\_security\_group\_id](#input\_existing\_security\_group\_id) | Optional additional security group ID to attach to the OpenTelemetry Collector resources. | `string` | `"N/A"` | no |
| <a name="input_external_access_principal"></a> [external\_access\_principal](#input\_external\_access\_principal) | Principal (AWS ARN/account ID or Federated identifier) allowed to assume the external access role. | `string` | `"N/A"` | no |
| <a name="input_external_access_principal_type"></a> [external\_access\_principal\_type](#input\_external\_access\_principal\_type) | Type of principal for external access role | `string` | `"AWS"` | no |
| <a name="input_external_access_role_name"></a> [external\_access\_role\_name](#input\_external\_access\_role\_name) | Custom name of the external access role. If left empty, will use the default name. | `string` | `"N/A"` | no |
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | External ID to access the S3 bucket. Update this value later after the stack is created. | `string` | `"N/A"` | no |
| <a name="input_grpc_port"></a> [grpc\_port](#input\_grpc\_port) | Port for OTLP gRPC receiver | `number` | `4317` | no |
| <a name="input_http_port"></a> [http\_port](#input\_http\_port) | Port for OTLP HTTP receiver | `number` | `4318` | no |
| <a name="input_memory_limit_mib"></a> [memory\_limit\_mib](#input\_memory\_limit\_mib) | Memory limit for the collector in MiB | `number` | `1500` | no |
| <a name="input_memory_spike_limit_mib"></a> [memory\_spike\_limit\_mib](#input\_memory\_spike\_limit\_mib) | Memory spike limit for the collector in MiB | `number` | `512` | no |
| <a name="input_task_cpu"></a> [task\_cpu](#input\_task\_cpu) | CPU units for the task (1024 = 1 vCPU) | `number` | `1024` | no |
| <a name="input_task_desired_count"></a> [task\_desired\_count](#input\_task\_desired\_count) | Desired number of running tasks for the OpenTelemetry Collector service | `number` | `2` | no |
| <a name="input_task_memory"></a> [task\_memory](#input\_task\_memory) | Memory for the task in MB | `number` | `2048` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_opentelemetry_collector_external_access_role_arn"></a> [opentelemetry\_collector\_external\_access\_role\_arn](#output\_opentelemetry\_collector\_external\_access\_role\_arn) | The ARN of the IAM role for external access to the OpenTelemetry S3 bucket |
| <a name="output_opentelemetry_collector_grpc_endpoint"></a> [opentelemetry\_collector\_grpc\_endpoint](#output\_opentelemetry\_collector\_grpc\_endpoint) | The gRPC endpoint for the OpenTelemetry Collector |
| <a name="output_opentelemetry_collector_http_endpoint"></a> [opentelemetry\_collector\_http\_endpoint](#output\_opentelemetry\_collector\_http\_endpoint) | The HTTP endpoint for the OpenTelemetry Collector |
| <a name="output_opentelemetry_collector_security_group_id"></a> [opentelemetry\_collector\_security\_group\_id](#output\_opentelemetry\_collector\_security\_group\_id) | The ID of the security group for the OpenTelemetry Collector |

## Post-Deployment Configuration

After deployment, update the external access configuration:
1. Set `external_id` to a secure random value
2. Set `external_access_principal` to the appropriate AWS account or federated identity
3. Run `terraform apply` again to update the external access role

## License

See [LICENSE](LICENSE) for more information.

## Security

See [SECURITY](SECURITY.md) for more information.
