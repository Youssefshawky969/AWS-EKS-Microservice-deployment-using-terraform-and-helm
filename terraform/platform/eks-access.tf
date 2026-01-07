resource "aws_eks_access_entry" "eks_admin_role" {
  cluster_name  = module.eks.cluster_name
  principal_arn = data.aws_iam_role.eks_admin.arn
  type          = "STANDARD"

  
}

resource "aws_eks_access_policy_association" "eks_admin_policy" {
  cluster_name  = module.eks.cluster_name
  principal_arn = data.aws_iam_role.eks_admin.arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  
}

