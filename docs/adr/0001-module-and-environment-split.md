# 0001 — GCP-only foundation module + thin environment roots

- **Status:** Accepted
- **Date:** 2026-09-29

## Context

The same VPC + GKE baseline is needed by several stacks (Argo CD, Flux, future `staging`/`prod`).
Copying HCL per stack drifts quickly. Mixing Kubernetes/Helm providers into the same module as
GCP resources couples credentials, upgrade cadence, and blast radius.

## Decision

- `terraform/modules/gke-foundation` owns **only GCP resources**: project APIs, VPC, subnet +
  secondary ranges, Cloud Router/NAT, private regional GKE, node pools. No `helm`, `kubernetes`,
  or `flux` providers inside the module.
- `terraform/environments/<env>` are **root modules**: provider config, backend, tfvars, and the
  cluster add-on bootstrap (Argo CD Helm release *or* Flux bootstrap).
- Upstream building blocks are the Google-maintained `terraform-google-modules`, pinned to exact versions.

## Consequences

- Module is reusable and testable on its own; environments stay small.
- A root that configures Kubernetes providers from the cluster it creates needs a two-step
  first apply (`-target`). [ADR 0007](0007-lifecycle-environments-and-layers.md) removes this by
  splitting each environment into `10-foundation` and `20-platform` roots with separate state.
