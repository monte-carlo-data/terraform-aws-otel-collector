## Storage-Only Example

This example deploys only the storage-related resources:
- External access role for read-only access to the telemetry bucket
- S3 bucket policy that grants the collector role write permissions

### Usage

```hcl
module "otel_collector" {
  source = "../../"

  deployment_name             = "example-otel-storage"
  deploy_otel_collector       = false
  telemetry_data_bucket_arn   = "arn:aws:s3:::my-telemetry-bucket"
  mcd_otel_collector_task_role_arn = "arn:aws:iam::123456789012:role/my-collector-role"
  vpc_endpoint_id             = "vpce-1234567890abcdef"
}
```
