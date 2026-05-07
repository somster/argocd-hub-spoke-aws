variable "argocd_admin_group_name" {
  description = "Display name of the IAM Identity Center group to map to ArgoCD ADMIN role. This is the friendly SSO group name Terraform resolves to the actual group ID via a data source lookup."
  type        = string
  default     = "ArgoCD-Admins"
}

variable "argocd_editor_group_name" {
  description = "Display name of the IAM Identity Center group to map to ArgoCD EDITOR role. This is the friendly SSO group name Terraform resolves to the actual group ID via a data source lookup."
  type        = string
  default     = "ArgoCD-Editors"
}

variable "argocd_viewer_group_name" {
  description = "Display name of the IAM Identity Center group to map to ArgoCD VIEWER role. This is the friendly SSO group name Terraform resolves to the actual group ID via a data source lookup."
  type        = string
  default     = "ArgoCD-Viewers"
}

variable "argocd_idc_region" {
  description = "Optional IAM Identity Center region. Falls back to AWS region if not specified."
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "enable_argocd_capability" {
  description = "Enable native EKS ArgoCD capability via EKS capability API"
  type        = bool
  default     = true
}
