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

# ArgoCD capability configuration (pre-built by root module)
variable "argocd_capability_configuration" {
  description = "Pre-built ArgoCD capability configuration with SSO and RBAC settings"
  type        = any
  default     = null
}
