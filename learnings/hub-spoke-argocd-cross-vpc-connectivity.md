# Hub-Spoke ArgoCD GitOps — Small scale POC for Enterprise wide cluster management and container workload deployment using ArgoCD and EKS.

> Pattern reference: [aws-ia/terraform-aws-eks-blueprints — gitops-multi-cluster-hub-spoke-argocd](https://aws-ia.github.io/terraform-aws-eks-blueprints/patterns/gitops/gitops-multi-cluster-hub-spoke-argocd/)
>
> Architecture diagram source: [`diagrams/github-oidc-aws-automation-cicd.drawio`](../diagrams/github-oidc-aws-automation-cicd.drawio)

---

## Section 1 — Deployment POC (current implementation)

### Architectural outcomes, overview and considerations

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
## Implementation details 
### 1. Simplified networking for POC 

Both `hub/main.tf` and `spokes/main.tf` have:

**File references:** `infra/gitops/hub/main.tf`, `infra/gitops/spokes/main.tf`

```hcl
cluster_endpoint_public_access = true
```
This was primarily for testing convince

In this POC the hub and spoke are in the same aws account and vpc. This is due to limitations imposed on us in the VPB 
account provisioned by OW-Digital.

>Producton note: 
> private endpoints for the eks control plane is recommended \
> Hub and spoke clusters in different account, with the hub residing in a privileged account like an automation or shared services account, and the spokes in separate application accounts. \
> Dedicated Networks for each clusters with secured connectivity between them (Likely Transit Gateway)
>(see Section 2 for details below).
### 2. Hub: ArgoCD gets an IAM role via EKS Pod Identity

In `hub/main.tf` (`infra/gitops/hub/main.tf`):

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

The hub exports this role ARN via Terraform output so spokes can reference it (`infra/gitops/hub/main.tf`):

```hcl
output "argocd_iam_role_arn" {
  value = aws_iam_role.argocd_hub.arn
}
```

---

### 3. Hub remote state is read from S3

In `spokes/main.tf` (`infra/gitops/spokes/main.tf`), the hub's state is fetched from S3:

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
refer to `spokes/Makefile` to review how state prefixes are dynamically configured based on the defined `ENV` variable.
### 4. Spoke: creates a trust role that only the hub's ArgoCD role can assume

In `spokes/main.tf` (`infra/gitops/spokes/main.tf`):

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

In `spokes/main.tf` (`infra/gitops/spokes/main.tf`):

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
>Producton note: 
> Create a custom role comprising of the `AmazonEKSClusterAdminPolicy` with a deny policy  \
TODO - craft tested custom policy 
---

### 6. Kubernetes providers use token auth (no CLI dependency)

Configure the terraform kubernetes provider using  `data "aws_eks_cluster_auth"`, which retrieves the token to the taget cluster directly  enabling modules to \
initiate helm deployments where required.

In `spokes/main.tf` (`infra/gitops/spokes/main.tf`):

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

The `gitops_bridge_bootstrap_hub` module uses the **hub** Kubernetes provider (`kubernetes.hub`) to write an ArgoCD cluster secret into the hub's `argocd` namespace. This secret tells ArgoCD how to reach and authenticate to the spoke.

In `spokes/main.tf` (`infra/gitops/spokes/main.tf`):

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

Both hub and spoke reuse the **same pre-existing VPC**. The VPC and subnets are looked up by tag convention in `net.tf` (`infra/gitops/hub/net.tf`, `infra/gitops/spokes/net.tf`):

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

The EKS module then consumes both subnet types (`infra/gitops/hub/main.tf`, `infra/gitops/spokes/main.tf`):

```hcl
module "eks" {
  vpc_id     = data.aws_vpc.main_vpc.id
  subnet_ids = concat(
    [for j in data.aws_subnet.core : j.id],
    [for k in data.aws_subnet.dmz : k.id]
  )
}
```
>Production note:  
> Hub and spoke clusters MUST be deployed in different account, with the hub residing in a privileged account like an automation or shared services account, and the spokes in separate application accounts. \
> Dedicated Networks for each clusters with secured connectivity between them (Likely Transit Gateway)
---

### 9. CNI config — prefix delegation disabled

The reference enables prefix delegation (`ENABLE_PREFIX_DELEGATION = true`) to pack more pods per node. This implementation disables it due to subnet IP constraints.

In `infra/gitops/hub/main.tf` and `infra/gitops/spokes/main.tf`:

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
>Production note: \
>This was required in the POC due to shared networks for EKS clusters , likely revert to defaults in with dedicated networks 



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


