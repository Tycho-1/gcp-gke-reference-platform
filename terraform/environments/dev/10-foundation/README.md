# dev / 10-foundation

GCP infrastructure for the `dev` cluster: project APIs, VPC + secondary ranges, Cloud Router/NAT, private regional GKE and its node pool. It is one call to [`modules/gke-foundation`](../../../modules/gke-foundation/).

Only `google` providers. Nothing here talks to the Kubernetes API.

**Next layer:** [`../20-platform`](../20-platform/) (Flux), which finds this cluster by name.

## Dev opinions (literals in `main.tf`)

| Setting | Value |
|---------|-------|
| Cluster | `platform-ref-gke-dev`, release channel `REGULAR` |
| Nodes | `e2-standard-4`, **Spot**, 0–3 per zone, 50 GB disk |
| Zones | `var.cluster_zones` (`[]` = all zones in region; set one zone to save cost) |
| `deletion_protection` | `false` |
| CIDRs | subnet `10.0.0.0/20`, pods `10.4.0.0/14`, services `10.8.0.0/20`, master `172.16.0.0/28` |

Security settings (private nodes, Dataplane V2, Workload Identity, DNS endpoint, …) are the same as prod.

## Inputs (`terraform.tfvars`)

| Variable | Required | Notes |
|----------|----------|-------|
| `project_id` | yes | |
| `master_authorized_networks` | yes | Source IPs allowed on the **control plane IP endpoint** — see [master authorized networks](../../../docs/master-authorized-networks.md). Solo: your `/32`; company: office/VPN CIDRs; lab-only: `0.0.0.0/0` (plan warns). Admin via DNS endpoint does not require widening this list |
| `region` | no | Default `europe-west4` |
| `cluster_zones` | no | Default `[]` |

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=../../backend.tfvars   # state prefix: dev/10-foundation
terraform apply                                       # ~15–25 min
```

### Verify access (`kubectl`)

Use the **DNS endpoint** (IAM-gated) so your laptop does not need to be in `master_authorized_networks`:

```bash
$(terraform output -raw configure_kubectl_dns)
kubectl get nodes
```

Same thing explicitly (use `project_id` and `region` from your `terraform.tfvars`; cluster name is `platform-ref-gke-dev`):

```bash
gcloud container clusters get-credentials platform-ref-gke-dev \
  --region europe-west4 \
  --project YOUR_PROJECT_ID \
  --dns-endpoint
kubectl get nodes
```

If you have several GKE clusters in `~/.kube/config`, stay on the context for **this** cluster (`…_platform-ref-gke-dev`). An old context that points at the **control plane IP** (`https://34.x.x.x/…`) can time out when your IP is not on the authorized list.

**Quick test without GCS:** backends cannot be toggled with a Terraform variable, and `plan` has no `-backend=false` flag. With `backend "gcs"` in `backend.tf`, Terraform 1.16 still requires a configured backend (or removing that block) before `plan` works.

Local state for a throwaway test:

```bash
mv backend.tf backend.tf.gcs   # restore after: mv backend.tf.gcs backend.tf
rm -rf .terraform
terraform init
terraform apply
```

State stays in `terraform.tfstate` here (gitignored). `terraform init -backend=false` only skips backend setup during that init; it does not let you `plan` while `backend.tf` still declares GCS.

For anything you keep, use `terraform/bootstrap` plus `../../backend.tfvars` and a dedicated state bucket.

**Destroy** only after `20-platform` is destroyed. A running cluster costs roughly €3–8 per day.

## Outputs

`cluster_name` and `cluster_location` (inputs for `20-platform`), `configure_kubectl` / `configure_kubectl_dns`, `network_name`, `workload_identity_pool`, `node_service_account`.
