output "flux_bootstrap_path" {
  description = "Path in the fleet repo where Flux was bootstrapped."
  value       = local.flux_bootstrap_path
}

output "flux_check_command" {
  value = "flux check --namespace ${var.flux_namespace}"
}

output "kubernetes_api_host" {
  description = "Endpoint Terraform used (DNS endpoint when use_dns_endpoint = true)."
  value       = local.kubernetes_config.host
}
