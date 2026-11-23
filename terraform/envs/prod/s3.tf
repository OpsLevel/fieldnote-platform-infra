# Customer file uploads served by the api service.
module "uploads_bucket" {
  source = "../../modules/s3-bucket"

  name        = "fieldnote-${var.environment}-uploads"
  kms_key_arn = aws_kms_key.s3.arn
}

moved {
  from = aws_s3_bucket.uploads
  to   = module.uploads_bucket.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_versioning.uploads
  to   = module.uploads_bucket.aws_s3_bucket_versioning.this
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.uploads
  to   = module.uploads_bucket.aws_s3_bucket_server_side_encryption_configuration.this
}

moved {
  from = aws_s3_bucket_public_access_block.uploads
  to   = module.uploads_bucket.aws_s3_bucket_public_access_block.this
}

# Analysis artifacts written by agent-runner sessions.
module "artifacts_bucket" {
  source = "../../modules/s3-bucket"

  name        = "fieldnote-${var.environment}-agent-artifacts"
  kms_key_arn = aws_kms_key.s3.arn
}
