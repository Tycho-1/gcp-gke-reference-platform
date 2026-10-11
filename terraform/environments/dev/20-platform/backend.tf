# Bucket comes from ../../backend.tfvars: terraform init -backend-config=../../backend.tfvars
terraform {
  backend "gcs" {
    prefix = "dev/20-platform"
  }
}
