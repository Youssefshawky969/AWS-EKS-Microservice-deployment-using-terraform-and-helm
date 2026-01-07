data "aws_iam_policy" "alb_controller" {
  name = "AWSLoadBalancerControllerPolicy"
}


resource "aws_iam_role" "alb_controller" {
  name = "alb-controller-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.terraform_remote_state.platform.outputs.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.terraform_remote_state.platform.outputs.oidc_issuer_url, "https://", "" )}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = data.aws_iam_policy.alb_controller.arn

}

resource "kubernetes_service_account_v1" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
  }
}
