# Terraform (GCP / GKE)

| Path | Purpose |
|------|---------|
| `bootstrap/` | **Once per project:** GCS state bucket (versioning, lifecycle, public access prevention). |
| `modules/gke-foundation/` | Reusable, GCP-only module: project APIs, VPC, Cloud NAT, private regional GKE. [README](modules/gke-foundation/README.md) |
| `environments/<env>/10-foundation/` | Calls the module with that environment's opinions (CIDRs, sizing, Spot, deletion protection). |
| `environments/<env>/20-platform/` | Flux bootstrap into the fleet repo. Finds the cluster by name; separate state. |
| `environments/README.md` | **Start here:** layers, apply order, dev vs prod, adding an environment. |
| `docs/` | [Auth](docs/gcp-authentication-for-terraform.md) · [Master authorized networks](docs/master-authorized-networks.md) · [Remote state](docs/terraform-remote-state.md) · [Troubleshooting](docs/gke-troubleshooting.md) |

Deep dive: [ARCHITECTURE.md](ARCHITECTURE.md). Alternative platform layer (Argo CD): [`../examples/argocd-platform/`](../examples/argocd-platform/).

---

## Aligned with Google Cloud Terraform guidance

| GCP recommendation | This repo |
|--------------------|-----------|
| [General style and structure](https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure?hl=en) | Module layout, naming, variables/outputs, `examples/` READMEs, `terraform fmt` in CI |
| [Reusable modules; root modules per environment](https://cloud.google.com/docs/terraform/best-practices/root-modules) | `modules/gke-foundation/` + `environments/{dev,prod}/` |
| [Minimize resources per root / separate state per component](https://cloud.google.com/docs/terraform/best-practices/root-modules) | `10-foundation` and `20-platform` layers, one state each |
| [Don't use workspaces for environments](https://cloud.google.com/docs/terraform/best-practices/root-modules) | One folder (and state prefix) per environment × layer |
| [Store state in Cloud Storage](https://cloud.google.com/docs/terraform/resource-management/store-state) | `bootstrap/` bucket + `backend "gcs"` in every root |
| [Use Google-maintained modules](https://cloud.google.com/docs/terraform/blueprints/terraform-blueprints) | `network` **18.2.0** + `kubernetes-engine` private-cluster **45.0.0** |
| fmt / validate / lint in CI | [`../scripts/terraform-validate.sh`](../scripts/terraform-validate.sh), [`../.github/workflows/ci.yml`](../.github/workflows/ci.yml) |

**Out of scope for Terraform** (by design): application workloads and platform add-ons live in the GitOps fleet repo after bootstrap. **One GitOps tool per cluster.**
