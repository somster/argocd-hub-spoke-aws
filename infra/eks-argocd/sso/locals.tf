locals {
  # Auto-discovered IAM Identity Center instance ARN
  resolved_idc_instance_arn = try(tolist(data.aws_ssoadmin_instances.this[0].arns)[0], null)

  # Identity Store ID – used for group lookups and informational outputs
  identity_store_id = try(tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0], null)

  identity_store_groups = try(data.aws_identitystore_groups.this[0].groups, [])

  # Resolve group IDs directly from the configured display names.
  resolved_admin_group_id = try(
    one([for group in local.identity_store_groups : group.group_id if group.display_name == var.argocd_admin_group_name]),
    null
  )
  resolved_editor_group_id = try(
    one([for group in local.identity_store_groups : group.group_id if group.display_name == var.argocd_editor_group_name]),
    null
  )
  resolved_viewer_group_id = try(
    one([for group in local.identity_store_groups : group.group_id if group.display_name == var.argocd_viewer_group_name]),
    null
  )

  # Build the RBAC role mapping list – only include roles where a group ID was resolved
  rbac_role_mappings = [
    for mapping in [
      local.resolved_admin_group_id != null ? {
        role     = "ADMIN"
        identity = [{ id = local.resolved_admin_group_id, type = "SSO_GROUP" }]
      } : null,
      local.resolved_editor_group_id != null ? {
        role     = "EDITOR"
        identity = [{ id = local.resolved_editor_group_id, type = "SSO_GROUP" }]
      } : null,
      local.resolved_viewer_group_id != null ? {
        role     = "VIEWER"
        identity = [{ id = local.resolved_viewer_group_id, type = "SSO_GROUP" }]
      } : null,
    ] : mapping if mapping != null
  ]
}
