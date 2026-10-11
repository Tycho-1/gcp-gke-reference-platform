# -----------------------------------------------------------------------------
# Regional GKE private cluster (nodes private; IP endpoint public unless you set
# enable_private_endpoint, gated by master_authorized_networks; optional
# IAM-gated DNS endpoint). VPC-native Alias IPs; Dataplane V2 by default.
# Upstream: terraform-google-modules/kubernetes-engine private-cluster.
# -----------------------------------------------------------------------------

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "45.0.0"

  depends_on = [
    google_project_service.required,
    module.network,
    google_compute_router_nat.gke,
  ]

  project_id = var.project_id
  name       = local.cluster_name
  regional   = true
  region     = var.region
  zones      = var.cluster_zones

  network            = local.gke_network
  subnetwork         = local.gke_subnetwork
  network_project_id = var.enable_shared_vpc ? var.shared_vpc_host_project_id : ""
  ip_range_pods      = local.pods_range_name
  ip_range_services  = local.services_range_name

  kubernetes_version = var.kubernetes_version
  release_channel    = var.release_channel

  enable_private_endpoint = var.enable_private_endpoint
  enable_private_nodes    = var.enable_private_nodes
  master_ipv4_cidr_block  = var.master_ipv4_cidr_block

  deletion_protection = var.deletion_protection

  master_authorized_networks = var.master_authorized_networks
  dns_allow_external_traffic = var.enable_dns_endpoint ? true : null

  add_cluster_firewall_rules = var.add_cluster_firewall_rules

  datapath_provider                        = var.datapath_provider
  network_policy                           = var.network_policy
  enable_cilium_clusterwide_network_policy = var.enable_cilium_clusterwide_network_policy
  identity_namespace                       = var.identity_namespace
  enable_shielded_nodes                    = var.enable_shielded_nodes
  security_posture_mode                    = var.security_posture_mode
  security_posture_vulnerability_mode      = var.security_posture_vulnerability_mode
  enable_binary_authorization              = var.enable_binary_authorization
  enable_vertical_pod_autoscaling          = var.enable_vertical_pod_autoscaling
  gateway_api_channel                      = var.gateway_api_channel
  monitoring_enable_managed_prometheus     = var.monitoring_enable_managed_prometheus

  maintenance_start_time = var.maintenance_start_time
  maintenance_end_time   = var.maintenance_end_time
  maintenance_recurrence = var.maintenance_recurrence
  maintenance_exclusions = var.maintenance_exclusions

  remove_default_node_pool = true
  create_service_account   = true

  node_pools = local.node_pools

  node_pools_labels = {
    all = local.base_labels
  }

  node_pools_tags = {
    all = ["gke-node", local.cluster_name]
  }

  cluster_resource_labels = local.base_labels
}
