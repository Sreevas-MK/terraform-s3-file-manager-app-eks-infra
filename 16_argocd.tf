resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [
    module.eks_blueprints_addons,
    module.eks.eks_managed_node_groups,
    module.eks,
    module.vpc,
    module.eks.eks_managed_node_groups
  ]
}

resource "helm_release" "argocd" {
  name      = "argocd"
  namespace = kubernetes_namespace_v1.argocd.metadata[0].name

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  set {
    name  = "configs.cm.url"
    value = "https://${var.argocd_url}"
  }
  set {
    name  = "configs.params.server.insecure"
    value = "true"
  }

  depends_on = [
    kubernetes_namespace_v1.argocd
  ]
}
