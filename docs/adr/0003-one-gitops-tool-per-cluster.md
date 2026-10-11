# 0003 — One GitOps tool per cluster (Argo CD *or* Flux)

- **Status:** Accepted
- **Date:** 2026-09-29

## Context

Argo CD and Flux both reconcile Git into the cluster. Running both on one cluster creates two
sources of truth, ownership conflicts on the same resources, and double the CRDs to upgrade.

## Decision

- Each cluster runs exactly one GitOps controller.
- `environments/<env>/20-platform`: `flux_bootstrap_git`. Flux commits its own manifests to a
  fleet repo; after bootstrap, platform add-ons and apps live in Git (`clusters/<name>/`, `apps/`).
- `examples/argocd-platform`: alternative platform layer. Argo CD installed by Terraform (Helm),
  optional `Application` pointing at Git. Applied *instead of* `20-platform`, never alongside it.
- Flux is the primary path (end-to-end tested; mirrors the sister EKS repo).

## Consequences

- Both models are available against the same foundation without interference.
- Flux bootstrap keeps Terraform's role to "create the cluster and hand it to Git", which is the
  cleaner long-term split. Argo via Helm-in-Terraform is simpler to start but means Terraform owns
  an in-cluster release; the usual next step is letting Argo manage itself (app-of-apps).
