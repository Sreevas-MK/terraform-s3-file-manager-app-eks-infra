resource "kubernetes_namespace_v1" "app_ns" {
  depends_on = [
    helm_release.argocd,
    module.eks,
    module.eks_blueprints_addons,
    module.ec2-openvpn,
    module.vpc
  ]
  metadata {
    name = var.app_namespace
    labels = {
      "pod-security.kubernetes.io/enforce"         = "baseline"
      "pod-security.kubernetes.io/enforce-version" = "latest"
      "pod-security.kubernetes.io/warn"            = "restricted"
      "pod-security.kubernetes.io/warn-version"    = "latest"
    }
  }
}


resource "kubectl_manifest" "s3_nodejs_app" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${var.app_name}
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: ${var.app_repo_url}
    targetRevision: HEAD
    path: ${var.app_repo_path}
    helm:
      parameters:
        - name: "global.host"
          value: "${var.app_host}"
        - name: "global.namespace"
          value: "${var.app_namespace}"
        - name: "global.certificate_arn"
          value: "arn:aws:acm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:certificate/${var.certificate_id}"
        - name: "global.vpc_cidr"
          value: "${module.vpc.vpc_cidr_block}"
        - name: "app.name"
          value: "${var.app_name}"
        - name: "global.alb_group_name"
          value: "${var.alb_group_name}"
        - name: "global.alb_lb_name"
          value: "eks-shared-alb"
        - name: "global.alb_sg_id"
          value: "${aws_security_group.alb_sg.id}"
        - name: "app.env.AWS_REGION"
          value: "${var.aws_region}"
        - name: "app.env.S3_BUCKET_NAME"
          value: "${var.app_bucket_name}"
        - name: "aws.region"
          value: "${var.aws_region}"
  destination:
    server: https://kubernetes.default.svc
    namespace: ${var.app_namespace}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=false
YAML

  depends_on = [
    kubernetes_namespace_v1.app_ns,
    helm_release.argocd,
    module.eks,
    module.eks_blueprints_addons,
    module.eks.eks_managed_node_groups,
    module.ec2-openvpn,
    module.eks.oidc_provider_arn,
    module.vpc
  ]
  wait = false
}
