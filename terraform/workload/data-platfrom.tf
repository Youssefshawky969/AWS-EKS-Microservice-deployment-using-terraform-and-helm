data "terraform_remote_state" "platform" {
  backend = "remote"

  config = {
    organization = "youssef_eks"
    workspaces = {
      name = "eks"
    }
  }
}
