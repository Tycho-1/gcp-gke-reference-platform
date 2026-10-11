# Terraform remote state (GCS)

**GCP guide:** [Store Terraform state in Cloud Storage](https://cloud.google.com/docs/terraform/resource-management/store-state) · **Decision:** [ADR 0005](../../docs/adr/0005-terraform-state-in-gcs.md)

---

## Why

| Local state | GCS backend |
|-------------|-------------|
| One machine only | Shared across team / CI |
| No locking | Native state locking |
| Easy to lose | Versioned bucket (last 5 versions kept) |

---

## Setup

### 1. Bootstrap the bucket (once per GCP project)

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars   # project_id
terraform init && terraform apply
terraform output backend_config_example
```

### 2. Shared backend config

```bash
cd ../environments
cp backend.tfvars.example backend.tfvars       # bucket = "<project_id>-tfstate"
```

Every layer's `backend.tf` hard-codes its own **prefix**. Only the bucket comes from `backend.tfvars`:

```bash
cd dev/10-foundation
terraform init -backend-config=../../backend.tfvars
```

---

## One state per environment × layer

| Root | State prefix |
|------|--------------|
| `environments/dev/10-foundation` | `dev/10-foundation` |
| `environments/dev/20-platform` | `dev/20-platform` |
| `environments/prod/10-foundation` | `prod/10-foundation` |
| `environments/prod/20-platform` | `prod/20-platform` |
| `examples/argocd-platform` | `dev/20-platform-argocd` |

Prefixes are in code, not in tfvars, so two roots can't point at the same state by accident.

**Prod in its own project** (recommended) has its own bucket. Bootstrap that project, then init prod roots with `-backend-config=../../backend.prod.tfvars` (gitignored like `backend.tfvars`).

**Layers don't read each other's state.** `20-platform` looks up the cluster with `data "google_container_cluster"` instead of `terraform_remote_state`. The platform identity therefore needs no read access to foundation state, and the layers stay loosely coupled.

---

## What's in each state

- **`10-foundation`:** ~20 GCP resources (6 project APIs, VPC, subnet, router, NAT, cluster, node pool, 2 firewall rules, node SA + IAM bindings), plus `data.*` / `random_*` entries.
- **`20-platform`:** `flux-system` namespace, `terraform-outputs` ConfigMap, `flux_bootstrap_git`. This state contains **Git credentials**, so treat the bucket as sensitive.

---

## Local state (quick experiment only)

Create a gitignored `backend_override.tf` in a root:

```hcl
terraform {
  backend "local" {}
}
```

Then `terraform init -reconfigure`. Remove the file and run `terraform init -migrate-state -backend-config=../../backend.tfvars` to move the state to GCS later.

---

## CI

```bash
terraform init -input=false -backend-config=../../backend.tfvars
terraform plan -input=false -out=tfplan
```

Give each environment's CI identity `roles/storage.objectAdmin` on that environment's bucket only. Prefer Workload Identity Federation over JSON keys (see [auth guide](gcp-authentication-for-terraform.md)).
