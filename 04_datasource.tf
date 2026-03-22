data "aws_caller_identity" "current" {}

# Find a certificate that is issued
data "aws_acm_certificate" "existing_cert" {
  domain      = var.acm_cert_host
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "my_domain" {
  name         = var.domain_name
  private_zone = false
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.ap-south-1.s3"
}

# AMI for OVPN instance
data "aws_ami" "ubuntu_20" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Data required to fetch OVPN instance details
data "aws_instance" "openvpn_instance" {
  filter {
    name   = "tag:Name"
    values = ["OpenVPN-AS"] # This must match the 'name' variable in your module
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [module.ec2-openvpn]
}
