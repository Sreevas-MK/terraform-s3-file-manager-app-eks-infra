data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "github_actions_policy" {
  name        = "GitHubActionsWorkflowPolicy"
  description = "Policy for GitHub Actions to manage EKS infrastructure"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = ["s3:ListBucket", "s3:GetObject", "s3:PutObject"]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket_name}",
          "arn:aws:s3:::${var.terraform_state_bucket_name}/*"
        ]
      },
      {
        Sid    = "TerraformLockAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        # Dynamically uses your account ID
        Resource = "arn:aws:dynamodb:ap-south-1:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table}"
      },
      {
        Sid    = "FullAccessToServices"
        Effect = "Allow"
        Action = [
          "eks:*",
          "ec2:*",
          "autoscaling:*",
          "elasticloadbalancing:*",
          "rds:*",
          "secretsmanager:*",
          "s3:*",
          "acm:*",
          "route53:*",
          "logs:*",
          "iam:*",
          "ssm:*",
          "kms:*",
          "elasticache:*",
          "cloudformation:*",
          "cloudfront:*",
          "wafv2:*"
        ]
        Resource = "*"
      },
      {
        Sid      = "STSAccess"
        Effect   = "Allow"
        Action   = ["sts:GetCallerIdentity"]
        Resource = "*"
      }
    ]
  })
}
