# dev / 20-platform

Bootstraps **Flux** into the `dev` cluster and points it at your fleet repo. After this, platform add-ons and apps are managed from Git, not Terraform.

Creates: `flux-system` namespace, `terraform-outputs` ConfigMap (cluster name, region, project, env, for Flux variable substitution), and `flux_bootstrap_git`, which installs Flux and commits its manifests to `clusters/platform-ref-gke-dev/` in the fleet repo.

**Requires:** [`../10-foundation`](../10-foundation/) applied, and the fleet repo pushed (start from [`examples/flux-fleet-sample`](../../../../examples/flux-fleet-sample/)).

## How it reaches the cluster

`data "google_container_cluster"` looks the cluster up by `cluster_name`. This layer never reads foundation's state. The `kubernetes` and `flux` providers use your ADC token against the **DNS endpoint**, which is IAM-gated, so no IP allowlist is needed. Set `use_dns_endpoint = false` to use the IP endpoint + CA instead.

## Inputs

`terraform.tfvars`:

| Variable | Required | Notes |
|----------|----------|-------|
| `project_id` | yes | |
| `flux_git_url` | yes | e.g. `https://github.com/<you>/<fleet-repo>.git` |
| `region` | no | Must match foundation. Default `europe-west4` |
| `cluster_name` | no | Default `platform-ref-gke-dev` |
| `flux_token_auth` | no | `true` = PAT (default), `false` = SSH deploy key |
| `flux_path` | no | Default `clusters/<cluster_name>` |
| `flux_network_policy` | no | Default `false` in dev |

`terraform.tfvars.secrets` (gitignored): `github_token`, **or** `github_ssh_private_key_path` + passphrase. A plan-time check fails if the one matching `flux_token_auth` is missing.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
cp terraform.tfvars.secrets.example terraform.tfvars.secrets
terraform init -backend-config=../../backend.tfvars   # state prefix: dev/20-platform
terraform apply -var-file=terraform.tfvars.secrets
flux check && flux get kustomizations
```

**Destroy** this layer before `10-foundation`. Flux's commits stay in the fleet repo.

**Argo CD instead?** Use [`examples/argocd-platform`](../../../../examples/argocd-platform/) *instead of* this layer, never both on one cluster.
