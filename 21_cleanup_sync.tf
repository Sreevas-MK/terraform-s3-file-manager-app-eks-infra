resource "null_resource" "destruction_dependencies" {
  # This list contains everything that can "stall" a delete
  depends_on = [
    kubectl_manifest.s3_nodejs_app,
    kubectl_manifest.grafana_datasources,
    helm_release.monitoring_stack,
    helm_release.argocd,
    kubernetes_ingress_v1.grafana_ingress,
    kubernetes_ingress_v1.argocd_shared_ingress,
    kubernetes_namespace_v1.app_ns,
    kubernetes_namespace_v1.monitoring,
    kubernetes_namespace_v1.argocd
  ]

  provisioner "local-exec" {
    when    = destroy
    command = "sleep 180"
  }
}
