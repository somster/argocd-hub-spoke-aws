variable "enable_argocd_capability" {
  description = "Enable the ArgoCD local-cluster secret"
  type        = bool
}

variable "argocd_namespace" {
  description = "Namespace where the ArgoCD cluster secret is created"
  type        = string
}

variable "cluster_arn" {
  description = "EKS cluster ARN used as ArgoCD server value"
  type        = string
}

