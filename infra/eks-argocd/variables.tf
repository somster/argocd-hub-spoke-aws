variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name used for naming and tags"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "test-cluster"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.32"
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
  default     = "10.42.0.0/16"
}

variable "az_count" {
  description = "How many AZs to use"
  type        = number
  default     = 3
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, one per AZ"
  type        = list(string)
  default     = ["10.42.0.0/24", "10.42.1.0/24", "10.42.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs, one per AZ"
  type        = list(string)
  default     = ["10.42.10.0/24", "10.42.11.0/24", "10.42.12.0/24"]
}

variable "cluster_endpoint_public_access" {
  description = "Whether EKS API server endpoint is public"
  type        = bool
  default     = true
}

variable "enable_eks_auto_mode" {
  description = "Enable EKS Auto Mode"
  type        = bool
  default     = true
}

variable "eks_auto_mode_node_pools" {
  description = "EKS Auto Mode node pools"
  type        = list(string)
  default     = ["system", "general-purpose"]
}

variable "enable_argocd_capability" {
  description = "Enable native EKS ArgoCD capability via EKS capability API"
  type        = bool
  default     = true
}

variable "argocd_capability_name" {
  description = "Capability name for EKS ArgoCD capability"
  type        = string
  default     = "argocd"
}

variable "argocd_namespace" {
  description = "Kubernetes namespace where EKS capability provisions ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_idc_region" {
  description = "Optional IAM Identity Center region"
  type        = string
  default     = null
}

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

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
