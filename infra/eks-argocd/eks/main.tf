module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  endpoint_public_access  = var.cluster_endpoint_public_access
  endpoint_private_access = true

  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true

  addons = {
    coredns = {}
    kube-proxy = {}
    vpc-cni = {}
    eks-pod-identity-agent = {}
  }

  compute_config = {
    enabled    = var.enable_eks_auto_mode
    node_pools = var.eks_auto_mode_node_pools
  }

  tags = local.all_tags
}

module "argocd_eks_capability" {
  source  = "terraform-aws-modules/eks/aws//modules/capability"
  version = "~> 21.0"

  create = var.enable_argocd_capability

  name         = var.argocd_capability_name
  cluster_name = module.eks.cluster_name
  type         = "ARGOCD"

  configuration            = local.argocd_capability_configuration
  delete_propagation_policy = "RETAIN"

  # Baseline ECR pull permissions for images managed by the capability.
  iam_policy_statements = {
    ECRRead = {
      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ]
      resources = ["*"]
    }
  }

  tags = local.all_tags

  depends_on = [module.eks]
}

# Attach AWSSecretsManagerClientReadOnlyAccess to the capability role.
# Provides read access to Secrets Manager, the AWS-recommended starter policy
# for the ArgoCD EKS capability.
resource "aws_iam_role_policy_attachment" "argocd_secrets_manager" {
  count      = var.enable_argocd_capability ? 1 : 0
  role       = regex("[^/]+$", module.argocd_eks_capability.iam_role_arn)
  policy_arn = "arn:aws:iam::aws:policy/AWSSecretsManagerClientReadOnlyAccess"

  depends_on = [module.argocd_eks_capability]
}

# Associate AmazonEKSClusterAdminPolicy with the ArgoCD capability access entry.
# Without this policy, ArgoCD cannot list cluster-scoped resources and all
# applications will report sync/connection errors.
resource "aws_eks_access_policy_association" "argocd_cluster_admin" {
  count = var.enable_argocd_capability ? 1 : 0

  cluster_name  = module.eks.cluster_name
  principal_arn = module.argocd_eks_capability.iam_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [module.argocd_eks_capability]
}
