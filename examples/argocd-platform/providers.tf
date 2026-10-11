# -----------------------------------------------------------------------------
# Targets an existing cluster (created by terraform/environments/<env>/10-foundation).
# Same connection pattern as the Flux platform layer: IAM-gated DNS endpoint by default.
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

  kube_host = local.use_dns ? "https://${local.dns_endpoint}" : "https://${data.google_container_cluster.this.endpoint}"
  kube_ca   = local.use_dns ? null : base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
}

provider "kubernetes" {
  host                   = local.kube_host
  cluster_ca_certificate = local.kube_ca
  token                  = data.google_client_config.default.access_token
}

provider "helm" {
  kubernetes {
    host                   = local.kube_host
    cluster_ca_certificate = local.kube_ca
    token                  = data.google_client_config.default.access_token
  }
}

provider "kubectl" {
  host                   = local.kube_host
  cluster_ca_certificate = local.kube_ca
  token                  = data.google_client_config.default.access_token
  load_config_file       = false
}
