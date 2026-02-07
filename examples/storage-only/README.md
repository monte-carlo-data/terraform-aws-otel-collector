## Storage-Only Example

This example deploys only the storage-related resources:
- External access role for read-only access to the telemetry bucket
- S3 bucket policy that grants the collector role write permissions
- Telemetry S3 bucket (created automatically when no bucket ARN is provided)

### Usage

```hcl
module "otel_collector" {
  source = "../../"

  deployment_name             = "example-data-store"
  deploy_otel_collector       = false
  mcd_otel_collector_task_role_arn = "arn:aws:iam::123456789012:role/my-collector-role"
  vpc_endpoint_id             = "vpce-1234567890abcdef"
}
```
