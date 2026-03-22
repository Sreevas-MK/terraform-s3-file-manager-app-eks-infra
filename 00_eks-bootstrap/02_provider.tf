terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      # This fixes the warning you saw in 'terraform init'
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the GitHub Provider
provider "github" {
  token = var.github_token
  owner = var.github_username
}
