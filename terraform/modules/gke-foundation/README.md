# Module: `gke-foundation`

Terraform module that creates a **dedicated VPC** and a **regional GKE private cluster** with **VPC-native (Alias IP)** pod/service ranges — the usual Google default path. **No custom CNI** (e.g. Cilium) and **no Karpenter-style** node provisioners; workers live in a **single managed node pool** with min/max size. (VPC is included as part of the standard GKE baseline, not a separate “networking-only” module.)

**Full platform architecture (diagrams, IP plan, security, comparisons):** [`../../ARCHITECTURE.md`](../../ARCHITECTURE.md)

**Callers:** [`environments/dev/10-foundation`](../../environments/dev/10-foundation/) · [`environments/prod/10-foundation`](../../environments/prod/10-foundation/)

**Callers must configure** `provider "google"` and `provider "google-beta"` in the root module (required by `terraform-google-modules/network`).

---

## What this module creates

| Layer | Resources (via upstream modules) |
|-------|----------------------------------|
| **Network** | VPC named `{name}-{environment}`, one **regional subnet** for nodes, **two secondary IP ranges** on that subnet (`ip-range-pods`, `ip-range-svc`) for VPC-native GKE. Optional **Cloud Router + Cloud NAT** (`enable_cloud_nat`, default `true`) for private-node **internet egress**. |
| **Kubernetes** | **Regional** GKE cluster (`private-cluster`), **private nodes**, optional **public** control plane endpoint, **Dataplane V2** optional (`ADVANCED_DATAPATH`), **NetworkPolicy**, **Workload Identity**, optional **Shared VPC**. |
| **Identity** | Cluster node **GCP service account** (created when `create_service_account` is left to upstream default `true` in submodule). |

