resource "aws_iam_role" "ovpn_role" {
  name = "${var.project_name}-ovpn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-ovpn-profile"
  role = aws_iam_role.ovpn_role.name
}


# 1. Register the OVPN Role with the EKS Cluster
resource "aws_eks_access_entry" "ovpn_server_access" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.ovpn_role.arn
  type          = "STANDARD"
}

# 2. Grant the ClusterAdmin policy to the OVPN Role
resource "aws_eks_access_policy_association" "ovpn_server_admin" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.ovpn_role.arn

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_entry" "sreevas_direct_access" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.wsl_user}"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "sreevas_direct_admin" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.wsl_user}"

  access_scope {
    type = "cluster"
  }
}
