data "aws_lb" "eks_alb" {
  name = "eks-shared-alb"
}

data "aws_route53_zone" "my_domain" {
  name         = var.domain_name
  private_zone = false
}

data "aws_caller_identity" "current" {}

data "aws_acm_certificate" "existing_cert" {
  domain      = var.acm_cert_host
  statuses    = ["ISSUED"]
  most_recent = true
}
