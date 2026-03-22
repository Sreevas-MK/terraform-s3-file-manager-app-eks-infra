# S3 bucket for Node application
resource "aws_s3_bucket" "s3_node_app" {
  bucket        = var.app_bucket_name
  force_destroy = true

  tags = {
    Environment = var.project_environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "s3_node_app_versioning" {
  bucket = aws_s3_bucket.s3_node_app.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_node_app_encryption" {
  bucket = aws_s3_bucket.s3_node_app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3_node_app_block" {
  bucket = aws_s3_bucket.s3_node_app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_iam_policy" "s3_access_policy" {
  name = "${var.project_name}-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:ListBucketVersions",
          "s3:GetBucketVersioning"
        ]
        Resource = aws_s3_bucket.s3_node_app.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.s3_node_app.arn}/*"
      }
    ]
  })
}

# Create IAM Role for S3 bucket access

module "s3_app_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name = "${var.project_name}-s3_app_irsa"

  depends_on = [module.eks]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.app_namespace}:${var.app_name}-sa"]
    }
  }

  role_policy_arns = {
    policy = aws_iam_policy.s3_access_policy.arn
  }
}

resource "kubernetes_service_account_v1" "app_sa" {
  metadata {
    name      = "${var.app_name}-sa"
    namespace = var.app_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = module.s3_app_irsa.iam_role_arn
    }
  }
  depends_on = [kubernetes_namespace_v1.app_ns]
}
