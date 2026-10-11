# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID where the VPC and GKE cluster are created."
  type        = string
}

variable "name" {
  description = "Name prefix for resources (cluster name is name-environment)."
  type        = string
}

variable "environment" {
  description = "Environment label (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "GCP region for the regional GKE cluster and subnet."
  type        = string
}

variable "tags" {
  description = "Optional resource labels merged into cluster and node pool labels. Keys must meet GCP rules (lowercase letters, numbers, underscores, dashes; start with a letter)."
  type        = map(string)
  default     = {}
}

variable "enable_apis" {
  description = "Enable the project APIs this module needs (Compute, Kubernetes Engine, IAM, …). Set false when APIs are managed centrally (e.g. project factory)."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# VPC (default VPC-native GKE networking)
# -----------------------------------------------------------------------------

variable "subnet_cidr" {
  description = "Primary CIDR for the GKE subnet (nodes)."
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary range name + CIDR for pods (must not overlap subnet or services)."
  type        = string
  default     = "10.4.0.0/14"
}

variable "services_cidr" {
  description = "Secondary range CIDR for ClusterIP services."
  type        = string
  default     = "10.8.0.0/20"
}

variable "subnet_private_access" {
  description = "Enable private Google access on the GKE subnet (recommended)."
  type        = bool
  default     = true
}

variable "enable_cloud_nat" {
  description = "Create a regional Cloud Router and Cloud NAT in this VPC. Recommended when enable_private_nodes is true so nodes and pods have reliable outbound internet (not only Private Google Access). Ignored when enable_shared_vpc is true (NAT is owned by the host VPC)."
  type        = bool
  default     = true
}

variable "enable_shared_vpc" {
  description = "Attach the cluster to an existing Shared VPC subnet in a host project instead of creating a dedicated VPC in project_id."
  type        = bool
  default     = false
}

variable "shared_vpc_host_project_id" {
  description = "Host project ID for Shared VPC (required when enable_shared_vpc is true)."
  type        = string
  default     = ""
}

variable "shared_vpc_network_name" {
  description = "VPC network name in the host project (required when enable_shared_vpc is true)."
  type        = string
  default     = ""
}

variable "shared_vpc_subnetwork_name" {
  description = "Subnet name in the host project; must have secondary ranges for pods and services (required when enable_shared_vpc is true)."
  type        = string
  default     = ""
}

variable "shared_vpc_pods_range_name" {
  description = "Secondary range name on the Shared VPC subnet used for pod IPs."
  type        = string
  default     = "ip-range-pods"
}

variable "shared_vpc_services_range_name" {
  description = "Secondary range name on the Shared VPC subnet used for ClusterIP services."
  type        = string
  default     = "ip-range-svc"
}

# -----------------------------------------------------------------------------
# GKE
# -----------------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Minimum control plane version. \"latest\" lets the release channel manage upgrades (recommended). An exact version (e.g. 1.36.4-gke.1391000) only sets a floor — the channel still auto-upgrades past it."
  type        = string
  default     = "latest"
}

variable "master_authorized_networks" {
  description = "CIDRs allowed to reach the control plane IP endpoint. Empty list = no external access to the IP endpoint (nodes are always allowed). Never use 0.0.0.0/0 outside a throwaway lab."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "enable_dns_endpoint" {
  description = "Enable the DNS-based control plane endpoint. Access is authorized by IAM (not source IP), so kubectl works from anywhere with `get-credentials --dns-endpoint` without widening master_authorized_networks."
  type        = bool
  default     = true
}

variable "release_channel" {
  description = "GKE release channel: UNSPECIFIED, RAPID, REGULAR, or STABLE."
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["UNSPECIFIED", "RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "release_channel must be UNSPECIFIED, RAPID, REGULAR, or STABLE."
  }
}

variable "cluster_zones" {
  description = "Zones where the node pool runs (passed to terraform-google-kubernetes-engine as `zones`). Empty = upstream picks up to 3 zones in `region` (more HA, slower create/destroy). Set one zone (e.g. [\"europe-west4-a\"]) for faster dev; control plane stays regional."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.cluster_zones) == 0 || alltrue([for z in var.cluster_zones : startswith(z, "${var.region}-")])
    error_message = "Each cluster_zones entry must be a zone in var.region (e.g. europe-west4-a when region is europe-west4)."
  }
}

variable "enable_private_nodes" {
  description = "Nodes have internal IPs only (standard secure setup)."
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "If true, control plane endpoint is private only. false = public API (typical for dev)."
  type        = bool
  default     = false
}

variable "add_cluster_firewall_rules" {
  description = "Pass-through to terraform-google-kubernetes-engine: extra GKE firewall rules (intra-cluster egress, master→webhooks). Helps when the VPC uses restrictive egress; matches many private-cluster blueprints."
  type        = bool
  default     = true
}

variable "master_ipv4_cidr_block" {
  description = "CIDR for the control plane (/28). Must not overlap VPC or secondary ranges."
  type        = string
  default     = "172.16.0.0/28"
}

variable "deletion_protection" {
  description = "When true, Terraform cannot delete the cluster."
  type        = bool
  default     = false
}

