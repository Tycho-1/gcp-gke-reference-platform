variable "project_id" {
  description = "GCP project ID for this environment (use a separate project from dev)."
  type        = string
}

variable "region" {
  description = "Region for the VPC and regional GKE cluster."
  type        = string
  default     = "europe-west4"
}

variable "master_authorized_networks" {
  description = "CIDRs allowed on the control plane IP endpoint (office/VPN ranges). Empty = DNS endpoint (IAM) only."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
}
