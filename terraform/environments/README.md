# Environments

Each **environment** (lifecycle stage) is a folder. Each environment is split into **layers**, and every layer is its own Terraform root with its own state:

```text
environments/
  backend.tfvars.example     # state bucket, shared by all layers (prefix is set per layer)
  dev/
    10-foundation/           # project APIs, VPC, Cloud NAT, private GKE  → module gke-foundation
    20-platform/             # Flux bootstrap into the fleet repo          → reads cluster by name
  prod/
    10-foundation/
    20-platform/
```

| | 10-foundation | 20-platform |
|--|--|--|
| Owns | GCP resources only | In-cluster bootstrap (Flux) |
| Providers | `google`, `google-beta` | `google` (data only), `kubernetes`, `flux` |
| State prefix | `<env>/10-foundation` | `<env>/20-platform` |
| Changes | Rarely; slow applies (cluster) | More often; fast applies |
| Depends on | Nothing | Cluster exists (`data "google_container_cluster"`) |

**Why layers?** The hard reason: Terraform configures providers *before* it creates resources, so a root can't reliably build the `kubernetes`/`flux` providers from a cluster it hasn't created yet. That forced `-target` on the first apply. With two roots, the cluster **already exists** when `20-platform` plans. The other benefits: a mistake in the GitOps bootstrap can't touch the VPC or cluster, each plan stays small, and the two layers can use different credentials. See [ADR 0007](../../docs/adr/0007-lifecycle-environments-and-layers.md).

**Why literals in `main.tf`?** An environment's opinions (CIDRs, sizing, Spot, deletion protection) are code-reviewed in `main.tf`. Only per-user values (`project_id`, `region`, your CIDR, Git URL, secrets) are variables. Comparing `dev/10-foundation/main.tf` with `prod/10-foundation/main.tf` shows exactly how the environments differ.

## dev vs prod

| | dev | prod |
|--|--|--|
| Cluster | `platform-ref-gke-dev` | `platform-ref-gke-prod` |
| Nodes | `e2-standard-4` Spot, 0–3 per zone | `e2-standard-4` on-demand, 1–5 per zone |
| Zones | variable (`[]` or one zone) | up to 3 zones |
| `deletion_protection` | `false` | `true` |
| CIDRs (subnet / pods / services / master) | `10.0.0.0/20` / `10.4.0.0/14` / `10.8.0.0/20` / `172.16.0.0/28` | `10.16.0.0/20` / `10.20.0.0/14` / `10.24.0.0/20` / `172.16.0.16/28` |
| Flux NetworkPolicies | off | on |
| GCP project | its own | its own (recommended; separate state bucket) |

Security settings are identical in both environments ([ADR 0006](../../docs/adr/0006-secure-by-default-gke.md)).

**`master_authorized_networks`:** allowlist for the control plane **IP** API (your office/home egress CIDRs). Not the same as pod/VPC CIDRs. How to set it for one person vs a company: [`../docs/master-authorized-networks.md`](../docs/master-authorized-networks.md).

## Apply order

```bash
# 0. Once per project: state bucket
cd terraform/bootstrap && cp terraform.tfvars.example terraform.tfvars && terraform init && terraform apply
cd ../environments && cp backend.tfvars.example backend.tfvars     # bucket = <bootstrap output bucket_name>

# 1. Foundation (~15–25 min for the cluster)
cd dev/10-foundation
cp terraform.tfvars.example terraform.tfvars                       # project_id, your /32
terraform init -backend-config=../../backend.tfvars
terraform apply
$(terraform output -raw configure_kubectl_dns) && kubectl get nodes

# 2. Platform: push examples/flux-fleet-sample/ to GitHub first
cd ../20-platform
cp terraform.tfvars.example terraform.tfvars                       # flux_git_url
cp terraform.tfvars.secrets.example terraform.tfvars.secrets       # github_token or SSH key
terraform init -backend-config=../../backend.tfvars
terraform apply -var-file=terraform.tfvars.secrets
flux check && flux get kustomizations
```

**Lab only — local state:** temporarily move `backend.tf` aside, `rm -rf .terraform`, then `terraform init` (see [dev/10-foundation/README.md](dev/10-foundation/README.md)). Not for shared or prod work.

**Destroy in reverse:** `20-platform`, then `10-foundation`. Prod has `deletion_protection = true`. To tear it down, set it to `false` and apply first.

**Argo CD instead of Flux:** apply [`examples/argocd-platform/`](../../examples/argocd-platform/) instead of `20-platform`. Don't apply both to one cluster.

## Adding an environment

1. Copy `dev/` to `staging/`.
2. Change `environment`, the CIDRs (no overlap if VPCs will ever peer), the sizing, and the `prefix` in both `backend.tf` files.
3. Add a matching `clusters/platform-ref-gke-staging/` folder in the fleet repo.
4. Add both new roots to `scripts/terraform-validate.sh` and `.github/dependabot.yml`.

## Troubleshooting

Node pool errors, `GCE_STOCKOUT`, slow creates, and a stuck destroy are covered in [`../docs/gke-troubleshooting.md`](../docs/gke-troubleshooting.md). For auth and `kubectl`, see [`../docs/gcp-authentication-for-terraform.md`](../docs/gcp-authentication-for-terraform.md).
