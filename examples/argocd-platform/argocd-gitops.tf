
# -----------------------------------------------------------------------------
# Declarative GitOps (Flux-style workflow): an Argo CD Application points at Git.
# After apply, change manifests in the repo and push — Argo syncs without UI.
# Example repo content: ../gitops-argocd-sample/
#
# Uses alekc/kubectl kubectl_manifest (not hashicorp/kubernetes kubernetes_manifest):
# the latter often fails on GKE with "cannot create REST client: no client config".
# -----------------------------------------------------------------------------
locals {
  argocd_gitops_enabled = var.install_argocd && trimspace(var.argocd_gitops_repo_url) != ""
}

resource "time_sleep" "wait_argocd_crds" {
  count = local.argocd_gitops_enabled ? 1 : 0

  create_duration = "${var.argocd_gitops_crds_wait_seconds}s"
  depends_on      = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_gitops_sample_app" {
  count = local.argocd_gitops_enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name       = var.argocd_gitops_application_name
      namespace  = var.argocd_namespace
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.argocd_gitops_repo_url
        targetRevision = var.argocd_gitops_target_revision
        path           = var.argocd_gitops_repo_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.argocd_gitops_destination_namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  })

  depends_on = [
    helm_release.argocd,
    time_sleep.wait_argocd_crds,
    kubernetes_secret_v1.argocd_gitops_repo_https,
    kubernetes_secret_v1.argocd_gitops_repo_ssh,
  ]
}
