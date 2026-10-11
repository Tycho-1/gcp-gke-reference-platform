# GKE troubleshooting (Terraform)

Operational issues seen while applying `terraform/environments/<env>/10-foundation`. Run commands from that layer's directory.

## “I only see the VPC, no GKE cluster”

The Terraform module **does** create both (`module.network` + `module.gke` under `gke-foundation`). If the console shows a VPC but **no cluster**, common causes:

1. **Wrong place in the console** — Clusters are under **Kubernetes Engine → Clusters**, not under **VPC network**. The VPC name is usually `{name}-{environment}` (e.g. `platform-ref-gke-dev`); the cluster has the **same name** in GKE.

2. **Wrong project or region** — The cluster is **regional** in `var.region` (e.g. `europe-west4`). Confirm the project and region selectors in the console match `terraform.tfvars`.

3. **Apply stopped or failed after the VPC** — GKE creation often takes **10–20+ minutes**. If `terraform apply` errored or was cancelled mid-way, you can have VPC in state without a finished cluster. Check the terminal output, then:

   ```bash
   terraform plan   # should propose creating cluster / node pool if missing
   ```

4. **Accidental `-target` on the VPC only** — Creating **only** the VPC happens if you targeted the **network submodule**, for example:

   ```bash
   # creates VPC only — do NOT use this unless you mean it
   terraform apply -target=module.gke_foundation.module.network
   ```

   `10-foundation` needs no `-target`; run a plain `terraform apply`.

5. **Confirm what Terraform thinks is deployed**

   ```bash
   terraform state list | grep -E 'gke_foundation|container_cluster|node_pool'
   gcloud container clusters list --project YOUR_PROJECT_ID --region YOUR_REGION
   ```

## Node pool: `RUNNING_WITH_ERROR`, slow delete, “InstanceGroupManager is unstable”

This is a **real operational risk** with GKE (Terraform is only **waiting on Google’s long-running operations** — the fix is usually **GCP networking or node choice**, not HCL syntax). Typical pattern:

1. **Create:** pool ends in **`RUNNING_WITH_ERROR`** → reconciliation failed (node SA / IAM, **private nodes without egress**, disk, quota, org policy, etc.). Use **GKE → cluster → Node pools →** status / events and **Operations** for the **exact** error string.
2. **Destroy:** delete can sit on **`Still destroying...`** for **many minutes**, then fail with **`InstanceGroupManager is unstable`** — the **Compute Engine MIG** behind the pool is still reconciling (often worse if the pool was already in an error state or **spot/preemptible** nodes are churning).
3. **Recovery:** if **VMs / cluster are already gone** in the console but Terraform is stuck, **`Ctrl+C`**, then remove the **gone** objects from state and finish cleanup:

   ```bash
   terraform state rm 'module.gke_foundation.module.gke.google_container_node_pool.pools["default"]'
   terraform state rm 'module.gke_foundation.module.gke.google_container_cluster.primary'
   terraform destroy
   ```

   Or **`terraform apply -refresh-only`** first if you deleted the cluster in the **UI** and want state to catch up.

**Why it matters:** you can lose **tens of minutes** on apply/destroy and end up with **state vs GCP drift** — treat **first successful node pool** as your **health check** before installing Argo or workloads.

### What this stack does to reduce those failures

| Topic | Behaviour |
|-------|-----------|
| **Private Google Access** | **`subnet_private_access`** (module default `true`) lets nodes without public IPs reach **Google APIs** (Artifact Registry, `*.googleapis.com`, etc.) over Google’s private path. |
| **Cloud NAT** | With **`enable_cloud_nat = true`** (default), the module creates a **Cloud Router + Cloud NAT** so nodes and pods get **SNAT for general internet egress** (anything that is *not* covered by Private Google Access alone). The GKE module **`depends_on`** NAT so the first nodes do not race a missing NAT. |
| **Extra GKE firewall rules** | **`add_cluster_firewall_rules = true`** (default) turns on the upstream **private-cluster** firewall helpers (intra-cluster egress, master→webhook paths). Useful if your org uses **restrictive VPC egress**; harmless on an open VPC. |
| **Spot VMs** | **`spot = true`** — cheap but **capacity-sensitive** and more **IGM churn** on create/destroy. Use **`spot = false`** for a stable first cluster; enable spot only when you accept that tradeoff. |

