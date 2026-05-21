output "cluster_name" {
  description = "Cluster Hub name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Cluster Hub endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Cluster Hub certificate_authority_data"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_region" {
  description = "Cluster Hub region"
  value       = local.region
}

output "argocd_iam_role_arn" {
  description = "IAM Role ARN used by ArgoCD on the Hub cluster to assume spoke roles"
  value       = aws_iam_role.argocd_hub.arn
}

