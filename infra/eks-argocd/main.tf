data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

module "shared" {
  source = "./shared"

  cluster_name         = var.cluster_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  az_count             = var.az_count
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = var.tags
}

module "sso" {
  source = "./sso"

  enable_argocd_capability = var.enable_argocd_capability
  argocd_admin_group_name  = var.argocd_admin_group_name
  argocd_editor_group_name = var.argocd_editor_group_name
  argocd_viewer_group_name = var.argocd_viewer_group_name
}

module "eks" {
  source = "./eks"

  cluster_name                   = var.cluster_name
  kubernetes_version             = var.kubernetes_version
  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  enable_eks_auto_mode           = var.enable_eks_auto_mode
  eks_auto_mode_node_pools       = var.eks_auto_mode_node_pools
  enable_argocd_capability       = var.enable_argocd_capability
  argocd_capability_name         = var.argocd_capability_name
  argocd_namespace               = var.argocd_namespace
  environment                    = var.environment
  tags                           = var.tags
  vpc_id                         = module.shared.vpc_id
  private_subnets                = module.shared.private_subnets
  argocd_capability_configuration = var.enable_argocd_capability ? {
    argo_cd = {
      aws_idc = {
        idc_instance_arn = module.sso.idc_instance_arn
      }
      rbac_role_mappings = module.sso.rbac_role_mappings
    }
  } : null

  depends_on = [module.shared, module.sso]
}

module "argocd_secret" {
  source = "./argocd-secret"

  enable_argocd_capability = var.enable_argocd_capability
  argocd_namespace         = var.argocd_namespace
  cluster_arn              = "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${module.eks.cluster_name}"

  depends_on = [module.eks]
}
