# prod / 20-platform

Bootstraps **Flux** into the `prod` cluster and points it at your fleet repo. Same code as [dev](../../dev/20-platform/); after this, platform add-ons and apps are managed from Git.

Flux commits its manifests to `clusters/platform-ref-gke-prod/` in the fleet repo. Changes reach prod by promoting them in Git (dev folder first, then prod), not by re-running Terraform.

**Requires:** [`../10-foundation`](../10-foundation/) applied, and the fleet repo containing `clusters/platform-ref-gke-prod/`.

## Differences from dev

| | dev | prod |
|--|--|--|
| `cluster_name` default | `platform-ref-gke-dev` | `platform-ref-gke-prod` |
| `flux_network_policy` default | `false` | `true` (Flux controllers only accept required traffic) |
| `ENVIRONMENT` in ConfigMap | `dev` | `prod` |
| State prefix | `dev/20-platform` | `prod/20-platform` |

For how it reaches the cluster, inputs and secrets, see the [dev README](../../dev/20-platform/README.md). They are the same.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
cp terraform.tfvars.secrets.example terraform.tfvars.secrets   # prefer a deploy key scoped to the fleet repo
terraform init -backend-config=../../backend.tfvars            # or backend.prod.tfvars
terraform plan -var-file=terraform.tfvars.secrets -out=tfplan && terraform apply tfplan
flux check && flux get kustomizations
```

**Destroy** this layer before `10-foundation`.
