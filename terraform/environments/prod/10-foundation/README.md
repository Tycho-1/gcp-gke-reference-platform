# prod / 10-foundation

GCP infrastructure for the `prod` cluster: project APIs, VPC + secondary ranges, Cloud Router/NAT, private regional GKE and its node pool. It is one call to [`modules/gke-foundation`](../../../modules/gke-foundation/), the same module as [dev](../../dev/10-foundation/).

Only `google` providers. Nothing here talks to the Kubernetes API.

**Next layer:** [`../20-platform`](../20-platform/) (Flux), which finds this cluster by name.

## Prod opinions (literals in `main.tf`)

| Setting | Value | Differs from dev |
|---------|-------|------------------|
| Cluster | `platform-ref-gke-prod`, release channel `REGULAR` | name |
| Nodes | `e2-standard-4`, **on-demand**, 1–5 per zone, 100 GB disk (single pool `default`) | no Spot, min 1, larger |
| Zones | all zones in the region (`[]`) | not configurable |
| `deletion_protection` | `true` | ✓ |
| CIDRs | subnet `10.16.0.0/20`, pods `10.20.0.0/14`, services `10.24.0.0/20`, master `172.16.0.16/28` | no overlap with dev |

Security settings are identical to dev ([ADR 0006](../../../../docs/adr/0006-secure-by-default-gke.md)).

**Optional — two node pools** (different VM sizes for system vs apps): documented as an example only in [`../../../modules/gke-foundation/README.md`](../../../modules/gke-foundation/README.md#multiple-node-pools-optional). Not enabled in this root by default.

## Inputs (`terraform.tfvars`)

| Variable | Required | Notes |
|----------|----------|-------|
| `project_id` | yes | Use a separate prod project |
| `master_authorized_networks` | yes | Office/VPN ranges. Never `0.0.0.0/0` |
| `region` | no | Default `europe-west1` |

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=../../backend.tfvars   # state prefix: prod/10-foundation
                                                      # separate project? use backend.prod.tfvars
terraform plan -out=tfplan && terraform apply tfplan
```

### Verify access (`kubectl`)

```bash
$(terraform output -raw configure_kubectl_dns)
kubectl get nodes
```

Or explicitly (`project_id` / `region` from `terraform.tfvars`; cluster `platform-ref-gke-prod`):

```bash
gcloud container clusters get-credentials platform-ref-gke-prod \
  --region europe-west1 \
  --project YOUR_PROJECT_ID \
  --dns-endpoint
kubectl get nodes
```

**Destroy:** destroy `20-platform` first, then set `deletion_protection = false` and apply, then `terraform destroy`. Prod costs noticeably more than dev (on-demand nodes, min 3 across zones).

## Outputs

`cluster_name` and `cluster_location` (inputs for `20-platform`), `configure_kubectl` / `configure_kubectl_dns`, `network_name`, `workload_identity_pool`, `node_service_account`.
