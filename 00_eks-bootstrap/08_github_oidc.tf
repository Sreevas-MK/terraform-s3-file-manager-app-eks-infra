resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # This pulls the actual thumbprint from the live certificate
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}
