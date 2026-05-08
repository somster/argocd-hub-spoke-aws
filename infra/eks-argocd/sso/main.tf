# Auto-discover the IAM Identity Center instance and identity store used by
# the ArgoCD capability for SSO login.
data "aws_ssoadmin_instances" "this" {
  count = var.enable_argocd_capability ? 1 : 0
}

# Create IAM Identity Center groups for ArgoCD RBAC roles.
# Groups are managed by Terraform and will be destroyed when infrastructure is destroyed.
resource "aws_identitystore_group" "argocd_admin" {
  count             = var.enable_argocd_capability ? 1 : 0
  identity_store_id = local.identity_store_id
  display_name      = var.argocd_admin_group_name
  description       = "ArgoCD Admin role - full administrative access to ArgoCD"
}

resource "aws_identitystore_group" "argocd_editor" {
  count             = var.enable_argocd_capability ? 1 : 0
  identity_store_id = local.identity_store_id
  display_name      = var.argocd_editor_group_name
  description       = "ArgoCD Editor role - edit access to ArgoCD resources"
}

resource "aws_identitystore_group" "argocd_viewer" {
  count             = var.enable_argocd_capability ? 1 : 0
  identity_store_id = local.identity_store_id
  display_name      = var.argocd_viewer_group_name
  description       = "ArgoCD Viewer role - read-only access to ArgoCD resources"
}
