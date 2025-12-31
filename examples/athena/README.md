# Athena Example

This example demonstrates the usage of the OpenTelemetry Collector Terraform module with AWS Athena integration enabled. This setup automatically processes telemetry data stored in S3 using AWS Glue crawlers, making it queryable via Athena.

## Overview

When enabled, this module creates:

- **AWS Glue Classifier**: A grok classifier (`%{GREEDYDATA:value}`) for parsing telemetry data
- **Amazon SQS Queue**: Subscribes to an SNS topic to receive notifications when new data arrives
- **IAM Role for Glue Crawler**: Grants permissions to access S3, read from SQS, and use AWS Glue services
- **AWS Glue Crawler**: Automatically processes new telemetry data in S3 and creates/updates tables in the Glue Data Catalog
- **AWS Glue Database**: A catalog database for organizing telemetry tables

## Architecture

```
S3 Bucket (telemetry data)
    ↓ (S3 Event Notification)
SNS Topic
    ↓ (Subscription)
SQS Queue
    ↓ (Event Queue ARN)
Glue Crawler (automatically triggered)
    ↓ (Processes data)
Glue Data Catalog (tables)
    ↓ (Queryable via)
Athena
```

## Prerequisites

1. An S3 bucket for storing telemetry data
2. An SNS topic configured to publish notifications when new objects are created in the S3 bucket
3. S3 bucket event notifications configured to publish to the SNS topic

### Setting up S3 Event Notifications

You need to configure your S3 bucket to publish events to the SNS topic. This can be done via:

1. AWS Console: S3 Bucket → Properties → Event notifications
2. AWS CLI or Terraform: Configure `aws_s3_bucket_notification` resource

Example S3 event notification configuration:

```hcl
resource "aws_s3_bucket_notification" "telemetry_notifications" {
  bucket = "your-telemetry-bucket"

  topic {
    topic_arn     = aws_sns_topic.telemetry_notifications.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "mcd/otel-collector/traces/"
  }
}
```

## Usage

1. Set the required variables in `terraform.tfvars`:

```hcl
existing_vpc_id                                 = "vpc-12345678"
existing_subnet_ids                             = ["subnet-12345678", "subnet-87654321"]
telemetry_data_bucket_arn                      = "arn:aws:s3:::my-telemetry-bucket"
telemetry_data_bucket_notification_sns_topic_arn = "arn:aws:sns:us-west-2:123456789012:telemetry-notifications"
```

2. Run Terraform:

```bash
terraform init
terraform plan
terraform apply
```

## Variables

### Required Variables

- `existing_vpc_id`: Your VPC ID where the collector will be deployed
- `existing_subnet_ids`: List of at least 2 private subnet IDs
- `telemetry_data_bucket_arn`: ARN of your S3 bucket for storing telemetry data
- `telemetry_data_bucket_notification_sns_topic_arn`: ARN of the SNS topic that publishes notifications when new data is written to S3

### Optional Variables

- `deployment_name`: (Optional) Name for the deployment (default: "example-otel-collector-athena")
- `task_desired_count`: (Optional) Number of tasks to run (default: 2)
- `task_cpu`: (Optional) CPU units for each task (default: 1024)
- `task_memory`: (Optional) Memory in MB for each task (default: 2048)
- `existing_security_group_id`: (Optional) Additional security group ID (default: "N/A")

## Outputs

### OpenTelemetry Collector Outputs

- `grpc_endpoint`: gRPC endpoint URL for sending telemetry data
- `http_endpoint`: HTTP endpoint URL for sending telemetry data
- `external_access_role_arn`: IAM role ARN for external access to S3 bucket
- `external_access_role_name`: IAM role name for external access
- `security_group_id`: Security group ID for the OpenTelemetry Collector

### Athena/Glue Resources Outputs

- `athena_glue_classifier_name`: Name of the Glue classifier
- `athena_sqs_queue_arn`: ARN of the SQS queue that triggers the crawler
- `athena_sqs_queue_url`: URL of the SQS queue
- `athena_glue_crawler_role_arn`: ARN of the IAM role used by the Glue crawler
- `athena_glue_crawler_role_name`: Name of the IAM role used by the Glue crawler
- `athena_glue_crawler_name`: Name of the Glue crawler
- `athena_glue_database_name`: Name of the Glue catalog database

## Querying Data with Athena

After the Glue crawler has processed your telemetry data, you can query it using Athena:

1. Go to the AWS Athena console
2. Select the database: `{deployment_name}-telemetry-db`
3. Query the tables created by the crawler:

```sql
SELECT * FROM "{deployment_name}-telemetry-db"."traces" 
WHERE year = '2025' AND month = '01' AND day = '15'
LIMIT 100;
```

Note: Table names will depend on your S3 folder structure. The crawler creates tables based on the paths it discovers.

## How It Works

1. **Data Collection**: The OpenTelemetry Collector receives telemetry data and writes it to S3 under `mcd/otel-collector/traces/`

2. **Event Notification**: When new objects are created in S3, an event notification is published to the SNS topic

3. **Queue Processing**: The SNS topic forwards the notification to the SQS queue

4. **Automatic Crawling**: The Glue crawler monitors the SQS queue (via `event_queue_arn`) and automatically starts when messages arrive

5. **Table Creation**: The crawler processes the new data, applies the grok classifier, and creates/updates tables in the Glue Data Catalog

6. **Querying**: The data is now queryable via Athena using standard SQL

## Troubleshooting

### Crawler Not Triggering

- Verify S3 event notifications are configured correctly
- Check that the SNS topic is publishing to the SQS queue
- Verify the SQS queue policy allows SNS to send messages
- Check CloudWatch Logs for the Glue crawler for errors

### Tables Not Appearing

- Ensure the crawler has completed successfully (check Glue console)
- Verify the S3 path is correct and contains data
- Check that the IAM role has proper S3 permissions
- Review crawler logs in CloudWatch

### Permission Issues

- Verify the Glue crawler IAM role has:
  - S3 read permissions on the telemetry bucket
  - SQS receive/delete permissions on the queue
  - AWSGlueServiceRole managed policy attached

