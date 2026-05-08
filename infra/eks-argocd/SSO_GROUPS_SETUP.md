# SSO Groups Configuration for ArgoCD EKS Capability

## Overview

This document describes how IAM Identity Center (IDC) groups are configured and mapped to ArgoCD RBAC roles in the EKS ArgoCD capability.

## Architecture Flow

```
IAM Identity Center (AWS SSO)
        ↓
   [Groups defined in IDC]
   - ArgoCD-Admins
   - ArgoCD-Editors  
   - ArgoCD-Viewers
        ↓
sso/main.tf [data sources discover groups]
        ↓
sso/locals.tf [resolve group IDs & build RBAC mappings]
        ↓
sso/outputs.tf [export mappings to EKS module]
        ↓
eks/locals.tf [ArgoCD capability configuration]
        ↓
module.argocd_eks_capability [AWS EKS Capability API]
        ↓
ArgoCD UI [Users login via SSO, get permissions based on group membership]
```

## Configuration Details

### SSO Module (./sso/)

#### Variables
Configure the display names of your IAM Identity Center groups:

```hcl
# variables.tf (root level)
argocd_admin_group_name   = "ArgoCD-Admins"    # or your custom name
argocd_editor_group_name  = "ArgoCD-Editors"   # or your custom name
argocd_viewer_group_name  = "ArgoCD-Viewers"   # or your custom name
argocd_idc_region         = "us-east-1"        # optional, defaults to aws_region
```

#### Data Sources (main.tf)
- `aws_ssoadmin_instances` - Auto-discovers the IAM Identity Center instance
- `aws_identitystore_groups` - Fetches all groups from the identity store

#### Group Resolution (locals.tf)
The module resolves group display names to group IDs:

```hcl
# Example:
resolved_admin_group_id = one([for group in groups : group.group_id if group.display_name == "ArgoCD-Admins"])
```

#### RBAC Mappings (locals.tf)
Builds the proper structure for ArgoCD capability:

```hcl
rbac_role_mappings = [
  {
    role       = "ADMIN"
    identities = [{ id = "group-id-123", type = "SSO_GROUP" }]
  },
  {
    role       = "EDITOR"
    identities = [{ id = "group-id-456", type = "SSO_GROUP" }]
  },
  {
    role       = "VIEWER"
    identities = [{ id = "group-id-789", type = "SSO_GROUP" }]
  }
]
```

#### Outputs (outputs.tf)
- `idc_instance_arn` - The ARN of the IAM Identity Center instance
- `idc_region` - The region where IDC is deployed
- `rbac_role_mappings` - The complete RBAC mappings for ArgoCD
- Individual group ID outputs for reference

### EKS Module (./eks/)

#### Configuration (locals.tf)
Uses SSO module outputs to construct the ArgoCD capability configuration:

```hcl
argocd_capability_configuration = {
  argo_cd = {
    aws_idc = {
      idc_instance_arn = var.sso_idc_instance_arn
      idc_region       = var.sso_idc_region
    }
    rbac_role_mappings = var.sso_rbac_role_mappings
  }
}
```

This configuration is passed to the EKS ArgoCD capability module.

## Prerequisites

1. **IAM Identity Center Setup**
   - IAM Identity Center must be enabled in your AWS account
   - Groups must be created in IDC with the display names matching your configuration
   - Users must be added to appropriate groups

2. **Terraform State**
   - SSO module must be applied before EKS module (dependency managed in main.tf)

## Deployment Steps

1. **Create Groups in IAM Identity Center**
   - Navigate to AWS IAM Identity Center console
   - Create groups matching the configured names:
     - ArgoCD-Admins
     - ArgoCD-Editors
     - ArgoCD-Viewers
   - Add users to appropriate groups

2. **Configure Terraform Variables**
   ```bash
   # terraform.tfvars
   enable_argocd_capability = true
   argocd_admin_group_name  = "ArgoCD-Admins"
   argocd_editor_group_name = "ArgoCD-Editors"
   argocd_viewer_group_name = "ArgoCD-Viewers"
   ```

3. **Deploy Infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Access ArgoCD**
   - Once the capability is deployed, get the ArgoCD UI endpoint from AWS EKS console
   - Click "LOG IN VIA SSO"
   - Users will be authenticated via their IDC credentials
   - Users will have permissions based on their group membership

## ArgoCD RBAC Roles

- **ADMIN** - Full administrative access to ArgoCD
- **EDITOR** - Edit access to ArgoCD resources
- **VIEWER** - Read-only access to ArgoCD resources

## Troubleshooting

### Groups Not Resolving
- Verify group display names exactly match the configured variable values
- Check that groups exist in the IAM Identity Center
- Confirm the IDC region is correct

### Users Can't Login
- Verify users are added to the appropriate IDC groups
- Check that the ArgoCD capability was deployed successfully
- Review AWS CloudWatch logs for the capability

### Missing Permissions in ArgoCD
- Confirm user's IDC group membership
- Check that the group is mapped to an appropriate RBAC role
- Review the `aws eks list-access-entries` output to verify the capability has proper cluster permissions

## Reference

- [AWS Dev.to Article: Get Started with Argo CD EKS Capability](https://dev.to/aws-heroes/get-started-with-the-argo-cd-eks-capability-36kd)
- [AWS EKS Capabilities Documentation](https://docs.aws.amazon.com/eks/latest/userguide/capabilities.html)
- [AWS IAM Identity Center Documentation](https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html)
