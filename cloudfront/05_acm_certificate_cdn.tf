resource "aws_acm_certificate" "cloudfront_cert" {
  provider                  = aws.us_east_1
  domain_name               = var.acm_cert_host
  subject_alternative_names = local.all_domains
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = { for dvo in aws_acm_certificate.cloudfront_cert.domain_validation_options : dvo.domain_name => dvo }

  zone_id = data.aws_route53_zone.my_domain.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cloudfront_cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
