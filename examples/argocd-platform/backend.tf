# terraform init -backend-config=../../terraform/environments/backend.tfvars
# Own prefix — never apply this and environments/<env>/20-platform to the same cluster.
terraform {
  backend "gcs" {
    prefix = "dev/20-platform-argocd"
  }
}
