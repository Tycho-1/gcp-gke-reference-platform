# -----------------------------------------------------------------------------
# Argo CD — GitOps CD (official argo-helm chart).
# Values: helm/argocd-values.yaml (best-practice defaults) + small Terraform overrides.
# Docs: https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd
# -----------------------------------------------------------------------------

locals {
  argocd_values_base = file("${path.module}/helm/argocd-values.yaml")

  # Later values override earlier; lets Terraform toggle bootstrap admin without editing YAML.
  argocd_values_overrides = yamlencode({
    configs = {
      cm = {
        "admin.enabled" = var.argocd_admin_enabled ? "true" : "false"
      }
    }
  })
}

resource "helm_release" "argocd" {
  count = var.install_argocd ? 1 : 0

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = var.argocd_namespace
  create_namespace = true

  # Helm best practices: wait for readiness, fail the whole release on error, cap history
  wait              = var.argocd_helm_wait
  timeout           = var.argocd_helm_timeout
  atomic            = var.argocd_helm_atomic
  cleanup_on_fail   = var.argocd_helm_cleanup_on_fail
  max_history       = var.argocd_helm_max_history
  wait_for_jobs     = var.argocd_helm_wait_for_jobs
  dependency_update = false
  skip_crds         = false
  replace           = false

  values = [
    local.argocd_values_base,
    local.argocd_values_overrides,
  ]

  set = concat(
    [{
      name  = "server.service.type"
      value = var.argocd_server_service_type
    }],
    var.argocd_global_domain != "" ? [{
      name  = "global.domain"
      value = var.argocd_global_domain
    }] : [],
  )
}
