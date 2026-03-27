resource "null_resource" "destruction_dependencies" {
  triggers = {
    app_name      = var.app_name
    app_namespace = var.app_namespace
  }

  depends_on = [
    kubectl_manifest.s3_nodejs_app,
    helm_release.argocd,
    helm_release.monitoring_stack,
    kubernetes_ingress_v1.grafana_ingress,
    kubernetes_ingress_v1.argocd_shared_ingress
  ]

  provisioner "local-exec" {
    when = destroy

    command = <<EOT
      echo "Cleaning ingress finalizers..."

      # App ingress
      kubectl patch ingress ${self.triggers.app_name}-ingress \
        -n ${self.triggers.app_namespace} \
        -p '{"metadata":{"finalizers":[]}}' --type=merge || true

      # ArgoCD ingress
      kubectl patch ingress argocd-server-ingress \
        -n argocd \
        -p '{"metadata":{"finalizers":[]}}' --type=merge || true

      # Grafana ingress
      kubectl patch ingress grafana-ingress \
        -n monitoring \
        -p '{"metadata":{"finalizers":[]}}' --type=merge || true

      echo "Waiting for ALB cleanup..."
      sleep 120
    EOT
  }
}


resource "null_resource" "infra_anchor" {
  depends_on = [null_resource.destruction_dependencies]
}
