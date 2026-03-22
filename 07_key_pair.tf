resource "aws_key_pair" "ssh_auth_key" {
  key_name   = "${var.project_name}-ssh-key"
  public_key = file("./files/s3app-eks-key.pub")

  tags = {
    "Name"        = "${var.project_name}-ssh-key"
    "Project"     = var.project_name
    "Environment" = var.project_environment
  }
}