variable "datapath_provider" {
  description = "GKE datapath: ADVANCED_DATAPATH (Dataplane V2 / eBPF, native NetworkPolicy enforcement — recommended) or DATAPATH_PROVIDER_UNSPECIFIED (legacy kube-proxy path). Changing it recreates the cluster."
  type        = string
  default     = "ADVANCED_DATAPATH"

  validation {
    condition     = contains(["DATAPATH_PROVIDER_UNSPECIFIED", "ADVANCED_DATAPATH"], var.datapath_provider)
    error_message = "datapath_provider must be DATAPATH_PROVIDER_UNSPECIFIED or ADVANCED_DATAPATH."
  }
}

variable "network_policy" {
  description = "Enable the legacy Calico NetworkPolicy add-on. Only for DATAPATH_PROVIDER_UNSPECIFIED; Dataplane V2 enforces NetworkPolicy natively and must keep this false."
  type        = bool
  default     = false
}

variable "enable_cilium_clusterwide_network_policy" {
  description = "Enable Cilium clusterwide network policies (requires datapath_provider = ADVANCED_DATAPATH)."
  type        = bool
  default     = false
}

variable "identity_namespace" {
  description = "Workload Identity pool for the cluster. \"enabled\" sets [project_id].svc.id.goog (recommended)."
  type        = string
  default     = "enabled"
}

variable "enable_shielded_nodes" {
  description = "Enable Shielded GKE nodes (Secure Boot, integrity monitoring)."
  type        = bool
  default     = true
}

variable "security_posture_mode" {
  description = "GKE security posture mode: BASIC (workload configuration audit, no extra cost) or DISABLED."
  type        = string
  default     = "BASIC"

  validation {
    condition     = contains(["DISABLED", "BASIC"], var.security_posture_mode)
    error_message = "security_posture_mode must be DISABLED or BASIC."
  }
}

variable "security_posture_vulnerability_mode" {
  description = "Vulnerability scanning mode when security posture is enabled."
  type        = string
  default     = "VULNERABILITY_DISABLED"

  validation {
    condition     = contains(["VULNERABILITY_DISABLED", "VULNERABILITY_BASIC", "VULNERABILITY_ENTERPRISE"], var.security_posture_vulnerability_mode)
    error_message = "Invalid security_posture_vulnerability_mode."
  }
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization on the cluster (requires policy setup in the project)."
  type        = bool
  default     = false
}

variable "enable_vertical_pod_autoscaling" {
  description = "Enable GKE-managed Vertical Pod Autoscaling (VPA) on the cluster. Installs VPA components; workloads need VerticalPodAutoscaler CRs (GitOps) to adjust CPU/memory requests."
  type        = bool
  default     = true
}

variable "gateway_api_channel" {
  description = "Gateway API channel: CHANNEL_STANDARD, CHANNEL_DISABLED, or null to omit."
  type        = string
  default     = null
  nullable    = true
}

variable "monitoring_enable_managed_prometheus" {
  description = "Enable Google Cloud Managed Service for Prometheus managed collection. Billed per ingested sample; nothing is scraped until PodMonitoring resources exist."
  type        = bool
  default     = true
}

variable "maintenance_start_time" {
  description = "Daily or recurring maintenance window start (RFC3339 time, e.g. 05:00)."
  type        = string
  default     = "05:00"
}

variable "maintenance_end_time" {
  description = "Recurring maintenance window end time (RFC3339). Empty = use upstream default."
  type        = string
  default     = ""
}

variable "maintenance_recurrence" {
  description = "Maintenance recurrence in RFC5545 format. Empty = use upstream default."
  type        = string
  default     = ""
}

variable "maintenance_exclusions" {
  description = "Maintenance exclusions (name, start_time, end_time, exclusion_scope)."
  type = list(object({
    name            = string
    start_time      = string
    end_time        = string
    exclusion_scope = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Node pool (default pool — no Autopilot, no custom CNI)
# -----------------------------------------------------------------------------

variable "node_pool_name" {
  description = "Name of the primary node pool."
  type        = string
  default     = "default"
}

variable "machine_type" {
  description = "Machine type for nodes."
  type        = string
  default     = "e2-standard-4"
}

variable "min_node_count" {
  type    = number
  default = 1
}

variable "max_node_count" {
  type    = number
  default = 5
}

variable "initial_node_count" {
  description = "Per-zone initial count (regional cluster = 3 zones × this many nodes at create)."
  type        = number
  default     = 1
}

variable "disk_size_gb" {
  type    = number
  default = 100
}

variable "spot" {
  description = "Use Spot VMs for the default pool (cheaper, can be reclaimed; not for production)."
  type        = bool
  default     = false
}

variable "node_pool_queued_provisioning" {
  description = "When true, GKE may queue node creation until capacity exists instead of failing fast on GCE_STOCKOUT (see GCP Queued Provisioning for node pools)."
  type        = bool
  default     = false
}

variable "node_pools" {
  description = <<-EOT
    Optional list of node pool maps passed to terraform-google-modules/kubernetes-engine.
    When empty (default), a single pool is built from node_pool_name, machine_type,
    min_node_count, max_node_count, and the other scalar node variables.
    Each entry is merged onto those defaults — specify only keys you want to override
    (e.g. name, machine_type, min_count, max_count, spot).
  EOT
  type        = list(map(any))
  default     = []
}
