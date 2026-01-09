## Overview
This project demonstrates how to build a cluster using Terraform as infrastructure as code. Moreover, establish cluster connectivity using kubeconfig files and learn how to manage IAM principals through the modern EKS access entries system. Compares specialized methods for granting cloud permissions to applications, such as EKS Pod Identities and IAM roles for service accounts (IRSA). At the cluster level, the implementation of Role-Based Access Control (RBAC) to define granular permissions for users, groups, and service accounts. Utilize HCP cloud for storing state, and Github actions for CI/CD pipeline deployment.

## Workflow Diagram
<img width="2240" height="1732" alt="EKS" src="https://github.com/user-attachments/assets/3459ccd3-94cb-4305-885b-a86225b0fefa" />

## Objective of the Task
- Build simple microservice application (Auth, orders, Payment)
- Dockerize the application
- Test the application by Docker-Compose
- Building terraform infrastructure (/Platfrom, /workload)
- Stroing state of both deployments in HCP Cloud
- Automate deployment using Github Actions


## What Was Implemented so far

### pipeline Logic

We will split the pipeline logic to eliminate the hard way of managing files as follows:

```text
./.github/workflows
|__ main.yml
|__ build-push-ecr.yml
|__ helm-deploy.yml
|__ terraform-platform.yml
|__ terraform-workload.yml
```

In main.yml

```yaml

name: Cloud Native Platform Full CI/CD

on:
  push:
    branches: [ "main" ]
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  terraform-platform:
    uses: ./.github/workflows/terraform-platform.yml
    secrets: inherit

  terraform-workload:
    needs: terraform-platform
    uses: ./.github/workflows/terraform-workload.yml
    secrets: inherit

  build-and-push:
    needs: terraform-workload
    uses: ./.github/workflows/build-push-ecr.yml
    secrets: inherit

  helm-deploy:
    needs: build-and-push
    uses: ./.github/workflows/helm-deploy.yml
    secrets: inherit
```

