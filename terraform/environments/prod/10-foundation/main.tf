# -----------------------------------------------------------------------------
# prod / 10-foundation — project APIs, VPC, Cloud NAT, private regional GKE.
# Same module as dev; differences are deliberate: multi-zone, on-demand nodes,
# deletion protection, non-overlapping CIDRs. Next layer: ../20-platform.
# -----------------------------------------------------------------------------

module "gke_foundation" {
  source = "../../../modules/gke-foundation"

  project_id  = var.project_id
  name        = "platform-ref-gke"
  environment = "prod"
  region      = var.region

  subnet_cidr            = "10.16.0.0/20"
  pods_cidr              = "10.20.0.0/14"
  services_cidr          = "10.24.0.0/20"
  master_ipv4_cidr_block = "172.16.0.16/28"

  master_authorized_networks = var.master_authorized_networks
  enable_dns_endpoint        = true

  release_channel     = "REGULAR"
  cluster_zones       = [] # up to 3 zones in the region
  deletion_protection = true

  machine_type       = "e2-standard-4"
  min_node_count     = 1
  max_node_count     = 5
  initial_node_count = 1
  disk_size_gb       = 100
  spot               = false

  tags = {
    project = "gcp-gke-reference-platform"
  }
}
