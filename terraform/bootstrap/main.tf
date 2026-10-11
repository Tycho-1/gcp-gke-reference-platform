locals {
  bucket_name = coalesce(var.bucket_name, "${var.project_id}-tfstate")
}

# One-time bootstrap: remote state bucket for all environments in this repo.
# Uses local state for this stack only (chicken-and-egg). See README.md.
resource "google_storage_bucket" "tfstate" {
  name     = local.bucket_name
  location = var.region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  force_destroy = var.force_destroy
}
