# EKS outputs
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS control plane endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate authority data for the EKS cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = module.eks.cluster_oidc_provider_arn
}

output "argocd_capability_arn" {
  description = "ARN of the EKS ArgoCD capability"
  value       = module.eks.argocd_capability_arn
}

output "argocd_capability_version" {
  description = "Version of the EKS ArgoCD capability"
  value       = module.eks.argocd_capability_version
}

output "argocd_server_url" {
  description = "ArgoCD server URL from EKS capability"
  value       = module.eks.argocd_server_url
}

output "argocd_capability_iam_role_arn" {
  description = "IAM role ARN used by EKS ArgoCD capability"
  value       = module.eks.argocd_capability_iam_role_arn
}
