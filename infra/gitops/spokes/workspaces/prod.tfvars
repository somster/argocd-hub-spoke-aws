region             = "us-west-2"
kubernetes_version = "1.31"
project_name       = "illand"
environment        = "prod"
addons = {
  enable_aws_load_balancer_controller = true
  enable_metrics_server               = true
  # Disable argo-deployments on spoke clusters - managed by hub
  enable_aws_argocd = false
  enable_argocd     = false
}
authentication_mode = "API"
