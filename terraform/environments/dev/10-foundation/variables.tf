variable "project_id" {
  description = "GCP project ID for this environment."
  type        = string
}

variable "region" {
  description = "Region for the VPC and regional GKE cluster."
  type        = string
  default     = "europe-west1"
}

variable "master_authorized_networks" {
  description = "CIDRs allowed on the control plane IP endpoint (e.g. your /32). The DNS endpoint is IAM-gated and not affected."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
}

variable "cluster_zones" {
  description = "Node zones. Empty = up to 3 zones in the region (more HA, more nodes). One zone (e.g. [\"europe-west1-b\"]) = cheaper, faster create/destroy."
  type        = list(string)
  default     = []
}
