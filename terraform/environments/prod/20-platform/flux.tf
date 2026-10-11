# -----------------------------------------------------------------------------
# Flux bootstrap: installs Flux and commits flux-system/ to the fleet repo at
# clusters/<cluster-name>/. After this, platform add-ons and apps live in Git.
# Fleet repo layout: ../../../../examples/flux-fleet-sample/
# -----------------------------------------------------------------------------

locals {
  flux_bootstrap_path = var.flux_path != "" ? var.flux_path : "clusters/${var.cluster_name}"

  # Both provider aliases are always configured; the unused one gets non-empty placeholders.
  flux_git_password = var.flux_token_auth ? coalesce(var.github_token, "x") : "x"
  flux_ssh_private_key = var.flux_token_auth ? " " : (
    trimspace(var.github_ssh_private_key_path) != "" ? file(pathexpand(var.github_ssh_private_key_path)) : coalesce(var.github_ssh_private_key, " ")
  )
  flux_ssh_private_key_passphrase = var.flux_token_auth ? "" : var.github_ssh_private_key_passphrase

  flux_git_url_https = replace(var.flux_git_url, "ssh://git@", "https://")
  flux_git_url_ssh   = replace(replace(var.flux_git_url, "https://", "ssh://git@"), "http://", "ssh://git@")
}

resource "kubernetes_namespace_v1" "flux_system" {
  metadata {
    name = var.flux_namespace
  }

  lifecycle {
    ignore_changes = [metadata[0].labels, metadata[0].annotations]
  }
}

# Cluster facts for Flux post-build substitution (${CLUSTER_NAME} etc. in the fleet repo).
resource "kubernetes_config_map_v1" "terraform_outputs" {
  metadata {
    name      = "terraform-outputs"
    namespace = kubernetes_namespace_v1.flux_system.metadata[0].name
  }

  data = {
    CLUSTER_NAME     = data.google_container_cluster.this.name
    CLUSTER_LOCATION = data.google_container_cluster.this.location
    GCP_PROJECT_ID   = var.project_id
    GCP_REGION       = var.region
    ENVIRONMENT      = "prod"
  }
}

resource "flux_bootstrap_git" "this" {
  count    = var.flux_token_auth ? 1 : 0
  provider = flux

  depends_on = [kubernetes_config_map_v1.terraform_outputs]

  path               = local.flux_bootstrap_path
  namespace          = var.flux_namespace
  version            = var.flux_version
  interval           = var.flux_interval
  embedded_manifests = true
  network_policy     = var.flux_network_policy
}

resource "flux_bootstrap_git" "this_ssh" {
  count    = var.flux_token_auth ? 0 : 1
  provider = flux.ssh

  depends_on = [kubernetes_config_map_v1.terraform_outputs]

  path               = local.flux_bootstrap_path
  namespace          = var.flux_namespace
  version            = var.flux_version
  interval           = var.flux_interval
  embedded_manifests = true
  network_policy     = var.flux_network_policy
}
