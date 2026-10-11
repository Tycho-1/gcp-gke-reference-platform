check "flux_pat_required" {
  assert {
    condition     = !var.flux_token_auth || trimspace(var.github_token) != ""
    error_message = "flux_token_auth = true needs github_token (put it in terraform.tfvars.secrets)."
  }
}

check "flux_ssh_key_required" {
  assert {
    condition     = var.flux_token_auth || trimspace(var.github_ssh_private_key) != "" || trimspace(var.github_ssh_private_key_path) != ""
    error_message = "flux_token_auth = false needs github_ssh_private_key or github_ssh_private_key_path."
  }
}
