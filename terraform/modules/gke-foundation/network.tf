# -----------------------------------------------------------------------------
# VPC + subnet + secondary IP ranges for VPC-native (Alias IP) GKE.
# Skipped when enable_shared_vpc = true (subnet + ranges must exist on host VPC).
# -----------------------------------------------------------------------------

module "network" {
  count = local.create_dedicated_vpc ? 1 : 0

  source  = "terraform-google-modules/network/google"
  version = "18.2.0"

  depends_on = [google_project_service.required]

  project_id   = var.project_id
  network_name = local.cluster_name
  mtu          = 1460

  subnets = [
    {
      subnet_name           = local.subnet_name
      subnet_ip             = var.subnet_cidr
      subnet_region         = var.region
      subnet_private_access = var.subnet_private_access ? "true" : "false"
    }
  ]

  secondary_ranges = {
    (local.subnet_name) = [
      {
        range_name    = local.pods_range_name
        ip_cidr_range = var.pods_cidr
      },
      {
        range_name    = local.services_range_name
        ip_cidr_range = var.services_cidr
      }
    ]
  }
}

# Private GKE nodes have no external IPs; Private Google Access covers Google APIs only.
# Cloud NAT provides SNAT for general internet egress (image pulls, package repos, etc.).
# Not created for Shared VPC — egress/NAT is owned by the host project.
resource "google_compute_router" "gke" {
  count = local.create_cloud_nat ? 1 : 0

  name    = "${local.cluster_name}-router"
  region  = var.region
  network = module.network[0].network_id
  project = var.project_id
}

resource "google_compute_router_nat" "gke" {
  count = local.create_cloud_nat ? 1 : 0

  name    = "${local.cluster_name}-nat"
  project = var.project_id
  region  = var.region
  router  = google_compute_router.gke[0].name

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
