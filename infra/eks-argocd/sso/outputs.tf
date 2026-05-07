output "idc_instance_arn" {
  description = "Auto-discovered IAM Identity Center instance ARN"
  value       = local.resolved_idc_instance_arn
}

output "idc_region" {
  description = "IAM Identity Center region (falls back to AWS region if not specified)"
  value       = coalesce(var.argocd_idc_region, var.aws_region)
}

output "admin_group_id" {
  description = "Resolved IAM Identity Center group ID for ArgoCD admins"
  value       = local.resolved_admin_group_id
}

output "editor_group_id" {
  description = "Resolved IAM Identity Center group ID for ArgoCD editors"
  value       = local.resolved_editor_group_id
}

output "viewer_group_id" {
  description = "Resolved IAM Identity Center group ID for ArgoCD viewers"
  value       = local.resolved_viewer_group_id
}

output "rbac_role_mappings" {
  description = "RBAC role mappings for the ArgoCD capability"
  value       = local.rbac_role_mappings
}
