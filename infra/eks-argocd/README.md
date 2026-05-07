# EKS Auto Mode + ArgoCD Capability (IaC Only)

## 1. Architecture Summary

This template provisions:

- VPC with public and private subnets using `terraform-aws-modules/vpc/aws`.
- EKS cluster using `terraform-aws-modules/eks/aws`.
- EKS Auto Mode enabled via module `compute_config`.
- Native EKS ArgoCD capability via `aws_eks_capability` through `terraform-aws-modules/eks/aws//modules/capability`, not manual Helm install.
- Public API endpoint enabled by default for test environments.

## 2. Assumptions And Inputs

- Terraform CLI >= 1.6 and AWS provider >= 6.28.
- You have AWS credentials and permissions for VPC, EKS, IAM, and EKS capabilities.
- ArgoCD capability is available in your target region.
- Git repo placeholders in `argocd/` templates are replaced before use.

Primary inputs are defined in `terraform.tfvars.example`.

## 3. File-By-File Terraform Templates

The Terraform configuration is organized into three logical modules under `infra/eks-argocd/`:

### Root Level
- `main.tf`: Orchestrates the four submodules (shared, sso, eks, argocd-secret).
- `variables.tf`: Root-level input variables; pass-through to submodules.
- `outputs.tf`: Exposes EKS and ArgoCD capability outputs from the `eks` submodule.
- `providers.tf`: AWS and Kubernetes providers.
- `versions.tf`: Terraform and provider version constraints.
- `terraform.tfvars.example`: Editable sample values.

### shared/ Module — VPC and Networking
Provisions the VPC, subnets, and networking infrastructure.
- `main.tf`: VPC module.
- `variables.tf`: VPC, CIDR, AZ, and tagging inputs.
- `locals.tf`: Computed values (name, AZs, tags).
- `outputs.tf`: VPC ID, subnet IDs.

### sso/ Module — IAM Identity Center Configuration
Auto-discovers and resolves IAM Identity Center instance and groups for ArgoCD RBAC.
- `main.tf`: Data sources for SSO instance and group lookup.
- `variables.tf`: SSO group display names, IDC region.
- `locals.tf`: Resolved group IDs and RBAC role mappings.
- `outputs.tf`: IDC ARN, IDC region, resolved group IDs, RBAC mappings.

### eks/ Module — EKS Cluster and ArgoCD Capability
Provisions EKS, Auto Mode, and ArgoCD capability.
- `main.tf`: EKS module, ArgoCD capability module, cluster access policy, IAM policy attachments.
- `variables.tf`: EKS version, Auto Mode config, ArgoCD inputs (passed from root).
- `locals.tf`: ArgoCD capability configuration (constructed from SSO module outputs).
- `outputs.tf`: Cluster details, ArgoCD capability details.

### argocd-secret/ Module — ArgoCD Cluster Secret
Creates the ArgoCD `local-cluster` Kubernetes secret after EKS is available. The module takes EKS outputs from root and keeps the Kubernetes resource separate from the cluster module.

## 4. ArgoCD Pipeline Template Files

See `argocd/`:

- `projects/platform-project.yaml`
- `applications/platform-appset.yaml`
- `apps/dev/*`, `apps/test/*`, `apps/prod/*`

These provide a reusable, environment-oriented GitOps scaffold.

## 5. Deployment Instructions (No Execution)

1. Review and update placeholders:
   - `cluster_name`, CIDRs, tags in `terraform.tfvars.example`
   - `repoURL` and `sourceRepos` in ArgoCD YAML files
2. Validate ArgoCD capability support in your target region and account.
3. Review IAM Identity Center settings if required by your organization:
   - `argocd_idc_region`
   - `argocd_admin_group_name`
   - `argocd_editor_group_name`
   - `argocd_viewer_group_name`
4. Run Terraform planning workflow only:
   - `cd infra/eks-argocd`
   - `cp terraform.tfvars.example terraform.tfvars`
   - `terraform init`
   - `terraform validate`
   - `terraform plan -out tfplan`
5. Gate before apply:
   - Review `tfplan` output with platform/security approvers.
   - Confirm public endpoint usage is test-only.

## 6. Verification Steps

After deployment is performed by an operator, verify:

1. Cluster health:
   - `aws eks describe-cluster --name <cluster_name> --region <region> --query 'cluster.status'`
   - Expect `ACTIVE`.
2. Auto Mode:
   - `aws eks describe-cluster --name <cluster_name> --region <region> --query 'cluster.computeConfig'`
   - Expect `enabled: true` and expected node pools.
3. ArgoCD capability readiness:
   - `aws eks describe-capability --cluster-name <cluster_name> --capability-name argocd --region <region>`
   - Expect capability status/version present and server URL available.
4. App sync behavior:
   - Confirm ApplicationSet generated apps for `dev`, `test`, and `prod`.
   - Confirm each app reaches `Synced` and `Healthy` state in ArgoCD.
5. Smoke tests:
   - Verify sample workload pods are running in `guestbook-dev`.
   - Verify service endpoints resolve inside cluster.

Recommended operator sequence after deployment:

1. Update kubeconfig:
   - `aws eks update-kubeconfig --name <cluster_name> --region <region>`
2. Verify ArgoCD control plane resources:
   - `kubectl get pods -n argocd`
   - `kubectl get svc -n argocd`
3. Verify generated ArgoCD resources:
   - `kubectl get applicationsets -n argocd`
   - `kubectl get applications -n argocd`
4. Verify workload deployment:
   - `kubectl get deploy,po,svc -n guestbook-dev`
5. Verify GitOps reconciliation:
   - Change replicas in `argocd/apps/dev/guestbook/deployment.yaml`
   - Commit and push
   - `kubectl rollout status deployment/guestbook -n guestbook-dev`
6. Verify self-heal:
   - `kubectl scale deployment/guestbook -n guestbook-dev --replicas=1`
   - Confirm ArgoCD reconciles back to the desired state

Failure and rollback checks:

- If capability creation fails, inspect Terraform output and EKS capability API error details.
- If plan includes unintended resource replacement, stop and revise variables.
- Rollback via Terraform-controlled changes only (no manual drift).

## 7. Risks, Trade-Offs, Hardening

- Public control plane endpoint simplifies testing but increases exposure.
- Hardening for non-test:
  - Set `cluster_endpoint_public_access = false`.
  - Restrict CIDRs and enable private endpoint access workflows.
  - Add tighter IAM least-privilege boundaries.
  - Add policy guardrails (OPA/Conftest, tfsec/checkov, CI checks).
- Capability availability and prerequisites (including IAM Identity Center integration) can vary by region and account; validate before planning.
