# 0006 — Secure-by-default GKE settings

- **Status:** Accepted
- **Date:** 2026-09-29

## Context

Reference code gets copied. If the defaults are lab-grade (open control plane, legacy datapath,
posture off), those defaults end up in real projects. Security should be the default, with cost
or convenience trade-offs made explicitly in tfvars.

## Decision

| Setting | Default | Why |
|---------|---------|-----|
| Private nodes | on | No public IPs on nodes; egress via Cloud NAT |
| `master_authorized_networks` | **required**, no default; `check` warns on `0.0.0.0/0` | No accidental internet-wide API exposure |
| DNS-based control plane endpoint | on | IAM-authorized API access from anywhere, without widening IP allowlists |
| Dataplane V2 (`ADVANCED_DATAPATH`) | on | eBPF datapath, native NetworkPolicy enforcement + logging |
| Calico add-on (`network_policy`) | off; `check` rejects it with Dataplane V2 | Incompatible with Dataplane V2 |
| Workload Identity | on | Pods get GCP identity without JSON keys |
| Shielded nodes | on | Secure Boot + integrity monitoring |
| Security posture | `BASIC` | Workload configuration audit, no extra cost |
| Release channel + `kubernetes_version = "latest"` | `REGULAR` | Google manages patching; exact pins only set a floor and drift |
| Dedicated node service account | on (upstream module) | Least-privilege node identity instead of the Compute default SA |
| Managed Prometheus | on | Metrics path ready; billed only when scraping |
| Image streaming + gVNIC | on | Faster pod start, better network throughput |

Lab trade-offs stay explicit in `terraform.tfvars`: `spot`, single-zone `cluster_zones`,
`deletion_protection = false`.

## Consequences

- First apply requires the user to set their own CIDR — one extra line, deliberately.
- Changing `datapath_provider` on an existing cluster forces recreation.
- Not yet enabled by default (tracked in `todolist.md`): Binary Authorization (needs a policy),
  private-endpoint-only control plane (needs VPN/IAP), CMEK for etcd/secrets, `VULNERABILITY_ENTERPRISE`.
