output "cluster_name" {
  value = module.eks.cluster_name
}

output "api_role_arn" {
  value = aws_iam_role.api.arn
}

output "uploads_bucket" {
  value = module.uploads_bucket.bucket
}

output "agent_runner_role_arn" {
  value = aws_iam_role.agent_runner.arn
}

output "agent_runner_lb_security_group_id" {
  value = aws_security_group.agent_runner_lb.id
}

output "artifacts_bucket" {
  value = module.artifacts_bucket.bucket
}
