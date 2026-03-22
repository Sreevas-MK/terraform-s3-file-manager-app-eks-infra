# This configures variables in your INFRA repo
resource "github_actions_variable" "aws_account_id" {
  repository    = var.github_terraform_repo
  variable_name = "AWS_ACCOUNT_ID"
  value         = data.aws_caller_identity.current.account_id
}

resource "github_actions_variable" "aws_region" {
  repository    = var.github_terraform_repo
  variable_name = "AWS_REGION"
  value         = var.aws_region
}

resource "github_actions_secret" "ssh_public_key" {
  repository      = var.github_terraform_repo
  secret_name     = "SSH_PUBLIC_KEY"
  plaintext_value = var.ssh_public_key
}

resource "github_actions_secret" "helm_repo_access" {
  repository      = var.github_code_repo
  secret_name     = "HELM_REPO_TOKEN"
  plaintext_value = var.github_token
}

resource "github_actions_secret" "dockerhub_username" {
  repository      = var.github_code_repo
  secret_name     = "DOCKERHUB_USERNAME"
  plaintext_value = var.dockerhub_username
}

resource "github_actions_secret" "dockerhub_password" {
  repository      = var.github_code_repo
  secret_name     = "DOCKERHUB_PASSWORD"
  plaintext_value = var.dockerhub_password
}

