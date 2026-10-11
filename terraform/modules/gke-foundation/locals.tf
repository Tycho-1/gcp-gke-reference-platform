locals {
  cluster_name = "${var.name}-${var.environment}"
  subnet_name  = "${local.cluster_name}-gke"

  pods_range_name     = var.enable_shared_vpc ? var.shared_vpc_pods_range_name : "ip-range-pods"
  services_range_name = var.enable_shared_vpc ? var.shared_vpc_services_range_name : "ip-range-svc"

  base_labels = merge(var.tags, {
    environment = var.environment
    terraform   = "true"
  })

  create_dedicated_vpc = !var.enable_shared_vpc
  create_cloud_nat     = var.enable_cloud_nat && local.create_dedicated_vpc

  gke_network    = var.enable_shared_vpc ? var.shared_vpc_network_name : module.network[0].network_name
  gke_subnetwork = var.enable_shared_vpc ? var.shared_vpc_subnetwork_name : module.network[0].subnets_names[0]

  # Single-pool defaults — used when node_pools is empty, and as merge base for custom pools.
  default_node_pool = {
    name                = var.node_pool_name
    machine_type        = var.machine_type
    min_count           = var.min_node_count
    max_count           = var.max_node_count
    local_ssd_count     = 0
    spot                = var.spot
    disk_size_gb        = var.disk_size_gb
    disk_type           = "pd-balanced"
    image_type          = "COS_CONTAINERD"
    enable_gcfs         = true
    enable_gvnic        = true
    logging_variant     = "DEFAULT"
    auto_repair         = true
    auto_upgrade        = true
    initial_node_count  = var.initial_node_count
    queued_provisioning = var.node_pool_queued_provisioning
  }

  # Empty node_pools → one pool from scalar variables (current behaviour).
  node_pools = length(var.node_pools) > 0 ? [
    for pool in var.node_pools : merge(local.default_node_pool, pool)
  ] : [local.default_node_pool]

  project_apis = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}
