variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "s3-node-app"
}

variable "project_environment" {
  description = "Project Environment"
  type        = string
  default     = "development"
}

variable "terraform_state_bucket_name" {
  description = "s3 bucket name"
  type        = string
  default     = "s3-nodeapp-project-terraform-state-0001"
}

variable "dynamodb_table" {
  description = "Dynamodb table name"
  type        = string
  default     = "s3-nodeapp-project-terraform-locks-0001"
}

variable "github_username" {
  default = "Sreevas-MK"
}

variable "github_terraform_repo" {
  default = "terraform-s3-file-manager-app-eks-infra"
}

variable "github_code_repo" {
  description = "Github repo - application code"
  type        = string
  default     = "s3node-app-with-versioning"
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "PAT with repo scope to manage secrets/vars"
  type        = string
  sensitive   = true
}

variable "dockerhub_username" {
  type      = string
  sensitive = true
}

variable "dockerhub_password" {
  type      = string
  sensitive = true
}


