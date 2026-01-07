resource "kubernetes_namespace_v1" "dev" {
  metadata {
    name = "dev"
  }
}

resource "kubernetes_namespace_v1" "staging" {
  metadata {
    name = "staging"
  }
}

resource "kubernetes_namespace_v1" "prod" {
  metadata {
    name = "prod"
  }
}
