# SSO Groups Configuration - Changes Summary

## Issue Found
During refactoring, the SSO groups configuration for ArgoCD EKS capability had structural issues that prevented proper RBAC role mappings.

## Root Cause
1. **sso/locals.tf**: Used singular `identity` instead of plural `identities` for the identities array
2. **eks/locals.tf**: 
   - Used `rbac_role_mapping` (singular) instead of `rbac_role_mappings` (plural)
   - Included unnecessary `namespace` field
   - Used `null` instead of `[]` for empty array default

## Files Modified

### 1. infra/eks-argocd/sso/locals.tf

**Before:**
```hcl
rbac_role_mappings = [
  for mapping in [
    local.resolved_admin_group_id != null ? {
      role     = "ADMIN"
      identity = [{ id = local.resolved_admin_group_id, type = "SSO_GROUP" }]  # ❌ singular
    } : null,
    ...
  ] : mapping if mapping != null
]
```

**After:**
```hcl
# Build the RBAC role mapping list – only include roles where a group ID was resolved
# Structure matches AWS EKS capability configuration for ArgoCD RBAC authentication
rbac_role_mappings = [
  for mapping in [
    local.resolved_admin_group_id != null ? {
      role       = "ADMIN"
      identities = [{ id = local.resolved_admin_group_id, type = "SSO_GROUP" }]  # ✅ plural
    } : null,
    ...
  ] : mapping if mapping != null
]
```

### 2. infra/eks-argocd/eks/locals.tf

**Before:**
```hcl
# ArgoCD capability configuration from SSO inputs
argocd_capability_configuration = var.sso_idc_instance_arn != null ? {
  argo_cd = {
    aws_idc = {
      idc_instance_arn = var.sso_idc_instance_arn
      idc_region       = var.sso_idc_region
    }
    namespace         = var.argocd_namespace              # ❌ unnecessary
    rbac_role_mapping = length(var.sso_rbac_role_mappings) > 0 ? var.sso_rbac_role_mappings : null  # ❌ singular + null default
  }
} : null
```

**After:**
```hcl
# ArgoCD capability configuration from SSO inputs
# Maps IAM Identity Center groups to ArgoCD RBAC roles (Admin, Editor, Viewer)
argocd_capability_configuration = var.sso_idc_instance_arn != null ? {
  argo_cd = {
    aws_idc = {
      idc_instance_arn = var.sso_idc_instance_arn
      idc_region       = var.sso_idc_region
    }
    rbac_role_mappings = length(var.sso_rbac_role_mappings) > 0 ? var.sso_rbac_role_mappings : []  # ✅ plural + [] default
  }
} : null
```

## Impact

These changes ensure that:
1. ✅ SSO groups are properly discovered from IAM Identity Center by display name
2. ✅ Group IDs are correctly resolved and mapped to RBAC roles (Admin, Editor, Viewer)
3. ✅ The configuration structure matches the AWS EKS capability API requirements
4. ✅ ArgoCD users will authenticate via SSO with appropriate permissions

## Data Flow

```
IAM Identity Center Groups
  ↓
sso/data_sources (aws_identitystore_groups) discovers groups
  ↓
sso/locals.tf resolves display names → group IDs
  ↓
sso/locals.tf builds rbac_role_mappings with correct structure:
  [{role: "ADMIN", identities: [{id: "...", type: "SSO_GROUP"}]}, ...]
  ↓
sso/outputs exports mappings to EKS module
  ↓
eks/locals.tf includes mappings in capability configuration
  ↓
module.argocd_eks_capability uses config to enable SSO auth
  ↓
ArgoCD enforces RBAC based on user's group membership
```

## Testing

To verify the changes:

1. Create test groups in AWS IAM Identity Center:
   - ArgoCD-Admins
   - ArgoCD-Editors
   - ArgoCD-Viewers

2. Deploy the infrastructure:
   ```bash
   cd infra/eks-argocd
   terraform init
   terraform plan
   terraform apply
   ```

3. Verify in AWS console:
   - Check EKS Capabilities shows ArgoCD is deployed
   - Check ArgoCD RBAC Assignments match your group mappings

4. Test SSO login:
   - Open the ArgoCD UI endpoint
   - Click "LOG IN VIA SSO"
   - Users in groups should be able to login with their permissions

## Reference Documentation

See [SSO_GROUPS_SETUP.md](./infra/eks-argocd/SSO_GROUPS_SETUP.md) for complete setup and configuration guide.
