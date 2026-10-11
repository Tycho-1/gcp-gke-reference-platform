# Flux fleet repo sample (GKE)

> **GitOps repo template — not applied from this monorepo.** Copy this folder into a **separate Git repository** (your fleet repo), push it, then point `flux_git_url` at that repo when you apply `terraform/environments/<env>/20-platform`. Terraform installs Flux and commits `flux-system/`; **you** own app and cluster YAML in Git. **Day-2** changes are `git push` → Flux reconciles — not `kubectl apply` from here.

A sample **fleet repository** for the Flux platform layer, `terraform/environments/<env>/20-platform`. Each cluster gets its own entry point under `clusters/<cluster-name>/`. Shared apps live under `apps/`. This is the same pattern as the sister EKS repo.

**Architecture:** [`../../terraform/ARCHITECTURE.md`](../../terraform/ARCHITECTURE.md) · **Environments:** [`../../terraform/environments/README.md`](../../terraform/environments/README.md)

## Layout

```text
clusters/
  platform-ref-gke-dev/
    kustomization.yaml        # cluster entrypoint (commit before bootstrap)
    flux-system/              # created by flux_bootstrap_git (do not hand-edit)
  platform-ref-gke-prod/
    kustomization.yaml
apps/sample-app/
  kustomization.yaml
  namespace.yaml
  deployment.yaml
  service.yaml
```

The folder names match the cluster names that `10-foundation` produces (`platform-ref-gke-<env>`). `20-platform` bootstraps into `clusters/<cluster_name>` unless you set `flux_path`.

## Bootstrap workflow

1. **Create a GitHub repo** and push this folder as the repo root. Leave out `flux-system/`; it doesn't exist yet.
2. **Git credentials:** a fine-grained PAT with Contents read/write on this repo only, or an SSH deploy key with write access.
3. **Apply the platform layer** once the cluster exists (`10-foundation` applied):

   ```bash
   cd terraform/environments/dev/20-platform
   cp terraform.tfvars.example terraform.tfvars                 # flux_git_url = this repo
   cp terraform.tfvars.secrets.example terraform.tfvars.secrets # github_token or SSH key
   terraform init -backend-config=../../backend.tfvars
   terraform apply -var-file=terraform.tfvars.secrets
   ```

   Bootstrap installs the Flux controllers and commits `flux-system/` under `clusters/platform-ref-gke-dev/`.

4. **Add `flux-system` to the cluster kustomization** in one commit to the fleet repo:

   ```yaml
   # clusters/platform-ref-gke-dev/kustomization.yaml
   resources:
     - flux-system
     - ../../apps/sample-app
   ```

5. **Verify:**

   ```bash
   flux check --namespace flux-system
   flux get kustomizations
   kubectl get pods -n sample-app
   ```

## Promotion

Dev and prod read the same `apps/`. To promote a change separately, give each cluster its own overlay. For example, `apps/sample-app/overlays/{dev,prod}` with different image tags, referenced from `clusters/<cluster-name>/`. Alternatively, pin prod to a Git tag via `flux_branch` or a separate `GitRepository`.

Legacy app-only layout: [`../gitops-flux-sample/`](../gitops-flux-sample/) (superseded by this fleet sample).
