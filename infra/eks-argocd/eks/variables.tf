variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.32"
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

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "environment" {
  description = "Environment name used for naming and tags"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

# Inputs from shared module
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs"
  type        = list(string)
}

# Inputs from SSO module
variable "sso_idc_instance_arn" {
  description = "IAM Identity Center instance ARN from SSO module"
  type        = string
}

variable "sso_idc_region" {
  description = "IAM Identity Center region from SSO module"
  type        = string
}

variable "sso_rbac_role_mappings" {
  description = "RBAC role mappings from SSO module"
  type        = list(any)
}
