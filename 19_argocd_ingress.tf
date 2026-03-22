resource "kubernetes_ingress_v1" "argocd_shared_ingress" {
  depends_on = [
    kubernetes_namespace_v1.argocd,
    helm_release.argocd,
    module.eks_blueprints_addons,
    module.eks,
    module.eks.eks_managed_node_groups,
    module.ec2-openvpn,
    module.eks.oidc_provider_arn,
    module.vpc
  ]
  metadata {
    name      = "argocd-server-ingress"
    namespace = "argocd"
    annotations = {
      "kubernetes.io/ingress.class"                  = "alb"
      "alb.ingress.kubernetes.io/scheme"             = "internet-facing"
      "alb.ingress.kubernetes.io/group.name"         = var.alb_group_name
      "alb.ingress.kubernetes.io/load-balancer-name" = "eks-shared-alb"
      "alb.ingress.kubernetes.io/security-groups"    = aws_security_group.alb_sg.id
      "alb.ingress.kubernetes.io/certificate-arn"    = "arn:aws:acm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:certificate/${var.certificate_id}"
      "alb.ingress.kubernetes.io/listen-ports"       = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"       = "443"
      "alb.ingress.kubernetes.io/target-type"        = "ip"
      "external-dns.alpha.kubernetes.io/exclude"     = "true"

      # CRITICAL FOR ARGOCD BEHIND ALB
      "alb.ingress.kubernetes.io/backend-protocol"     = "HTTPS"
      "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTPS"
      "alb.ingress.kubernetes.io/healthcheck-path"     = "/healthz"
    }
  }

  spec {
    rule {
      host = var.argocd_url
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 443 # Port 443 is required when backend-protocol is HTTPS
              }
            }
          }
        }
      }
    }
  }
}
