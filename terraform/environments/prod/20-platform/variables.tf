variable "project_id" {
  description = "GCP project ID (same as ../10-foundation)."
  type        = string
}

variable "region" {
  description = "Region of the regional cluster (same as ../10-foundation)."
  type        = string
  default     = "europe-west1"
}

variable "cluster_name" {
  description = "Cluster created by ../10-foundation (output cluster_name)."
  type        = string
  default     = "platform-ref-gke-prod"
}

variable "use_dns_endpoint" {
  description = "Reach the API via the IAM-gated DNS endpoint (true) or the IP endpoint, which requires the runner's IP in master_authorized_networks (false)."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Flux
# -----------------------------------------------------------------------------

variable "flux_git_url" {
  description = "Fleet repo URL (https://github.com/owner/repo.git or ssh://git@github.com/owner/repo.git). Must have at least one commit."
  type        = string
}

variable "flux_path" {
  description = "Path in the fleet repo for this cluster. Empty = clusters/<cluster_name>."
  type        = string
  default     = ""
}

variable "flux_branch" {
  type    = string
  default = "main"
}

variable "flux_namespace" {
  type    = string
  default = "flux-system"
}

variable "flux_version" {
  type    = string
  default = "v2.9.0"
}

variable "flux_interval" {
  description = "Reconciliation interval for the bootstrap Kustomization."
  type        = string
  default     = "1m0s"
}

variable "flux_network_policy" {
  description = "NetworkPolicies for Flux controllers."
  type        = bool
  default     = true
}

variable "flux_token_auth" {
  description = "true = PAT over HTTPS (github_token); false = SSH deploy key."
  type        = bool
  default     = true
}

variable "flux_git_username" {
  description = "Git username for PAT auth."
  type        = string
  default     = "git"
}

variable "github_token" {
  description = "GitHub PAT for bootstrap. terraform.tfvars.secrets only — never commit."
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_ssh_private_key" {
  description = "SSH deploy key content. terraform.tfvars.secrets only — never commit."
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_ssh_private_key_path" {
  description = "Path to an SSH deploy key file. Alternative to github_ssh_private_key."
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_ssh_private_key_passphrase" {
  description = "Passphrase for an encrypted SSH key. Empty for passwordless keys."
  type        = string
  default     = ""
  sensitive   = true
}
