check "shared_vpc_inputs" {
  assert {
    condition = !var.enable_shared_vpc || (
      trimspace(var.shared_vpc_host_project_id) != "" &&
      trimspace(var.shared_vpc_network_name) != "" &&
      trimspace(var.shared_vpc_subnetwork_name) != ""
    )
    error_message = "When enable_shared_vpc is true, set shared_vpc_host_project_id, shared_vpc_network_name, and shared_vpc_subnetwork_name (subnet must already have secondary pod/service ranges)."
  }
}

check "cilium_clusterwide_requires_dataplane_v2" {
  assert {
    condition     = !var.enable_cilium_clusterwide_network_policy || var.datapath_provider == "ADVANCED_DATAPATH"
    error_message = "enable_cilium_clusterwide_network_policy requires datapath_provider = \"ADVANCED_DATAPATH\" (Dataplane V2)."
  }
}

check "node_pool_names_unique" {
  assert {
    condition     = length(distinct([for pool in local.node_pools : pool.name])) == length(local.node_pools)
    error_message = "Each node pool must have a unique name."
  }
}

check "pods_cidr_canonical" {
  assert {
    condition     = var.pods_cidr == "${cidrhost(var.pods_cidr, 0)}/${tonumber(split("/", var.pods_cidr)[1])}"
    error_message = "pods_cidr must be a canonical CIDR on its prefix boundary (e.g. 10.4.0.0/14, not 10.5.0.0/14). GCP rejects misaligned secondary ranges."
  }
}

check "spot_and_queued_provisioning" {
  assert {
    condition     = !var.node_pool_queued_provisioning || !var.spot
    error_message = "node_pool_queued_provisioning and spot are mutually exclusive on GKE."
  }
}

check "calico_not_with_dataplane_v2" {
  assert {
    condition     = !(var.network_policy && var.datapath_provider == "ADVANCED_DATAPATH")
    error_message = "network_policy enables the legacy Calico add-on, which is incompatible with ADVANCED_DATAPATH. Dataplane V2 enforces NetworkPolicy natively — set network_policy = false."
  }
}

check "control_plane_not_open_to_internet" {
  assert {
    condition     = !contains([for n in var.master_authorized_networks : n.cidr_block], "0.0.0.0/0")
    error_message = "master_authorized_networks contains 0.0.0.0/0 — the control plane IP endpoint is reachable from the whole internet. Acceptable only for a throwaway lab; prefer your /32 or enable_dns_endpoint."
  }
}

check "queued_provisioning_min_zero" {
  assert {
    condition     = !var.node_pool_queued_provisioning || var.min_node_count == 0
    error_message = "When node_pool_queued_provisioning is true, min_node_count must be 0."
  }
}
