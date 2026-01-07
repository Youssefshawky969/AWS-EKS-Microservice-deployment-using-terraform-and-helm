module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project_name}-eks"
  cluster_version = "1.29"
  
  enable_irsa = true
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 5
      desired_size = 2
    }
  }

  tags = {
    Project = var.project_name
  }
}
