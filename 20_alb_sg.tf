resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-shared-alb-sg"
  description = "Security group for the shared EKS ALB"
  vpc_id      = module.vpc.vpc_id

  # REPLACE both open ingress rules with CloudFront prefix list only
  #   ingress {
  #     from_port       = 80
  #     to_port         = 80
  #     protocol        = "tcp"
  #     prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  #     description     = "HTTP from CloudFront only"
  #   }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

    #    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
    #    description     = "HTTPS from CloudFront only"
  }

  # Rule 2: Allow the VPC itself to hit the ALB (CRITICAL for Health Checks)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "Allow internal VPC traffic for health checks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-shared-alb-sg"
  }
}
