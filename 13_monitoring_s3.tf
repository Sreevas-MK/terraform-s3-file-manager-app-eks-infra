resource "aws_s3_bucket" "loki_logs" {
  bucket        = "${var.project_name}-loki-logs"
  force_destroy = true

  tags = {
    Name        = var.project_name
    Environment = var.project_environment
  }
}

module "loki_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name = "${var.project_name}-loki-irsa"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["monitoring:monitoring-stack-loki"]
    }
  }

  role_policy_arns = {
    policy = aws_iam_policy.loki_s3_policy.arn
  }
}

resource "aws_iam_policy" "loki_s3_policy" {
  name        = "${var.project_name}-loki-s3-policy"
  description = "Allow Loki to manage logs in S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.loki_logs.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["${aws_s3_bucket.loki_logs.arn}/*"]
      }
    ]
  })
}
