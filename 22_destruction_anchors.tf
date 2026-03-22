data "aws_vpc" "destruction_anchor" {
  id         = module.vpc.vpc_id
  depends_on = [null_resource.destruction_dependencies]
}

data "aws_eks_cluster" "destruction_anchor" {
  name       = module.eks.cluster_name
  depends_on = [null_resource.destruction_dependencies]
}

