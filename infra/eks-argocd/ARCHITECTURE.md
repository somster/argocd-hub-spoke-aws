# Terraform Module Architecture

This document describes the refactored Terraform module structure for the EKS ArgoCD capability deployment.

## Design Philosophy

The configuration is organized into three logical, independently-scalable modules:

1. **shared** — Foundational networking (VPC, subnets)
2. **sso** — AWS IAM Identity Center discovery and RBAC mapping
3. **eks** — EKS cluster, Auto Mode, and ArgoCD capability

This separation enables:
- Independent testing and reuse of each module
- Clear dependency flow: `shared` and `sso` → `eks`
- Easier maintenance and debugging by limiting scope per module
- Straightforward addition of new cloud resources

## Module Flow

```
root/main.tf
   ├─→ ./shared/main.tf    (VPC)
   ├─→ ./sso/main.tf       (SSO lookups)
   ├─→ ./eks/main.tf       (EKS + ArgoCD capability)
   └─→ ./argocd-secret/    (Kubernetes cluster secret)
        └─ depends_on: module.eks
```

## Variable Flow

**shared** module accepts top-level input variables:
- `cluster_name`, `environment`, `vpc_cidr`, `az_count`, `public_subnet_cidrs`, `private_subnet_cidrs`, `tags`

**sso** module accepts:
- `enable_argocd_capability`, `argocd_admin_group_name`, `argocd_editor_group_name`, `argocd_viewer_group_name`, `argocd_idc_region`, `aws_region`

**eks** module accepts:
- All EKS and ArgoCD inputs from root (`cluster_name`, `kubernetes_version`, etc.)
- Plus outputs from **shared** (`vpc_id`, `private_subnets`)
- Plus outputs from **sso** (`idc_instance_arn`, `idc_region`, `rbac_role_mappings`)

**argocd-secret** module accepts:
- `enable_argocd_capability`, `argocd_namespace`, `aws_region`, `account_id`, `cluster_name`

## Output Flow

- **shared** outputs: VPC ID, subnet IDs
- **sso** outputs: IDC instance ARN, IDC region, resolved group IDs, RBAC mappings
- **eks** outputs: Cluster name, endpoint, OIDC ARN, ArgoCD capability details
- **root** aggregates all and re-exports for end users

## Adding New Resources

### Adding to an Existing Module

For example, adding an additional IAM policy to the ArgoCD capability role:

1. Edit `eks/main.tf` to add `aws_iam_role_policy` resource
2. If it needs a new input, add to `eks/variables.tf`
3. If it references computed values, add to `eks/locals.tf`
4. If it should be exposed, add to `eks/outputs.tf`
5. If the input is user-facing, also update root `variables.tf` to pass it through

### Adding a New Module

For example, adding CloudWatch monitoring:

1. Create `monitoring/` directory with `main.tf`, `variables.tf`, `locals.tf`, `outputs.tf`
2. Add data sources and resources in `monitoring/main.tf`
3. Add dependencies (e.g., cluster name) as variables in `monitoring/variables.tf`
4. In root `main.tf`, add:
   ```terraform
   module "monitoring" {
     source = "./monitoring"
     cluster_name = var.cluster_name
     # ... other inputs
   }
   ```
5. Update root `outputs.tf` to aggregate monitoring outputs

## File Structure

```
infra/eks-argocd/
├── main.tf                     # Root orchestration
├── variables.tf                # Root pass-through variables
├── outputs.tf                  # Root aggregated outputs
├── providers.tf                # AWS and Kubernetes providers
├── versions.tf                 # Version constraints
├── terraform.tfvars.example    # Sample configuration
├── README.md                   # Deployment guide
├── ARCHITECTURE.md             # This file
│
├── shared/
│   ├── main.tf                 # VPC module
│   ├── variables.tf            # VPC inputs
│   ├── locals.tf               # Computed values
│   └── outputs.tf              # VPC outputs
│
├── sso/
│   ├── main.tf                 # SSO data sources
│   ├── variables.tf            # SSO inputs
│   ├── locals.tf               # Resolved values
│   └── outputs.tf              # SSO outputs
│
└── eks/
    ├── main.tf                 # EKS resources
    ├── variables.tf            # EKS inputs
    ├── locals.tf               # ArgoCD config
    └── outputs.tf              # EKS outputs
```

## Maintenance Notes

- **Dependency order matters**: Root `main.tf` must declare `depends_on = [module.shared, module.sso]` for the `eks` module to ensure sequential execution.
- **Local values are module-internal**: Locals in `sso/locals.tf` are not exposed outside the module; they must be output in `sso/outputs.tf` to be used by `eks`.
- **Naming conventions**: All data sources and resources include module context in their names (e.g., `aws_identitystore_group.argocd_admin` in sso).
- **No cross-module references of locals**: If `eks` needs a value from `sso`, it must come through `sso`'s outputs, not through direct local access.

## Testing Individual Modules

Each module can be tested in isolation by creating a local `main.tf`:

```terraform
module "shared" {
  source = "../shared"
  
  cluster_name = "test"
  environment  = "dev"
  # ... other required variables
}

output "vpc_id" {
  value = module.shared.vpc_id
}
```

Then run `terraform init`, `terraform validate`, and `terraform plan` within that test directory.
