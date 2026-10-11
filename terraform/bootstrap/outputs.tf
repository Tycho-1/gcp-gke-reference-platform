output "bucket_name" {
  description = "GCS bucket for Terraform remote state."
  value       = google_storage_bucket.tfstate.name
}

output "backend_config_example" {
  description = "Contents for terraform/environments/backend.tfvars (each layer's backend.tf sets its own prefix)."
  value       = <<-EOT
    bucket = "${google_storage_bucket.tfstate.name}"
  EOT
}
