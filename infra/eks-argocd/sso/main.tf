# Auto-discover the IAM Identity Center instance and identity store used by
# the ArgoCD capability for SSO login.
data "aws_ssoadmin_instances" "this" {
  count = var.enable_argocd_capability ? 1 : 0
}

# Resolve the IAM Identity Center groups that back the ArgoCD RBAC roles.
# We read the full group list and filter it locally so missing display names
# resolve to null instead of aborting the whole plan.
data "aws_identitystore_groups" "this" {
  count             = var.enable_argocd_capability && length(data.aws_ssoadmin_instances.this) > 0 ? 1 : 0
  identity_store_id = tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0]
}
