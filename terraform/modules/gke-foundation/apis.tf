# -----------------------------------------------------------------------------
# Project APIs required by the VPC + GKE resources in this module.
# disable_on_destroy = false: other stacks in the same project may depend on them.
# -----------------------------------------------------------------------------

resource "google_project_service" "required" {
  for_each = var.enable_apis ? toset(local.project_apis) : toset([])

  project = var.project_id
  service = each.value

  disable_on_destroy         = false
  disable_dependent_services = false
}
