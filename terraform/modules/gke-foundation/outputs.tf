output "network_name" {
  description = "VPC network name (dedicated module VPC or Shared VPC network name)."
  value       = var.enable_shared_vpc ? var.shared_vpc_network_name : module.network[0].network_name
}

output "network_id" {
  description = "VPC network id (null when using Shared VPC)."
  value       = var.enable_shared_vpc ? null : module.network[0].network_id
}

output "subnet_name" {
  description = "GKE subnet name."
  value       = var.enable_shared_vpc ? var.shared_vpc_subnetwork_name : module.network[0].subnets_names[0]
}

output "subnets_ips" {
  description = "Subnet CIDRs (empty when using Shared VPC)."
  value       = var.enable_shared_vpc ? [] : module.network[0].subnets_ips
}

output "cluster_name" {
  description = "GKE cluster name."
  value       = module.gke.name
}

output "cluster_location" {
  description = "Cluster location (region for regional clusters)."
  value       = module.gke.location
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint (sensitive)."
  value       = module.gke.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64, sensitive)."
  value       = module.gke.ca_certificate
  sensitive   = true
}

output "configure_kubectl" {
  description = "Command to fetch credentials for kubectl."
  value       = "gcloud container clusters get-credentials ${module.gke.name} --region ${var.region} --project ${var.project_id}"
}

output "configure_kubectl_dns" {
  description = "Command to fetch credentials via the IAM-gated DNS endpoint (null when enable_dns_endpoint is false)."
  value       = var.enable_dns_endpoint ? "gcloud container clusters get-credentials ${module.gke.name} --region ${var.region} --project ${var.project_id} --dns-endpoint" : null
}

output "service_account" {
  description = "Email of the GKE node service account (if created by the module)."
  value       = module.gke.service_account
}

output "workload_identity_pool" {
  description = "Workload Identity pool ([project_id].svc.id.goog when identity_namespace is enabled)."
  value       = module.gke.identity_namespace
}

output "cloud_nat_name" {
  description = "Regional Cloud NAT resource name when enable_cloud_nat is true on a dedicated VPC."
  value       = local.create_cloud_nat ? google_compute_router_nat.gke[0].name : null
}

output "enable_shared_vpc" {
  description = "Whether the cluster uses Shared VPC."
  value       = var.enable_shared_vpc
}

output "datapath_provider" {
  description = "Configured GKE datapath provider."
  value       = var.datapath_provider
}

output "vertical_pod_autoscaling_enabled" {
  description = "Whether GKE-managed Vertical Pod Autoscaling is enabled on the cluster."
  value       = module.gke.vertical_pod_autoscaling_enabled
}