In [terraform-platform.yml](https://github.com/Youssefshawky969/AWS-EKS-Microservice-deployment-using-terraform-and-helm/blob/main/.github/workflows/terraform-platform.yml)

```yaml

name: Terraform Platform


on:
  workflow_call:

env:
  TF_CLOUD_ORG: youssef_eks
  TF_WORKSPACE: eks
  
jobs:
  platform:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Configure AWS credentials (assume role)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          role-to-assume:        arn:aws:iam::${{secrets.AWS_ACCOUNT_ID}}:role/eks-admin-role
          aws-region:            ${{ secrets.AWS_REGION }}    


          
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Authenticate to Terraform Cloud
        run: |
          echo 'credentials "app.terraform.io" {
            token = "${{ secrets.TF_API_TOKEN }}"
          }' > ~/.terraformrc
        

      - name: Terraform Init
        working-directory: terraform/platform
        run: terraform init

      - name: Terraform Apply
        working-directory: terraform/platform
        run: terraform apply -auto-approve
```

In [terraform-workload.yml](https://github.com/Youssefshawky969/AWS-EKS-Microservice-deployment-using-terraform-and-helm/blob/main/.github/workflows/terraform-workload.yml)

```yaml

name: Terraform Workload

on:
  workflow_call:

env:
  TF_CLOUD_ORG: youssef_eks
  TF_WORKSPACE: eks_2

jobs:
  workload:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Configure AWS credentials (assume role)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          role-to-assume:        arn:aws:iam::${{secrets.AWS_ACCOUNT_ID}}:role/eks-admin-role
          aws-region:            ${{ secrets.AWS_REGION }}  

     
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        
      
      - name: Authenticate to Terraform Cloud
        run: |
          echo 'credentials "app.terraform.io" {
            token = "${{ secrets.TF_API_TOKEN }}"
          }' > ~/.terraformrc


      - name: Verify AWS identity
        run: aws sts get-caller-identity

      - name: Update kubeconfig
        run: aws eks update-kubeconfig --region ${{secrets.AWS_REGION}} --name ${{secrets.EKS_CLUSTER_NAME}}
      
      - name: Terraform Init
        working-directory: terraform/workload
        run: terraform init

      - name: Terraform Apply
        working-directory: terraform/workload
        run: terraform apply -auto-approve
```

In [build-push-ecr.yml](https://github.com/Youssefshawky969/AWS-EKS-Microservice-deployment-using-terraform-and-helm/blob/main/.github/workflows/build-push-ecr.yml)

```yaml

name: Build and Push Images

on:
  workflow_call:

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
            aws-access-key-id:     ${{ secrets.AWS_ACCESS_KEY_ID }}
            aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
            aws-region:            ${{ secrets.AWS_REGION }}

      - uses: aws-actions/amazon-ecr-login@v2

      - name: Build & Push Auth
        run: |
          docker build -t ${{secrets.AWS_ACCOUNT_ID}}.dkr.ecr.${{secrets.AWS_REGION}}.amazonaws.com/auth-service:${{ github.sha }} app/auth
          docker push ${{secrets.AWS_ACCOUNT_ID}}.dkr.ecr.${{secrets.AWS_REGION}}.amazonaws.com/auth-service:${{ github.sha }}

      - name: Build & Push Orders
        run: |
          docker build -t ${{secrets.AWS_ACCOUNT_ID}}.dkr.ecr.${{secrets.AWS_REGION}}.amazonaws.com/orders-service:${{ github.sha }} app/orders
          docker push ${{secrets.AWS_ACCOUNT_ID}}.dkr.ecr.${{secrets.AWS_REGION}}.amazonaws.com/orders-service:${{ github.sha }}

      - name: Build & Push Payment
        run: |
          docker build -t ${{secrets.AWS_ACCOUNT_ID}}.dkr.ecr.${{secrets.AWS_REGION}}.amazonaws.com/payment-service:${{ github.sha }} app/payment
          docker push ${{secrets.AWS_ACCOUNT_ID}}.dkr.ecr.${{secrets.AWS_REGION}}.amazonaws.com/payment-service:${{ github.sha }}
```

In [helm-deploy.yml](https://github.com/Youssefshawky969/AWS-EKS-Microservice-deployment-using-terraform-and-helm/blob/main/.github/workflows/helm-deploy.yml)

```yaml

name: Helm Deploy

on:
  workflow_call:

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
      
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
            aws-access-key-id:     ${{ secrets.AWS_ACCESS_KEY_ID }}
            aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
            role-to-assume:        arn:aws:iam::${{secrets.AWS_ACCOUNT_ID}}:role/eks-admin-role
            aws-region:            ${{ secrets.AWS_REGION }}


      - name: Verify AWS identity
        run: aws sts get-caller-identity

      - name: Update kubeconfig
        run: aws eks update-kubeconfig --region ${{ secrets.AWS_REGION }} --name ${{secrets.EKS_CLUSTER_NAME}}

      - name: Helm deploy auth
        run: |
          helm upgrade --install auth helm/auth --namespace dev --create-namespace --set image.tag=${{ github.sha }}


      - name: Helm deploy orders
        run: |
          helm upgrade --install auth helm/orders --namespace dev --create-namespace --set image.tag=${{ github.sha }}
      
      - name: Helm deploy payment
        run: |
          helm upgrade --install payment helm/payment --namespace dev --set image.tag=${{ github.sha }}


      - name: Deploy ingress (dev)
        run: |
          kubectl apply -f k8s/ingress-dev.yaml
```

### Terraform Logic

I split out the Terraform logic into two layers: AWS infrastructure (platform layer), from Kubernetes workloads (workload layer), because Terraform initializes providers before resources exist, and the Kubernetes and Helm providers require a live Kubernetes API, which only exists after EKS is provisioned. I separate it as follows:

```text
./terraform
|__ platfrom/ 
|   |__ provider.tf 
|   |__ variables.tf
|   |__ backend.tf
|   |__ vpc.tf
|   |__ eks.tf
|   |__ iam-eks-admin.tf
|   |__ eks-access.tf
|   |__ outputs.tf
|
|__ workload/
    |__ provider.tf 
    |__ variables.tf
    |__ backend.tf
    |__ data-platfrom.tf
    |__ ecr.tf
    |__ helm-alb.tf
    |__ iam-eks-admin.tf
    |__ iam-irsa-alb.tf
    |__ k8s-namespaces.tf
    |__ outputs.tf
    |__ iam_policy_alb.json
    |__ alb-values.yaml
```

In /platform/provider.tf

```go
provider "aws" {
  region = var.aws_region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

  }
}
```

In /platform/variables.tf

```go
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "cloud-native-platform"
}
```

In /platform/vpc.tf

```go
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Project = var.project_name
  }
}
```

In /platform/eks.tf

```go
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
```

In /platform/eks-access.tf

```go
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
```

In /platform/output.tf

```go
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  value = module.eks.cluster_certificate_authority_data
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
```

In workload/provider

```go

provider "aws" {
  region = var.aws_region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}



data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.platform.outputs.cluster_name
}


provider "kubernetes" {
  host = data.terraform_remote_state.platform.outputs.cluster_endpoint

  cluster_ca_certificate = base64decode(
    data.terraform_remote_state.platform.outputs.cluster_ca_certificate
  )

  token = data.aws_eks_cluster_auth.this.token
}


provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  
  
  }
}
```

In workload/data-platfrom**.tf**

```go
data "terraform_remote_state" "platform" {
  backend = "remote"

  config = {
    organization = "youssef_eks"
    workspaces = {
      name = "eks"
    }
  }
}
```

In workload/iam-irsa-alb.tf

```go

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
```

In workload/k8s-namespaces.tf

```go
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
```

In workload/helm-alb.tf

```go
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
```
## Outputs
<img width="917" height="112" alt="Screenshot 2026-01-05 183520" src="https://github.com/user-attachments/assets/470a5502-4b29-4083-94ed-ca713acb35f9" />

>
>

<img width="936" height="236" alt="Screenshot 2026-01-05 183550" src="https://github.com/user-attachments/assets/1a2bb877-dca2-474b-8d9f-6676622ea85c" />

>
>

<img width="932" height="472" alt="Screenshot 2026-01-05 183614" src="https://github.com/user-attachments/assets/448c2dde-90b0-4baa-a483-47a7ce6ad3c5" />

