resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
  depends_on = [
    module.eks_blueprints_addons,
    module.eks.eks_managed_node_groups
  ]
}

resource "helm_release" "monitoring_stack" {
  name      = "monitoring-stack"
  namespace = kubernetes_namespace_v1.monitoring.metadata[0].name

  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"

  recreate_pods = true

  values = [
    templatefile("${path.module}/files/values-s3.yaml.tpl", {
      loki_bucket_name     = aws_s3_bucket.loki_logs.bucket
      aws_region           = var.aws_region
      nodegroup_name       = "default"
      loki_service_account = "monitoring-stack-loki"
      loki_iam_role_arn    = module.loki_irsa.iam_role_arn
    }),

    yamlencode({
      grafana = {
        enabled = true
        "grafana.ini" = {
          server = {
            domain              = var.grafana_url
            root_url            = "https://${var.grafana_url}/"
            serve_from_sub_path = true
          }
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace_v1.monitoring,
    aws_s3_bucket.loki_logs,
    module.loki_irsa,
    module.eks_blueprints_addons,
    module.eks.eks_managed_node_groups
  ]
}

resource "kubectl_manifest" "grafana_datasources" {
  depends_on = [
    helm_release.monitoring_stack,
    module.eks_blueprints_addons
  ]

  yaml_body = file("${path.module}/files/monitoring-configmap.yml")
}
