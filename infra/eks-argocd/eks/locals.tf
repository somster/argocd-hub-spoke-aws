locals {
  name = "${var.cluster_name}-${var.environment}"

  base_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "eks-argocd"
  }

  all_tags = merge(local.base_tags, var.tags)

  # ArgoCD capability configuration from SSO inputs
  argocd_capability_configuration = var.sso_idc_instance_arn != null ? {
    argo_cd = {
      aws_idc = {
        idc_instance_arn = var.sso_idc_instance_arn
        idc_region       = var.sso_idc_region
      }
      namespace         = var.argocd_namespace
      rbac_role_mapping = length(var.sso_rbac_role_mappings) > 0 ? var.sso_rbac_role_mappings : null
    }
  } : null
}
