locals {
  name = "${var.cluster_name}-${var.environment}"

  base_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "eks-argocd"
  }

  all_tags = merge(local.base_tags, var.tags)

  # Use the pre-built capability configuration from root module
  argocd_capability_configuration = var.argocd_capability_configuration
}
