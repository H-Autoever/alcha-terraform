# eks_argocd.tf
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = var.argocd_version

  values = [yamlencode({
    server = {
      service = {
        type = "ClusterIP" # 외부 노출
      }
      ingress = {
        enabled = true
        annotations = {
          "kubernetes.io/ingress.class" = "alb"
          "alb.ingress.kubernetes.io/scheme" = "internet-facing"
          "alb.ingress.kubernetes.io/target-type" = "ip"
        }
        hosts = ["argocd.team-alcha.local"] # 임시 호스트명
        https = false
      }
    }
    global = {
      domain = "team-alcha.local" # 임시 도메인 설정
    }
  })]

  depends_on = [
    kubernetes_namespace.argocd,
    module.eks
  ]
}
