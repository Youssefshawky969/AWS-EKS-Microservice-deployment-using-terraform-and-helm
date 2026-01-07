resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  values = [
    file("${path.module}/alb-values.yaml")
  ]

  depends_on = [
    kubernetes_service_account_v1.alb_controller,
    aws_iam_role_policy_attachment.alb_attach
  ]
}
