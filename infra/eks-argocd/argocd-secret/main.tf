resource "kubernetes_secret_v1" "argocd_local_cluster" {
  count = var.enable_argocd_capability ? 1 : 0

  metadata {
    name      = "local-cluster"
    namespace = var.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }

  data = {
    name    = "local-cluster"
    server  = var.cluster_arn
    project = "default"
  }
}
