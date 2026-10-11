# -----------------------------------------------------------------------------
# The cluster is created by ../10-foundation (separate state). This layer looks it
# up by name, so providers get a known endpoint at plan time — no -target step.
#
# Default: connect through the IAM-gated DNS endpoint (publicly trusted cert, no CA
# needed, works from any network incl. CI). Falls back to the IP endpoint + CA.
# -----------------------------------------------------------------------------

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "default" {}

data "google_container_cluster" "this" {
  name     = var.cluster_name
  location = var.region
}

locals {
  dns_endpoint = try(data.google_container_cluster.this.control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint, "")
  use_dns      = var.use_dns_endpoint && local.dns_endpoint != ""

  kubernetes_config = {
    host                   = local.use_dns ? "https://${local.dns_endpoint}" : "https://${data.google_container_cluster.this.endpoint}"
    cluster_ca_certificate = local.use_dns ? null : base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}

provider "kubernetes" {
  host                   = local.kubernetes_config.host
  cluster_ca_certificate = local.kubernetes_config.cluster_ca_certificate
  token                  = local.kubernetes_config.token
}

provider "flux" {
  kubernetes = local.kubernetes_config
  git = {
    url    = local.flux_git_url_https
    branch = var.flux_branch
    http = {
      username = var.flux_git_username
      password = local.flux_git_password
    }
  }
}

provider "flux" {
  alias      = "ssh"
  kubernetes = local.kubernetes_config
  git = {
    url    = local.flux_git_url_ssh
    branch = var.flux_branch
    ssh = {
      username    = "git"
      private_key = local.flux_ssh_private_key
      password    = local.flux_ssh_private_key_passphrase
    }
  }
}
