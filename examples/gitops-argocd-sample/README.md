# Example GitOps repo for Argo CD (commit-to-deploy, no UI)

> **GitOps repo template — not applied from this monorepo.** Copy this folder into a **separate Git repository**, push it, then set `argocd_gitops_repo_url` (or equivalent) when you use [`argocd-platform/`](../argocd-platform/) or an `Application` CR. **Day-2** deploys are commits to **that** repo; Argo syncs to the cluster.

This folder is a **minimal layout you can push to GitHub** (or GitLab, etc.). **Argo CD** watches the Git URL you configure and syncs Kubernetes manifests—same *idea* as **Flux** (`GitRepository` + `Kustomization`), but Argo uses the **`Application`** CRD instead.

**Terraform root:** [`examples/argocd-platform/`](../argocd-platform/) · **Architecture:** [`terraform/ARCHITECTURE.md`](../../terraform/ARCHITECTURE.md)

## Flow

1. **Push this content** to a Git repository (keep the `apps/sample-app` path, or change it and match `argocd_gitops_repo_path` in Terraform).
2. **Register the Application** (one-time):
   - **Terraform** (recommended in this repo): set `argocd_gitops_repo_url` in `terraform.tfvars` and apply [`examples/argocd-platform`](../argocd-platform/) — see that README.
   - **Or** `kubectl apply -f bootstrap/application-sample.yaml` after replacing `repoURL` / `path` (if you skip Terraform bootstrap).
3. **Change manifests** (e.g. image tag, replicas) and **commit + push**. Argo CD **auto-syncs** (prune + self-heal) — no clicks in the Argo UI.

## Layout

```text
apps/sample-app/     # Synced by the Application’s spec.source.path
bootstrap/           # Optional manual Application manifest (template)
```

## Private repository (normal for production)

**Public GitOps repos** are only sane for **quick demos**—they expose how your cluster is shaped. In **production**, use a **private** repo and give Argo CD **read-only** access: **SSH deploy key** or **HTTPS + fine-scoped PAT**, as an Argo `Secret` with `argocd.argoproj.io/secret-type: repository` ([Argo docs](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#repositories)). The `examples/argocd-platform` Terraform can create that secret via `argocd_gitops_https_password` or `argocd_gitops_ssh_private_key`; prefer injecting credentials without storing them in Terraform state in real prod (External Secrets, Vault, or manual `kubectl`).

## Flux vs Argo (mental model)

| Flux | Argo CD |
|------|---------|
| `GitRepository` + `Kustomization` | `Application` with `spec.source` (Git) + path |
| Reconciles on interval / webhook | Same: poll + optional webhook |
| Declarative in cluster | Declarative `Application` CRs (often also stored in Git — “app of apps”) |

Both are **Git as source of truth**; you are not required to use the Argo CD UI after bootstrap.
