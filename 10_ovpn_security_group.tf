resource "aws_security_group" "openvpn_sg" {
  name        = "${var.project_name}-openvpn-sg"
  description = "Allow VPN traffic"
  vpc_id      = module.vpc.vpc_id

  # Allow OpenVPN web interface
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # Allow OpenVPN UDP port (default 1194) for VPN tunnel
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
