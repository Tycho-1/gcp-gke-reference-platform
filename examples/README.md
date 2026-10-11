# Examples

Templates and alternate Terraform roots for this platform. **Nothing under `examples/` is synced to a cluster by itself.**

| Path | What it is | Applied how |
|------|------------|-------------|
| [`flux-fleet-sample/`](flux-fleet-sample/) | **GitOps repo template** (Flux fleet layout) | Copy → **your fleet Git repo** → push; Flux syncs after `20-platform` bootstrap |
| [`gitops-argocd-sample/`](gitops-argocd-sample/) | **GitOps repo template** (app manifests for Argo) | Copy → **your Git repo** → push; Argo `Application` syncs |
| [`gitops-flux-sample/`](gitops-flux-sample/) | Legacy app-only layout | Superseded by `flux-fleet-sample/` |
| [`argocd-platform/`](argocd-platform/) | **Terraform root** (Argo CD install) | `terraform apply` — same layer as `environments/<env>/20-platform`, not a fleet repo |

**Day-2 rule:** workloads and platform add-ons (apps, ingress, ESO, Helm charts) live in the **fleet / GitOps repository**, not in this monorepo.
