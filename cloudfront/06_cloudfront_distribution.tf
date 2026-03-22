locals {

  all_domains = [
    var.app_host,
    var.grafana_url,
    var.argocd_url
  ]
}


resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = ""
  wait_for_deployment = false

  aliases = local.all_domains

  web_acl_id = aws_wafv2_web_acl.cloudfront_waf.arn

  origin {
    domain_name = data.aws_lb.eks_alb.dns_name
    origin_id   = "shared-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "shared-alb"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["Host"]

      cookies {
        forward = "all"
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  logging_config {
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_regional_domain_name
    prefix          = "cloudfront-logs/"
    include_cookies = false
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  depends_on = [
    aws_acm_certificate_validation.cloudfront_cert_validation
  ]
}


# Creates a WAFv2 Web ACL resource.

resource "aws_wafv2_web_acl" "cloudfront_waf" {
  provider = aws.us_east_1 # Must be us-east-1 for CloudFront
  name     = "${var.project_name}-cloudfront-waf"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # RULE 1: Rate Limiting
  rule {
    name     = "RateLimit"
    priority = 1
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 1000 # Max 1000 requests per 5 mins per IP
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAFRateLimit"
      sampled_requests_enabled   = true
    }
  }

  # RULE 2: AWS Managed Common Rules (SQLi, XSS, etc.)
  rule {
    name     = "AWSManagedRulesCommon"
    priority = 2
    override_action {
      count {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedCommon"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CloudFrontWAF"
    sampled_requests_enabled   = true
  }
}
