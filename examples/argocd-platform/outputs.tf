output "argocd_namespace" {
  description = "Namespace where Argo CD is installed (empty if install_argocd = false)."
  value       = var.install_argocd ? var.argocd_namespace : null
}

output "argocd_ui_port_forward" {
  description = "Example port-forward when server is ClusterIP."
  value       = var.install_argocd && var.argocd_server_service_type == "ClusterIP" ? "kubectl port-forward svc/argocd-server -n ${var.argocd_namespace} 8080:443" : null
}

output "argocd_initial_admin_secret" {
  description = "Read bootstrap admin password (chart stores it in a Secret)."
  value       = var.install_argocd ? "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo" : null
}

output "argocd_gitops_sample_enabled" {
  description = "True when an Application CR was applied to sync from argocd_gitops_repo_url."
  value       = local.argocd_gitops_enabled
}

output "argocd_gitops_sample_port_forward" {
  description = "After sync, hit the sample Service from your laptop (optional)."
  value       = local.argocd_gitops_enabled ? "kubectl port-forward -n ${var.argocd_gitops_destination_namespace} svc/sample-nginx 8081:80" : null
}

output "argocd_gitops_example_path" {
  description = "Copy this folder to your Git repo root (or subtree matching argocd_gitops_repo_path)."
  value       = "examples/gitops-argocd-sample/ (repo root)"
}
