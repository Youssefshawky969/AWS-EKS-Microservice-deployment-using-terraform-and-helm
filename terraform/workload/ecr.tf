resource "aws_ecr_repository" "auth" {
  name = "auth-service"
}

resource "aws_ecr_repository" "orders" {
  name = "orders-service"
}

resource "aws_ecr_repository" "payment" {
  name = "payment-service"
}
