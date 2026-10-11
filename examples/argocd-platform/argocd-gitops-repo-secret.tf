# Optional credentials so Argo CD can clone private Git repos.
# Docs: https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#repositories
# Public repos: leave argocd_gitops_https_password and argocd_gitops_ssh_private_key empty.

check "argocd_gitops_repo_creds_mutex" {
  assert {
    condition = !(
      trimspace(var.argocd_gitops_https_password) != "" &&
      trimspace(var.argocd_gitops_ssh_private_key) != ""
    )
    error_message = "Set only one of argocd_gitops_https_password (HTTPS/PAT) or argocd_gitops_ssh_private_key (SSH)."
  }
}

locals {
  argocd_gitops_https_creds = local.argocd_gitops_enabled && trimspace(var.argocd_gitops_https_password) != ""
  argocd_gitops_ssh_creds   = local.argocd_gitops_enabled && trimspace(var.argocd_gitops_ssh_private_key) != ""

  argocd_gitops_repo_credential_url = trimspace(var.argocd_gitops_repo_credential_url_prefix) != "" ? trimspace(var.argocd_gitops_repo_credential_url_prefix) : trimsuffix(trimspace(var.argocd_gitops_repo_url), ".git")
}

resource "kubernetes_secret_v1" "argocd_gitops_repo_https" {
  count = local.argocd_gitops_https_creds ? 1 : 0

  metadata {
    name      = "${var.argocd_gitops_application_name}-repo-https"
    namespace = var.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = base64encode("git")
    url      = base64encode(local.argocd_gitops_repo_credential_url)
    username = base64encode(var.argocd_gitops_https_username)
    password = base64encode(var.argocd_gitops_https_password)
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_secret_v1" "argocd_gitops_repo_ssh" {
  count = local.argocd_gitops_ssh_creds ? 1 : 0

  metadata {
    name      = "${var.argocd_gitops_application_name}-repo-ssh"
    namespace = var.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type          = base64encode("git")
    url           = base64encode(local.argocd_gitops_repo_credential_url)
    sshPrivateKey = base64encode(var.argocd_gitops_ssh_private_key)
  }

  depends_on = [helm_release.argocd]
}
