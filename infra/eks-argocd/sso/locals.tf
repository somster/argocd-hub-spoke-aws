locals {
  # Auto-discovered IAM Identity Center instance ARN
  resolved_idc_instance_arn = try(tolist(data.aws_ssoadmin_instances.this[0].arns)[0], null)

  # Identity Store ID – used for group creation
  identity_store_id = try(tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0], null)

  # Resolve group IDs from the created Terraform resources
  resolved_admin_group_id  = try(aws_identitystore_group.argocd_admin[0].group_id, null)
  resolved_editor_group_id = try(aws_identitystore_group.argocd_editor[0].group_id, null)
  resolved_viewer_group_id = try(aws_identitystore_group.argocd_viewer[0].group_id, null)

  # Build the RBAC role mapping list – only include roles where a group ID was resolved
  # Structure matches AWS EKS capability configuration for ArgoCD RBAC authentication
  rbac_role_mappings = [
    for mapping in [
      local.resolved_admin_group_id != null ? {
        role       = "ADMIN"
        identities = [{ id = local.resolved_admin_group_id, type = "SSO_GROUP" }]
      } : null,
      local.resolved_editor_group_id != null ? {
        role       = "EDITOR"
        identities = [{ id = local.resolved_editor_group_id, type = "SSO_GROUP" }]
      } : null,
      local.resolved_viewer_group_id != null ? {
        role       = "VIEWER"
        identities = [{ id = local.resolved_viewer_group_id, type = "SSO_GROUP" }]
      } : null,
    ] : mapping if mapping != null
  ]
}