**Environment knobs** (module arguments in `<env>/10-foundation/main.tf`): `enable_cloud_nat`, `add_cluster_firewall_rules`, `spot`. **Module** reference: [`../modules/gke-foundation/README.md`](../modules/gke-foundation/README.md).

If NAT is **already provided** elsewhere for this VPC (shared router, hub-and-spoke), set **`enable_cloud_nat = false`** here to avoid redundant NAT.

### `GCE_STOCKOUT` / “zone does not have enough resources”

GCP sometimes cannot place your **`machine_type`** in **one or more zones**. Terraform then waits a long time and may error with **`GCE_STOCKOUT`** and **only some nodes registered** (e.g. 1 of 3 when the pool spans three zones). That is **transient capacity**, not NAT or Terraform misconfiguration.

**Mitigations:**

- **`cluster_zones = ["REGION-b"]`** (dev `terraform.tfvars`) — **single zone**, one MIG, fewer chances to hit an empty zone.
- **Smaller `machine_type`** (e.g. **`e2-standard-2`** or **`e2-medium`**) — often available when larger SKUs stock out.
- **`node_pool_queued_provisioning = true`** — GKE can **queue** VMs until capacity exists ([Queued provisioning](https://cloud.google.com/kubernetes-engine/docs/how-to/queued-provisioning)).
- **Retry later** or use **another region** if the area is saturated.

**If apply fails with `Error waiting for resuming GKE node pool`** (after stockout or Ctrl+C): the pool in GCP is often **half‑broken** (e.g. 1 of 3 nodes). Terraform keeps trying to **reconcile** that object and hits the same timeout. **Break the deadlock** by recreating the pool, then apply again with **`cluster_zones`** + smaller **`machine_type`** already set:

1. **Replace the pool in one step** (from `terraform/environments/dev/10-foundation`):

   ```bash
   terraform apply -replace='module.gke_foundation.module.gke.google_container_node_pool.pools["default"]'
   ```

2. **Or** delete the pool in GCP, then apply:

   ```bash
   gcloud container node-pools delete default \
     --cluster=platform-ref-gke-dev --region=europe-west4 --project=<PROJECT_ID> --quiet
   terraform apply
   ```

   (Adjust cluster name / region / project to match your environment.)

3. **Or** delete the **whole cluster** in the console and run **`terraform apply`** (cleanest if the cluster is unusable).

## How long should `apply` take?

**NAT and extra firewall rules** fix **connectivity / reconciliation failures**, not the **clock**. GKE still runs **long‑lived operations** (cluster + node pool). **~15–25 minutes** for a first apply is **common** on Google’s side.

**Terraform** prints `Still creating...` every **10 seconds** while the provider waits on the API — that is **polling**, not proof it is stuck.

**Fewer zones → usually shorter creates:** with **`cluster_zones = []`**, the upstream module can place nodes in **up to three zones** (more HA, more VMs). With **`cluster_zones = ["europe-west4-b"]`** (dev `terraform.tfvars`), the pool uses **one zone** — fewer instances to provision, often **noticeably faster** for dev. Use **multi‑zone** (`[]` or several zones) for production‑style resilience.

## Node pool sizing (min / max / autoscaler)

- **`min_node_count`** / **`max_node_count`** set the **allowed range** for the **managed node pool**. GKE’s **Cluster Autoscaler** scales **node count** between them when **min &lt; max**, mainly based on **unschedulable (Pending) pods**, not “high CPU” alone.
- **`min_node_count == max_node_count`** ⇒ **fixed** pool size. **`machine_type`** is not auto-changed—only the number of nodes moves.
- Details: [`../ARCHITECTURE.md`](../ARCHITECTURE.md) §4.3.

## Networking notes

- **VPC-native GKE** via secondary ranges: pods and services get Alias IP ranges from the subnet.
- **Private nodes** default to `true`; the control plane endpoint stays **public** unless `enable_private_endpoint = true`.
- **`master_authorized_networks`** controls who can reach the **IP** endpoint. It has no default — set your own `/32` (e.g. `curl -s ifconfig.me`). The **DNS endpoint** (`enable_dns_endpoint = true`) is gated by IAM instead; use `get-credentials --dns-endpoint`.
- **Egress:** **Private Google Access** (subnet) + **Cloud NAT** (optional but **default on** via `enable_cloud_nat`) — see the table under [Node pool: `RUNNING_WITH_ERROR`](#node-pool-running_with_error-slow-delete-instancegroupmanager-is-unstable) above.
