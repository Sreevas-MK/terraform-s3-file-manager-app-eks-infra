variable "aws_region" {
  default = "ap-south-1"
}

variable "project_name" {
  default = "s3-nodejs-app"
}

variable "project_environment" {
  default = "development"
}

variable "domain_name" {
  default = "sreevasmk.online"
}

variable "app_host" {
  default = "s3app.sreevasmk.online"
}

variable "grafana_url" {
  default = "grafana.sreevasmk.online"
}

variable "argocd_url" {
  default = "argocd.sreevasmk.online"
}

variable "acm_cert_host" {
  default = "*.sreevasmk.online"
}
