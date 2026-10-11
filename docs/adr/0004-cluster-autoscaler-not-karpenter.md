# 0004 — GKE cluster autoscaler, not Karpenter

- **Status:** Accepted
- **Date:** 2026-09-29

## Context

The sister EKS platform uses Karpenter for just-in-time node provisioning. Karpenter's GCP
provider is not a first-class, Google-supported option for GKE.

## Decision

Use the **built-in GKE cluster autoscaler** on managed node pools (`min_count` / `max_count`),
plus **GKE-managed VPA** at the cluster level. Pod-level scaling (HPA/VPA objects) is defined in Git.

## Consequences

- No extra controller to install, upgrade, or grant IAM to; scaling is supported by Google.
- Less flexible bin-packing than Karpenter; mitigated with multiple node pools (`node_pools`)
  and, if needed later, GKE node auto-provisioning (`cluster_autoscaling`), which is intentionally
  not exposed by the module yet.
