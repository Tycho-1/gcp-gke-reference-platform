# 0002 — GKE Standard (not Autopilot)

- **Status:** Accepted
- **Date:** 2026-09-29

## Context

GKE Autopilot is Google's recommended default for many teams: Google manages nodes, security
hardening is enforced, and billing is per pod request. GKE Standard exposes node pools, machine
types, and node-level configuration.

## Decision

Use **GKE Standard** with a regional control plane and explicitly managed node pools.

Reasons for this reference platform:

- Demonstrates node pool design (machine types, Spot, autoscaling bounds, multi-pool layouts),
  which is the part most platform teams still operate.
- Keeps parity with the sister EKS platform (managed node groups / Karpenter) for comparison.
- Allows workloads Autopilot restricts (privileged DaemonSets, some eBPF tooling, custom node config).

## Consequences

- We own node pool sizing and upgrade surge settings; mitigated by release channels,
  auto-repair/auto-upgrade, and maintenance windows.
- Security settings that Autopilot enforces must be set explicitly (see ADR 0006).
- For teams without node-level requirements, **Autopilot is the better default**; the module
  boundary (ADR 0001) means an Autopilot variant can be added without touching environments'
  GitOps layer.
