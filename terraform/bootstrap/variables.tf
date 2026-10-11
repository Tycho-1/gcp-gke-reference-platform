variable "project_id" {
  description = "GCP project ID where the Terraform state bucket is created."
  type        = string
}

variable "region" {
  description = "Region for the state bucket (GCP recommends same region as workloads)."
  type        = string
  default     = "europe-west4"
}

variable "bucket_name" {
  description = "GCS bucket name for Terraform remote state. Default: {project_id}-tfstate (GCP tutorial convention)."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Allow bucket deletion when non-empty. false for safety; true only for throwaway lab projects."
  type        = bool
  default     = false
}
