# 0007 — Lifecycle environments split into foundation and platform layers

- **Status:** Accepted
- **Date:** 2026-09-29

## Context

The first layout had one root per GitOps tool (`gke-argo`, `gke-flux`). That named environments
after *tools* instead of *lifecycle stages*, and each root both created the cluster and configured
Kubernetes providers from it, which forced a `-target=module.gke_foundation` first apply.
A single state also meant a Flux change planned against the VPC and cluster.

## Decision

- Environments are lifecycle stages: `terraform/environments/dev/` and `prod/`.
- Each environment has two roots with separate state:
  - `10-foundation`: calls `modules/gke-foundation`. Only `google` providers.
  - `20-platform`: Flux bootstrap. Finds the cluster with `data "google_container_cluster"` by
    name (not `terraform_remote_state`, so it has no read access to foundation state).
- Environment opinions (CIDRs, sizing, Spot, zones, deletion protection) are **literals** in
  `10-foundation/main.tf`. Variables exist only for per-user values (project, region, allowed CIDRs).
- `20-platform` connects via the IAM-gated DNS control-plane endpoint by default.
- Argo CD moves to `examples/argocd-platform`, an alternative platform layer.

## Consequences

- Every root is a single, normal `terraform apply`. Apply `10` → `20`; destroy in reverse.
- Smaller blast radius and faster plans: in-cluster changes never plan GCP infrastructure.
- `diff -r environments/dev environments/prod` shows every environment difference.
- The Flux HCL in `dev/20-platform` and `prod/20-platform` is duplicated, because the module
  contract keeps modules GCP-only. A `modules/flux-bootstrap` module is the fix if that rule is
  relaxed or a third environment is added.
- Adding `staging` is a folder copy plus new literals and non-overlapping CIDRs.
