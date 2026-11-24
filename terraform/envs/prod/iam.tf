# Trust policy shared by every role bound through EKS Pod Identity.
data "aws_iam_policy_document" "pod_identity_assume" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

# Pod Identity role for the api service account (namespace: api, sa: api).
resource "aws_iam_role" "api" {
  name               = "${var.environment}-api"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume.json
}

resource "aws_eks_pod_identity_association" "api" {
  cluster_name    = module.eks.cluster_name
  namespace       = "api"
  service_account = "api"
  role_arn        = aws_iam_role.api.arn
}

data "aws_iam_policy_document" "api" {
  statement {
    sid       = "UploadsReadWrite"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.uploads.arn}/*"]
  }

  statement {
    sid       = "UploadsList"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.uploads.arn]
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

# Pod Identity role for the export worker (namespace: api, sa: api-worker).
resource "aws_iam_role" "worker" {
  name               = "${var.environment}-api-worker"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume.json
}

resource "aws_eks_pod_identity_association" "worker" {
  cluster_name    = module.eks.cluster_name
  namespace       = "api"
  service_account = "api-worker"
  role_arn        = aws_iam_role.worker.arn
}

data "aws_iam_policy_document" "worker" {
  statement {
    sid       = "Uploads"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.uploads.arn, "${aws_s3_bucket.uploads.arn}/*"]
  }

  statement {
    sid       = "UploadsKms"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.s3.arn]
  }
}

resource "aws_iam_role_policy" "worker" {
  name   = "api-worker"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.worker.json
}