**Upstream modules** ([`terraform-google-modules`](https://github.com/terraform-google-modules) — **Google-maintained**, on the HashiCorp Registry)

- [`terraform-google-modules/network/google`](https://registry.terraform.io/modules/terraform-google-modules/network/google) **18.2.0**  
- [`terraform-google-modules/kubernetes-engine/google//modules/private-cluster`](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/45.0.0/submodules/private-cluster) **45.0.0**

**Why use these inside our module instead of only `google_compute_network` / `google_container_cluster`?**

- They implement **recommended GCP + GKE patterns** (VPC-native secondary ranges, private cluster wiring, node pools, service accounts) with far less custom HCL.
- **Maintenance:** API and best-practice drift is handled upstream; you bump **version constraints** when you choose.
- **Our wrapper** (`gke-foundation`) narrows the surface to **your** inputs (naming, CIDRs, one pool) so environments stay small and consistent.

They are **not** the HashiCorp company writing them, but they are the **standard Google ecosystem modules** for Terraform on GCP—not arbitrary third-party code.

---

## Requirements

- Terraform `>= 1.5.0`
- Provider **`hashicorp/google`** `>= 7.39.0, < 8.0.0` (required by kubernetes-engine **45.0.0**; see `versions.tf`)
- GCP project with billing active (required APIs are enabled by the module unless `enable_apis = false`)
- The **root module** must configure the Google provider (`project`, `region`); this module does not declare a `provider` block.

---

## Usage

```hcl
provider "google" {
  project = var.project_id
  region  = var.region
}

module "gke" {
  source = "./modules/gke-foundation" # or your registry path

  project_id  = var.project_id
  name        = "myapp"
  environment = "dev"
  region      = "europe-west1"

  # Optional overrides — see variables.tf for full list
  # subnet_cidr     = "10.0.0.0/20"
  # pods_cidr       = "10.4.0.0/14"
  # services_cidr   = "10.8.0.0/20"
  # master_authorized_networks = [{ cidr_block = "203.0.113.0/24", display_name = "office" }]
}
```

After apply, use the **`configure_kubectl`** output:

```bash
gcloud container clusters get-credentials <cluster_name> --region <region> --project <project_id>
```

---

## Inputs (summary)

| Name | Description | Default |
|------|-------------|---------|
| `project_id` | GCP project ID | (required) |
| `name` | Resource prefix; cluster = `name-environment` | (required) |
| `environment` | Env segment in names | `"dev"` |
| `region` | Region for subnet + regional cluster | (required) |
| `tags` | Labels merged into cluster / pool metadata | `{}` |
| `subnet_cidr` | Node primary subnet CIDR | `10.0.0.0/20` |
| `pods_cidr` | Secondary range CIDR for pods | `10.4.0.0/14` |
| `services_cidr` | Secondary range CIDR for ClusterIP | `10.8.0.0/20` |
| `subnet_private_access` | Private Google Access on subnet | `true` |
| `enable_cloud_nat` | Regional Cloud Router + Cloud NAT (SNAT for private nodes / pods) | `true` |
| `add_cluster_firewall_rules` | Upstream GKE module: intra-cluster egress + master→webhook rules | `true` |
| `enable_apis` | Enable required project APIs (`google_project_service`) | `true` |
| `kubernetes_version` | Minimum version; `latest` = release channel manages upgrades | `"latest"` |
| `master_authorized_networks` | Source CIDRs allowed on the control plane **IP** endpoint (warns on `0.0.0.0/0`). Guide: [`../../docs/master-authorized-networks.md`](../../docs/master-authorized-networks.md) | `[]` |
| `enable_dns_endpoint` | IAM-gated DNS control plane endpoint | `true` |
| `datapath_provider` | `ADVANCED_DATAPATH` (Dataplane V2) or `DATAPATH_PROVIDER_UNSPECIFIED` (legacy) | `"ADVANCED_DATAPATH"` |
| `network_policy` | Legacy Calico add-on — keep `false` with Dataplane V2 | `false` |
| `enable_cilium_clusterwide_network_policy` | Cilium clusterwide policies (needs Dataplane V2) | `false` |
| `identity_namespace` | Workload Identity pool | `"enabled"` |
| `enable_shared_vpc` | Use host-project Shared VPC instead of dedicated VPC | `false` |
| `shared_vpc_*` | Host project, network, subnet, range names | empty / defaults |
| `enable_shielded_nodes` | Shielded GKE nodes | `true` |
| `security_posture_mode` | `DISABLED` or `BASIC` | `"BASIC"` |
| `monitoring_enable_managed_prometheus` | Managed Service for Prometheus collection | `true` |
| `enable_binary_authorization` | Binary Authorization | `false` |
| `enable_vertical_pod_autoscaling` | GKE-managed VPA (cluster components; per-workload CRs in Git) | `true` |
| `deletion_protection` | Block Terraform destroy | `false` |
| `node_pool_name` | Managed pool name | `default` |
| `node_pools` | Optional list of pool maps; `[]` = single pool from scalars above | `[]` |
| `machine_type` | Machine type | `e2-standard-4` |
| `min_node_count` / `max_node_count` / `initial_node_count` | Pool sizing | `1` / `5` / `1` |
| `disk_size_gb` | Boot disk per node | `100` |
| `spot` | Spot VMs | `false` |
| `node_pool_queued_provisioning` | GKE queued provisioning (optional; default off) | `false` |

Full definitions: **`variables.tf`**. Invalid input combinations fail at **`terraform plan`** via `validations.tf`.

### Environment tiers

Security-relevant defaults are the same in every tier; environments only relax cost and lifecycle knobs.

| Setting | dev (lab) | staging / prod |
|---------|-----------|----------------|
| `datapath_provider` | `ADVANCED_DATAPATH` | `ADVANCED_DATAPATH` |
| `master_authorized_networks` | your workstation `/32` | office / VPN CIDRs (or empty + DNS endpoint only) |
| `enable_private_endpoint` | `false` | often `true` |
| `deletion_protection` | `false` | `true` |
| `spot` | `true` (cost) | `false` |
| `cluster_zones` | one zone (fast create) | `[]` (multi-zone) |
| `enable_shared_vpc` | `false` | optional `true` |
| `security_posture_mode` | `BASIC` | `BASIC` (+ `VULNERABILITY_ENTERPRISE` if licensed) |

Per-app **Workload Identity IAM bindings** use the upstream [`workload-identity`](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/45.0.0/submodules/workload-identity) submodule in the **environment** layer.

### Node pool min/max and Cluster Autoscaler

- **`min_node_count`** and **`max_node_count`** define the **scaling range** for this **managed node pool** (via `terraform-google-modules/kubernetes-engine`). They behave as a **moving** range when autoscaling is active for the pool and **min &lt; max**.
- GKE’s **Cluster Autoscaler** (built in for autoscaling node pools — not a separate chart in this repo) **adds/removes nodes** between those limits, mainly when pods are **Pending** due to **insufficient schedulable CPU/memory** on existing nodes.
- If **`min_node_count == max_node_count`**, the pool is **fixed** at that size.
- Autoscaler does **not** change **`machine_type`**; it only changes **node count**. See **[`../../ARCHITECTURE.md`](../../ARCHITECTURE.md) §4.3** for the full picture.

### Vertical Pod Autoscaling (VPA)

When **`enable_vertical_pod_autoscaling = true`** (default), GKE enables **managed VPA** on the cluster (upstream `private-cluster` → `verticalPodAutoscaling.enabled`). GKE runs the VPA control plane components; this module does **not** install a separate VPA Helm chart.

| Layer | Scales | Enabled here? |
|-------|--------|----------------|
| **Cluster Autoscaler** | Node count (`min`/`max`) | ✅ always (autoscaling pool) |
| **HPA** | Pod replicas | 📋 fleet repo (P2) |
| **VPA** | Container CPU/memory **requests** | ✅ cluster flag; **`VerticalPodAutoscaler` CRs** per Deployment in Git |

VPA does **not** replace Cluster Autoscaler: if VPA raises requests and pods no longer fit, **pending pods** can still trigger **node scale-out**.

### Multiple node pools (optional)

**Default:** one pool built from `node_pool_name`, `machine_type`, `min_node_count`, `max_node_count`, `spot`, etc.

**Several pools:** set `node_pools` to a **non-empty** list. Each map is **merged** onto the same defaults (`locals.tf`). When `node_pools` is set, **only** those pools are created — include every pool you want (for example `system` and `apps`).

This repo’s **dev** and **prod** roots use a **single** pool today. The sketch below is an optional **prod** pattern (smaller stable pool + larger app pool); not applied in code until you need it.

**Example** — add to `environments/prod/10-foundation/main.tf` inside `module "gke_foundation"` (remove or ignore the scalar `machine_type` / `min_node_count` / `max_node_count` / `spot` lines if they would confuse readers; merges still use them as defaults for each pool unless overridden):

```hcl
  node_pools = [
    {
      name         = "system"
      machine_type = "e2-standard-2"
      min_count    = 1
      max_count    = 2
      spot         = false
    },
    {
      name         = "apps"
      machine_type = "e2-standard-8"
      min_count    = 1
      max_count    = 5
      spot         = false
      disk_size_gb = 100
    },
  ]
```

**After apply:** schedule workloads with **node labels** / **node selectors** or **taints/tolerations** in Git (for example `cloud.google.com/gke-nodepool: apps`). A second pool that nothing uses only adds cost.

### Private nodes, egress, and healthy node pools

**Private nodes** have **no external IP**. **Private Google Access** on the subnet (`subnet_private_access`, default `true`) is required for many **Google APIs** (containers, Artifact Registry, etc.) without the public internet.

It does **not** replace **general outbound internet**. For reliable egress (non-Google endpoints, some bootstrap paths, arbitrary workloads), this module defaults **`enable_cloud_nat = true`**, which creates **Cloud Router + Cloud NAT** with `source_subnetwork_ip_ranges_to_nat = ALL_SUBNETWORKS_ALL_IP_RANGES` on this VPC. The GKE submodule uses **`depends_on`** the NAT resource so creation order is safe.

**`add_cluster_firewall_rules`** (default `true`) enables the **terraform-google-kubernetes-engine** `private-cluster` firewall helpers. They matter most when the VPC enforces **default-deny egress**; on a minimal VPC they add explicit rules aligned with GKE blueprints.

**`spot`** VMs can contribute to **`RUNNING_WITH_ERROR`** or **unstable instance groups** when capacity is tight; prefer **`false`** until the cluster is proven healthy.

For operational symptoms and recovery (**`InstanceGroupManager is unstable`**, state cleanup), see **[`docs/gke-troubleshooting.md`](../../docs/gke-troubleshooting.md)**.

---

## Outputs

| Name | Description |
|------|-------------|
| `network_name` / `network_id` | VPC identifiers |
| `subnet_name` / `subnets_ips` | GKE subnet name and CIDRs |
| `cluster_name` / `cluster_location` | Cluster identity |
| `cluster_endpoint` | API URL (sensitive) |
| `cluster_ca_certificate` | CA cert, base64 (sensitive) |
| `configure_kubectl` | Ready-to-run `gcloud` command |
| `configure_kubectl_dns` | Same, via the IAM-gated DNS endpoint |
| `service_account` | Node service account email |
| `workload_identity_pool` | WI pool (`[project].svc.id.goog`) |
| `cloud_nat_name` | Cloud NAT name when created on dedicated VPC |
| `datapath_provider` | Configured datapath |

---

## Files in this module

| File | Role |
|------|------|
| `versions.tf` | Terraform + provider versions |
| `variables.tf` | Input variables |
| `locals.tf` | Shared locals (network vs Shared VPC wiring) |
| `validations.tf` | `check` blocks (Shared VPC inputs, Cilium, Calico vs Dataplane V2, open control plane) |
| `apis.tf` | Required project APIs |
| `network.tf` | VPC, subnet, secondary ranges; optional Cloud Router + Cloud NAT |
| `main.tf` | GKE `private-cluster` submodule |
| `outputs.tf` | Exported values |
| `README.md` | This document |

---

## Out of scope (by design)

- **Custom NAT topology** beyond the default **single-region Router + NAT** (e.g. multi-region, fixed NAT IPs, PSC-only egress) — extend `network.tf` or compose another module if you need that.
- Workload Identity bindings for Kubernetes service accounts
- Explicit **`cluster_autoscaling`** / node auto-provisioning **profiles** (separate from this pool’s min/max + built-in autoscaler — see §4.3 in `ARCHITECTURE.md`)
- **In-cluster apps** (Argo CD, ingress controllers, etc.) — these belong in a separate root with its own state, like [`environments/<env>/20-platform`](../../environments/dev/20-platform/) (Flux) or [`examples/argocd-platform`](../../../examples/argocd-platform/) (Argo CD). Keep that separation so this module stays infra-only.

Extend the module or compose additional modules as your platform grows.
