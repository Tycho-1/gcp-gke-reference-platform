# Bootstrap — GCS remote state bucket

Creates the **Cloud Storage bucket** used by all environment stacks for [Terraform remote state](https://cloud.google.com/docs/terraform/resource-management/managing-infrastructure-as-code).

This stack uses **local state** (no backend) — run once per GCP project.

## Usage

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars   # set project_id
terraform init
terraform plan
terraform apply
```

Note the output `bucket_name`, then configure the shared backend file (each layer sets its own prefix):

```bash
cd ../environments
cp backend.tfvars.example backend.tfvars   # bucket = <bucket_name>
cd dev/10-foundation && terraform init -backend-config=../../backend.tfvars
```

## GCP alignment

- Bucket naming: `{project_id}-tfstate` ([GCP IaC tutorial](https://cloud.google.com/docs/terraform/resource-management/managing-infrastructure-as-code))
- **Versioning** enabled
- **Uniform bucket-level access**
- Lifecycle: keep last 5 object versions (adjust for prod)

## IAM

Your Terraform identity needs `roles/storage.objectAdmin` on the bucket (or project-level storage admin for lab).

CI service accounts: grant the same on this bucket only.
