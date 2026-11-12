# VPC flow logs -> S3.
# S3 delivery is used (not CloudWatch) because it needs no IAM role, which the
# AWS Academy lab does not allow us to create. Flow logs give network-level
# visibility (who talked to whom) to complement Wazuh's host-level logs.

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "flow_logs" {
  #checkov:skip=CKV_AWS_144:Cross-region replication is unnecessary for short-lived lab flow logs
  #checkov:skip=CKV_AWS_145:SSE-S3 (AES256) is sufficient for this lab; a KMS key adds cost and overhead
  #checkov:skip=CKV_AWS_18:Access logging on a logs bucket would be circular; not needed for the lab
  #checkov:skip=CKV2_AWS_62:Event notifications are not needed for this lab logs bucket
  bucket_prefix = "${var.project_name}-flow-logs-"
  force_destroy = true
  tags          = { Name = "${var.project_name}-flow-logs" }
}

resource "aws_s3_bucket_public_access_block" "flow_logs" {
  bucket                  = aws_s3_bucket.flow_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  rule {
    id     = "expire-old-logs"
    status = "Enabled"
    filter {}
    expiration {
      days = 30
    }
  }
  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"
    filter {}
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSLogDeliveryWrite"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.flow_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
      },
      {
        Sid       = "AWSLogDeliveryAclCheck"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = ["s3:GetBucketAcl", "s3:ListBucket"]
        Resource  = aws_s3_bucket.flow_logs.arn
      }
    ]
  })
}

resource "aws_flow_log" "vpc" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.flow_logs.arn
  tags                 = { Name = "${var.project_name}-vpc-flow-log" }
}
