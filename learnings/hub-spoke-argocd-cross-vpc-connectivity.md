# Hub-Spoke ArgoCD GitOps — Connectivity Explained

> Pattern reference: [aws-ia/terraform-aws-eks-blueprints — gitops-multi-cluster-hub-spoke-argocd](https://aws-ia.github.io/terraform-aws-eks-blueprints/patterns/gitops/gitops-multi-cluster-hub-spoke-argocd/)
>
> **This doc reflects the actual implementation in `infra/gitops/`**, which diverges from the reference in several important ways. See the [Implementation Differences](#implementation-differences-from-reference) section.

## TL;DR

No VPC peering is required — hub and spoke run in the **same VPC and same AWS account**. The spoke registers itself with the hub's ArgoCD via **IAM role chaining through AWS STS**, using the **public EKS API endpoints** for Kubernetes API calls. Terraform state is stored in S3 and Kubernetes providers authenticate with token-based auth (no AWS CLI dependency).

---

## Implementation Differences from Reference

| Concern | Reference Pattern | This Implementation |
|---------|-------------------|---------------------|
| **State backend** | Local file (`terraform.tfstate`) | S3 bucket (`owd101vpbtfstate`) |
| **AWS auth** | Default credential chain | Assumed role `VPB_Terraform_Access` + `default_tags` |
| **Networking** | Creates new VPC + subnets (`module.vpc`) | Data-sources pre-existing VPC/subnets (`net.tf`) |
| **K8s provider auth** | `exec { command = "aws eks get-token" }` | `data "aws_eks_cluster_auth"` token (no CLI) |
| **CNI prefix delegation** | `ENABLE_PREFIX_DELEGATION = true` | `ENABLE_PREFIX_DELEGATION = false`, `WARM_IP_TARGET = 5` |
| **Hub remote state read** | Local file path (`../hub/terraform.tfstate`) | S3 (`gitops/terraform.tfstate`) |
| **Topology** | Hub + spokes in separate VPCs | Hub + spokes share the same VPC |

---

## How it works — step by step

### 1. Both clusters expose a public API endpoint

Both `hub/main.tf` and `spokes/main.tf` have:

```hcl
cluster_endpoint_public_access = true
```

Even though hub and spoke are in the **same VPC**, the public endpoint is used so that:
- Terraform (running locally or in CI) can connect to both clusters without needing VPN/bastion
- ArgoCD on the hub can reach the spoke API server on a stable, resolvable HTTPS URL

---

### 2. Hub: ArgoCD gets an IAM role via EKS Pod Identity

In `hub/main.tf`:

```hcl
# ArgoCD pods assume this role automatically via EKS Pod Identity
resource "aws_iam_role" "argocd_hub" {
  name               = "${module.eks.cluster_name}-argo-deployments-hub"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json  # trusted by pods.eks.amazonaws.com
}

# Allows this role to sts:AssumeRole on any role (i.e., all spoke roles)
resource "aws_iam_policy" "aws_assume_policy" {
  policy = # sts:AssumeRole + sts:TagSession on "*"
}

# Binds both ArgoCD service accounts to the hub IAM role
resource "aws_eks_pod_identity_association" "argocd_app_controller" {
  service_account = "argo-deployments-application-controller"
  role_arn        = aws_iam_role.argocd_hub.arn
}
resource "aws_eks_pod_identity_association" "argocd_api_server" {
  service_account = "argo-deployments-server"
  role_arn        = aws_iam_role.argocd_hub.arn
}
```

The hub exports this role ARN via Terraform output so spokes can reference it:

```hcl
output "argocd_iam_role_arn" {
  value = aws_iam_role.argocd_hub.arn
}
```

---

### 3. Hub remote state is read from S3 (not local file)

In `spokes/main.tf`, the hub's state is fetched from S3 — not a local file path as in the reference:

```hcl
data "terraform_remote_state" "cluster_hub" {
  backend = "s3"
  config = {
    bucket = "owd101vpbtfstate"
    key    = "gitops/terraform.tfstate"   # hub's fixed state key
    region = "us-west-2"
  }
}
```

Spoke state is also stored in S3. With Terraform workspaces the key is automatically namespaced:
- `default` workspace → `gitops/spokes/terraform.tfstate`
- `dev` workspace    → `env:/dev/gitops/spokes/terraform.tfstate`
- `staging` workspace → `env:/staging/gitops/spokes/terraform.tfstate`
- `prod` workspace   → `env:/prod/gitops/spokes/terraform.tfstate`

---

### 4. Spoke: creates a trust role that only the hub's ArgoCD role can assume

In `spokes/main.tf`:

```hcl
resource "aws_iam_role" "spoke" {
  name               = "${local.name}-argo-deployments-spoke"   # e.g. spoke-dev-argo-deployments-spoke
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "AWS"
      # Only the hub's ArgoCD IAM role can assume this spoke role
      identifiers = [data.terraform_remote_state.cluster_hub.outputs.argocd_iam_role_arn]
    }
  }
}
```

---

### 5. Spoke: grants the spoke role cluster-admin on the spoke EKS cluster

```hcl
access_entries = {
  argocd_spoke = {
    principal_arn = aws_iam_role.spoke.arn
    policy_associations = {
      argocd = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = { type = "cluster" }
      }
    }
  }
}
```

---

### 6. Kubernetes providers use token auth (no CLI dependency)

The reference uses `exec { command = "aws" }` which requires the AWS CLI to be installed on the machine running Terraform. This implementation uses `data "aws_eks_cluster_auth"` instead, which retrieves the token via the AWS Terraform provider directly:

```hcl
# Hub cluster auth token
data "aws_eks_cluster_auth" "hub_cluster_auth" {
  name = data.terraform_remote_state.cluster_hub.outputs.cluster_name
}

provider "kubernetes" {
  alias                  = "hub"
  host                   = data.terraform_remote_state.cluster_hub.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.cluster_hub.outputs.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.hub_cluster_auth.token  # no CLI needed
}

# Spoke cluster auth token
data "aws_eks_cluster_auth" "spoke_cluster_auth" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.spoke_cluster_auth.token  # no CLI needed
}
```

---

### 7. Spoke Terraform writes the cluster Secret INTO the hub (GitOps Bridge)

The `gitops_bridge_bootstrap_hub` module uses the **hub** Kubernetes provider (`kubernetes.hub`) to write an ArgoCD cluster secret into the hub's `argocd` namespace. This secret tells ArgoCD how to reach and authenticate to the spoke:

```hcl
module "gitops_bridge_bootstrap_hub" {
  providers = {
    kubernetes = kubernetes.hub  # <-- secret is created on the HUB
  }

  install = false  # ArgoCD is already installed on the hub
  cluster = {
    server = module.eks.cluster_endpoint  # spoke's public EKS API URL
    config = <<-EOT
      {
        "tlsClientConfig": {
          "caData": "${module.eks.cluster_certificate_authority_data}"
        },
        "awsAuthConfig": {
          "clusterName": "${module.eks.cluster_name}",
          "roleARN": "${aws_iam_role.spoke.arn}"   # role ArgoCD will assume
        }
      }
    EOT
  }
}
```

---

### 8. Networking — shared VPC, data-sourced subnets

Unlike the reference which creates a new VPC per cluster, both hub and spoke reuse the **same pre-existing VPC**. The VPC and subnets are looked up by tag convention in `net.tf`:

```hcl
data "aws_vpc" "main_vpc" {
  filter {
    name   = "tag:Environment"
    values = [upper(var.environment)]   # e.g. "PROD"
  }
}

# Core (private) subnets — one per AZ
data "aws_subnet" "core" {
  for_each          = toset(local.azs)
  vpc_id            = data.aws_vpc.main_vpc.id
  availability_zone = each.value
  filter {
    name   = "tag:Name"
    values = ["owd-${var.environment}_${substr(each.value, -1, -1)}_core"]
  }
}

# DMZ (public/ingress) subnets — one per AZ
data "aws_subnet" "dmz" {
  for_each          = toset(local.azs)
  vpc_id            = data.aws_vpc.main_vpc.id
  availability_zone = each.value
  filter {
    name   = "tag:Name"
    values = ["owd-${var.environment}_${substr(each.value, -1, -1)}_dmz"]
  }
}
```

The EKS module then consumes both subnet types:

```hcl
module "eks" {
  vpc_id     = data.aws_vpc.main_vpc.id
  subnet_ids = concat(
    [for j in data.aws_subnet.core : j.id],
    [for k in data.aws_subnet.dmz : k.id]
  )
}
```

---

### 9. CNI config — prefix delegation disabled

The reference enables prefix delegation (`ENABLE_PREFIX_DELEGATION = true`) to pack more pods per node. This implementation disables it due to subnet IP constraints:

```hcl
vpc-cni = {
  configuration_values = jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = "false"
      WARM_IP_TARGET           = "5"   # pre-allocate 5 IPs per node
    }
  })
}
```

---

## Full connection flow at runtime

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Shared VPC (prod)                                                       │
│                                                                          │
│  ┌─────────────────────────┐       ┌──────────────────────────────────┐ │
│  │  HUB EKS Cluster        │       │  SPOKE EKS Cluster               │ │
│  │                         │       │                                  │ │
│  │  ArgoCD Pod             │       │  EKS API Server                  │ │
│  │  (argocd_hub IAM role   │       │  (public endpoint)               │ │
│  │   via EKS Pod Identity) │       │        ▲                         │ │
│  │         │               │       │        │                         │ │
│  └─────────┼───────────────┘       └────────┼─────────────────────────┘ │
│            │                                │                            │
└────────────┼────────────────────────────────┼────────────────────────────┘
             │                                │
             │  1. sts:AssumeRole(spoke)       │
             ▼  (AWS STS public endpoint)      │
          AWS STS ── temp credentials ─────────┤
                                               │
             │  2. HTTPS API call              │
             └──────── public internet ────────┘
                       (TLS via caData)
```

| Step | What happens | Transport |
|------|-------------|-----------|
| 1 | ArgoCD Pod assumes `spoke` IAM role via `sts:AssumeRole` | AWS STS — public HTTPS |
| 2 | ArgoCD calls spoke's EKS API with temporary credentials | Spoke EKS public endpoint — HTTPS |
| 3 | Spoke EKS validates role via Access Entries → grants cluster-admin | AWS control plane |
| 4 | ArgoCD deploys/syncs manifests to the spoke cluster | HTTPS |

---

## Key components summary

| Component | Location | Purpose |
|-----------|----------|---------|
| `aws_iam_role.argocd_hub` | Hub | IAM role assumed by ArgoCD pods via EKS Pod Identity |
| `aws_iam_policy.aws_assume_policy` | Hub | Allows `argocd_hub` to `sts:AssumeRole` on `"*"` (all spoke roles) |
| `aws_eks_pod_identity_association` | Hub | Binds `argocd-application-controller` + `argocd-server` to `argocd_hub` role |
| `output "argocd_iam_role_arn"` | Hub (S3 state) | Exports hub ArgoCD role ARN; read by spoke Terraform via `terraform_remote_state` |
| `data "aws_eks_cluster_auth"` | Hub + Spoke | Fetches EKS token via Terraform AWS provider — no AWS CLI required |
| `aws_iam_role.spoke` | Spoke | IAM role trusted only by `argocd_hub`; used by ArgoCD to authenticate to spoke |
| `access_entries` (EKS) | Spoke | Grants `spoke` IAM role `AmazonEKSClusterAdminPolicy` on the spoke cluster |
| `gitops_bridge_bootstrap_hub` | Spoke Terraform → Hub K8s | Creates ArgoCD cluster secret on the hub with spoke endpoint + `roleARN` |
| `net.tf` | Hub + Spoke | Data-sources pre-existing VPC/subnets by `tag:Environment` and naming convention |

---

## Why no VPC peering is needed

In this implementation, hub and spoke are already in the **same VPC** — so VPC-level connectivity is inherently present. However, the architecture does **not** rely on it:

- **EKS API servers are public** — `cluster_endpoint_public_access = true` on both clusters; Terraform and ArgoCD connect over HTTPS regardless of VPC
- **Authentication is IAM-based** — AWS STS is a public service; no VPC routing needed for role assumption
- **TLS is enforced** — `caData` in the cluster secret verifies the spoke's endpoint certificate
- **Authorization uses EKS Access Entries** — the spoke explicitly grants the `spoke` IAM role cluster-admin

## Making this private (optional)

Since hub and spoke are already in the same VPC, transitioning to private-only endpoints is simpler than the cross-VPC reference scenario:

1. Set `cluster_endpoint_public_access = false` on both clusters
2. Ensure the hub's node security group allows egress to the spoke's **private API endpoint CIDR** (typically `10.x.x.x/32` for each endpoint ENI)
3. Update `data "aws_eks_cluster_auth"` — this calls the EKS API internally so it will work on private endpoints as long as the Terraform runner has VPC access
4. For CI/CD pipelines running outside the VPC, add a VPC endpoint for EKS or route traffic through a NAT gateway / VPN

> No VPC Peering or Transit Gateway is required since both clusters are already on the same VPC.
