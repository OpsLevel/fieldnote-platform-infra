locals {
  oidc_provider = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
}

# IRSA role for the api service account (namespace: api, sa: api).
data "aws_iam_policy_document" "api_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:api:api"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api" {
  name               = "${var.environment}-api"
  assume_role_policy = data.aws_iam_policy_document.api_assume.json
}

data "aws_iam_policy_document" "api" {
  statement {
    sid       = "UploadsReadWrite"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${module.uploads_bucket.arn}/*"]
  }

  statement {
    sid       = "UploadsList"
    actions   = ["s3:ListBucket"]
    resources = [module.uploads_bucket.arn]
  }

  statement {
    sid       = "UploadsKms"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.s3.arn]
  }
}

resource "aws_iam_role_policy" "api" {
  name   = "api"
  role   = aws_iam_role.api.id
  policy = data.aws_iam_policy_document.api.json
}
