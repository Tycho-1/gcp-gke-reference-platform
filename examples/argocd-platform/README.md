# Example: Argo CD platform layer

> **Terraform (day-1 platform), not the GitOps repo.** This root installs Argo CD on an existing cluster — same role as `environments/<env>/20-platform` for Flux. **App manifests** belong in a **separate Git repo**; use [`gitops-argocd-sample/`](../gitops-argocd-sample/) as the template and push there for **day-2** sync. The `helm/` folder here is only **Argo CD chart values** for this Terraform apply, not your application Helm charts.

Alternative to `terraform/environments/<env>/20-platform` (Flux). It installs **Argo CD** with Helm on a cluster that already exists, created by `terraform/environments/<env>/10-foundation`.

**Use one GitOps tool per cluster** ([ADR 0003](../../docs/adr/0003-one-gitops-tool-per-cluster.md)). Apply this root **or** the Flux `20-platform` layer, never both.

## Usage

```bash
# 1. Cluster exists (terraform/environments/dev/10-foundation applied)
cd examples/argocd-platform
cp terraform.tfvars.example terraform.tfvars      # project_id, region, cluster_name
terraform init -backend-config=../../terraform/environments/backend.tfvars
terraform apply
```

Terraform finds the cluster by name with `data "google_container_cluster"` and connects through the IAM-gated **DNS endpoint**. It doesn't need the cluster's state, a `-target` step, or your IP in `master_authorized_networks`.

## What it installs

| File | Purpose |
|------|---------|
| `argocd.tf` | Official `argo-cd` chart. Uses the pinned `argocd_chart_version` and [`helm/argocd-values.yaml`](helm/argocd-values.yaml) (TLS on, resource limits, Dex, notifications and exec off) |
| `argocd-gitops.tf` | Optional `Application`, applied with `alekc/kubectl`, pointing at `argocd_gitops_repo_url` with automated sync (prune + self-heal) |
| `argocd-gitops-repo-secret.tf` | Optional repository `Secret` (HTTPS PAT **or** SSH deploy key) for private repos |

**Commit to deploy:**
1. Copy [`../gitops-argocd-sample/`](../gitops-argocd-sample/) into a Git repo.
2. Set `argocd_gitops_repo_url`.
3. Apply.

After that, every `git push` syncs without the UI.

## Access

```bash
$(terraform -chdir=../../terraform/environments/dev/10-foundation output -raw configure_kubectl_dns)
kubectl port-forward svc/argocd-server -n argocd 8080:443   # https://localhost:8080
terraform output -raw argocd_initial_admin_secret | sh      # initial admin password
```

## Production notes

- **Access:** use Ingress or Gateway API with TLS and SSO (OIDC). Then set `argocd_admin_enabled = false`.
- **Repo credentials:** passing them as `TF_VAR_...` keeps them out of Git, but they still end up in Terraform state. Prefer External Secrets + Secret Manager.
- **Self-management:** the usual next step is letting Argo CD manage its own chart (app-of-apps), so Terraform only bootstraps it once.
- **More:** [`helm/README.md`](helm/README.md) (Argo CD chart values in this example root).
