# Bucket comes from ../../backend.tfvars: terraform init -backend-config=../../backend.tfvars
terraform {
  backend "gcs" {
    prefix = "prod/10-foundation"
  }
}
