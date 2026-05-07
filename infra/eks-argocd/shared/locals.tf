locals {
  name = "${var.cluster_name}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  base_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "eks-argocd"
  }

  all_tags = merge(local.base_tags, var.tags)
}
