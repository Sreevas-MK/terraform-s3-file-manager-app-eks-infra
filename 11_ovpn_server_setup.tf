module "ec2-openvpn" {
  source = "rizkiprass/ec2-openvpn-as/aws"

  name                          = "OpenVPN-AS"
  instance_type                 = "t2.micro"
  ami_id                        = data.aws_ami.ubuntu_20.id
  key_name                      = aws_key_pair.ssh_auth_key.key_name
  vpc_id                        = module.vpc.vpc_id
  ec2_subnet_id                 = module.vpc.public_subnets[0]
  user_openvpn                  = "devuser"
  routing_ip                    = module.vpc.vpc_cidr_block
  create_vpc_security_group_ids = false
  vpc_security_group_ids        = [aws_security_group.openvpn_sg.id]
  iam_instance_profile          = aws_iam_instance_profile.ec2_instance_profile.name

  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 20
    },
  ]

  tags = {
    Project = var.project_name
  }
}

output "openvpn_public_ip" {
  description = "Public IP of OpenVPN instance"
  value       = data.aws_instance.openvpn_instance.public_ip
}
