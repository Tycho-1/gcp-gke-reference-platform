# -----------------------------------------------------------------------------
# dev / 10-foundation — project APIs, VPC, Cloud NAT, private regional GKE.
# Environment opinions live here as literals; only per-user values are variables.
# Next layer: ../20-platform (Flux bootstrap), separate state.
# -----------------------------------------------------------------------------

module "gke_foundation" {
  source = "../../../modules/gke-foundation"

  project_id  = var.project_id
  name        = "platform-ref-gke"
  environment = "dev"
  region      = var.region

  subnet_cidr            = "10.0.0.0/20"
  pods_cidr              = "10.4.0.0/14"
  services_cidr          = "10.8.0.0/20"
  master_ipv4_cidr_block = "172.16.0.0/28"

  master_authorized_networks = var.master_authorized_networks
  enable_dns_endpoint        = true

  release_channel     = "REGULAR"
  cluster_zones       = var.cluster_zones
  deletion_protection = false

  # Lab cost profile: Spot nodes, scale to zero when idle.
  machine_type       = "e2-standard-4"
  min_node_count     = 0
  max_node_count     = 3
  initial_node_count = 1
  disk_size_gb       = 50
  spot               = true

  tags = {
    project = "gcp-gke-reference-platform"
  }
}
