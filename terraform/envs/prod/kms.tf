resource "aws_kms_key" "s3" {
  description         = "SSE-KMS key for ${var.environment} S3 buckets"
  enable_key_rotation = true
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.environment}-s3"
  target_key_id = aws_kms_key.s3.key_id
}
