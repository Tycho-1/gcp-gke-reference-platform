# Platform Requirements — GCP GKE Reference

Base requirements for a **GKE reference platform**, aligned with container platform engineering practice for **high-traffic Kubernetes** workloads (media, SaaS, internal platform teams).

---

## Core platform components

| Component | Purpose | Status in this repo |
|-----------|---------|---------------------|
| **GKE cluster** | Managed Kubernetes; regional, private nodes | ✅ `modules/gke-foundation` |
| **VPC-native networking** | Alias IP ranges for pods/services | ✅ |
| **Cloud NAT** | Outbound from private nodes | ✅ |
| **Node pools + cluster autoscaler** | Scale nodes on scheduling pressure | ✅ min/max on pool |
| **Vertical Pod Autoscaling (VPA)** | GKE-managed VPA on cluster; per-workload CRs in Git | ✅ `enable_vertical_pod_autoscaling` (default on) |
| **Workload Identity** | Pods → GCP APIs without JSON keys | ✅ pool enabled in module; 📋 per-app IAM bindings (P1) |
| **Artifact Registry** | Container images | 📋 todo (TF + CI) |
| **Argo CD** | GitOps CD on cluster (alternative) | ✅ `examples/argocd-platform` |
| **Flux CD** | GitOps bootstrap + fleet repo | ✅ `environments/<env>/20-platform` |
| **Helm** | Package workloads | ✅ Argo install chart in `examples/argocd-platform`; apps/add-ons via **GitOps** fleet repo |
| **External Secrets Operator** | Secret Manager → K8s secrets | 📋 todo |
| **cert-manager** | TLS for ingress | 📋 todo |
| **Ingress / Gateway** | HTTP routing to apps | 📋 todo (nginx or GKE ingress) |
| **Cloud CDN + HTTP(S) LB** | Edge cache, TLS termination | 📋 todo |
| **CI quality gates** | fmt, validate, tflint, Trivy, kubeconform | ✅ `.github/workflows/ci.yml` |
| **GitLab CI** (or GHA) | Build image → deploy | 📋 `.gitlab-ci.yml` planned |
| **HPA + metrics** | Pod autoscaling demo | 📋 todo |
| **Monitoring / alerting** | Prometheus/GMP, alerts | 📋 todo |
| **Kyverno / policy** | Guardrails for many devs | 📋 todo |

---

## Infrastructure as Code

| Tool | Owns |
|------|------|
| **Terraform** | GCP project APIs, VPC, GKE, node pools, IAM, WI pool, LB/CDN foundation |
| **Helm** | Charts in fleet repo (`HelmRelease` / Argo); Argo CD **install** only in `examples/argocd-platform` Terraform |
| **GitOps (Argo or Flux)** | Cluster add-ons (ESO, cert-manager, ingress, Istio, …) + application workloads — fleet repo (primary); Argo CD bootstrap optional |

**Principle:** reusable **`modules/gke-foundation`** (GCP only); **environments/<env>/10-foundation** pins env opinions; **20-platform** bootstraps GitOps with separate state.

---

## Environments (target)

| Environment | Purpose |
|-------------|---------|
| **`dev`** | Spot nodes, 0–3 per zone, no deletion protection; Flux without NetworkPolicies |
| **`prod`** | On-demand, multi-zone, min 1 per zone, deletion protection, Flux NetworkPolicies |
| **`staging`** (future) | Folder copy of `prod` with its own CIDRs + state prefix |

One **folder per stage**, each split into `10-foundation` / `20-platform` roots ([ADR 0007](docs/adr/0007-lifecycle-environments-and-layers.md)).

---

## Security

| Topic | Practice |
|-------|----------|
| **Private nodes** | ✅ default in module |
| **Control plane access** | ✅ `master_authorized_networks` required (no default) + IAM-gated DNS endpoint |
| **Dataplane V2 / NetworkPolicy** | ✅ default `ADVANCED_DATAPATH`; 📋 NetworkPolicy examples |
| **Secrets** | Secret Manager + ESO; never in git |
| **RBAC** | Least privilege; no cluster-admin for CI |
| **Image trust** | Scan in CI; optional Binary Authorization |

---

## Operations

| Topic | Practice |
|-------|----------|
| **Remote state** | GCS via `bootstrap/`; one prefix per env × layer in each `backend.tf` |
| **Upgrades** | Release channel REGULAR + `kubernetes_version = "latest"`; control timing with maintenance windows/exclusions |
| **Backups** | Velero / GKE backup (future doc) |
| **Cost** | Small machine types; destroy lab clusters |

---

## Related

- [aws-eks-reference-platform](https://github.com/Tycho-1/aws-eks-reference-platform) — sister repo on AWS
