# agent-runner: receives GitHub webhooks, runs agent analysis sessions against
# the repository, and writes the resulting artifacts to S3.

# IRSA role for the agent-runner service account (namespace: agent-runner, sa: agent-runner).
data "aws_iam_policy_document" "agent_runner_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:agent-runner:agent-runner"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "agent_runner" {
  name               = "${var.environment}-agent-runner"
  assume_role_policy = data.aws_iam_policy_document.agent_runner_assume.json
}

data "aws_iam_policy_document" "agent_runner" {
  statement {
    sid       = "ArtifactsAccess"
    actions   = ["s3:*"]
    resources = ["*"]
  }

  statement {
    sid       = "ArtifactsKms"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.s3.arn]
  }
}

resource "aws_iam_role_policy" "agent_runner" {
  name   = "agent-runner"
  role   = aws_iam_role.agent_runner.id
  policy = data.aws_iam_policy_document.agent_runner.json
}

# Security group for the agent-runner NLB so GitHub webhooks can reach the service.
resource "aws_security_group" "agent_runner_lb" {
  name        = "${var.environment}-agent-runner-lb"
  description = "agent-runner webhook load balancer"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "agent_runner_webhooks" {
  security_group_id = aws_security_group.agent_runner_lb.id
  description       = "GitHub webhooks"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "agent_runner_lb_to_nodes" {
  security_group_id            = aws_security_group.agent_runner_lb.id
  description                  = "Forward to agent-runner pods"
  referenced_security_group_id = module.eks.node_security_group_id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_agent_runner_lb" {
  security_group_id            = module.eks.node_security_group_id
  description                  = "agent-runner NLB to pods"
  referenced_security_group_id = aws_security_group.agent_runner_lb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}
