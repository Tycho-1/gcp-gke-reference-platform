output "cluster_name" {
  description = "GKE cluster name — input for ../20-platform."
  value       = module.gke_foundation.cluster_name
}

output "cluster_location" {
  value = module.gke_foundation.cluster_location
}

output "network_name" {
  value = module.gke_foundation.network_name
}

output "configure_kubectl" {
  value = module.gke_foundation.configure_kubectl
}

output "configure_kubectl_dns" {
  value = module.gke_foundation.configure_kubectl_dns
}

output "workload_identity_pool" {
  value = module.gke_foundation.workload_identity_pool
}

output "node_service_account" {
  value = module.gke_foundation.service_account
}
