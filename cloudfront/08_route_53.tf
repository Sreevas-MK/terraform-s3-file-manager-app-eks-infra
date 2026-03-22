resource "aws_route53_record" "app_dns" {
  for_each = toset([var.app_host, var.grafana_url, var.argocd_url])

  zone_id = data.aws_route53_zone.my_domain.zone_id
  name    = each.value
  type    = "A" # Alias records must be type A

  # This forces Terraform to ignore the conflict and overwrite
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
