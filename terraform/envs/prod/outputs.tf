output "cluster_name" {
  value = module.eks.cluster_name
}

output "api_role_arn" {
  value = aws_iam_role.api.arn
}

output "uploads_bucket" {
  value = aws_s3_bucket.uploads.bucket
}

# Infrastructure values for the api chart. `make deploy-api` passes this to Helm.
output "api_helm_values" {
  value = yamlencode({
    env = {
      DATABASE_HOST  = aws_db_instance.main.address
      UPLOADS_BUCKET = aws_s3_bucket.uploads.bucket
      JOBS_REDIS_URL = "rediss://${aws_elasticache_replication_group.jobs.primary_endpoint_address}:6379"
    }
  })
}

output "worker_role_arn" {
  value = aws_iam_role.worker.arn
}
