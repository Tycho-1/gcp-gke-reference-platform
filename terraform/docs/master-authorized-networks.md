# Master authorized networks (GKE control plane)

How `master_authorized_networks` works in this repo, how to set it for one person vs a company, and how it relates to the DNS endpoint.

**Set in:** `terraform/environments/<env>/10-foundation/terraform.tfvars` → module variable `master_authorized_networks`.

---

## What it is

GKE exposes a **Kubernetes API** (the control plane). When the cluster uses a **public** control plane endpoint (`enable_private_endpoint = false`, the dev default), Google still lets you restrict **which source IP addresses** may connect to that API on the **classic IP endpoint**.

`master_authorized_networks` is that **allowlist**: a list of CIDR blocks (with optional display names). Example:

```hcl
master_authorized_networks = [
  { cidr_block = "203.0.113.42/32", display_name = "alice-laptop" },
]
```

Only clients whose **public egress IP** falls in one of those ranges can reach the API on the **IP endpoint** path. Node traffic to the control plane is handled separately (nodes are always allowed).

This is **not**:

| You might think… | Actually |
|------------------|----------|
| Pod or service CIDR | Those are `pods_cidr` / `services_cidr` in `main.tf` |
| “An IP range GCP assigns me” | You supply **your** (or your office’s) **source** IPs |
| Rules for users hitting your app | Ingress / Load Balancer / Gateway are unrelated |
| A replacement for IAM | You still need valid GCP credentials to use the API |

---

## Is it good to have?

**Yes**, for any cluster with a **public** control plane endpoint. It is a standard **defense-in-depth** control:

- Shrinks who can even **attempt** to talk to the API from the internet.
- Complements **IAM** (who is allowed to act once connected).
- Expected in audits and CIS-style GKE guidance.

This repo does **not** default to open internet (`0.0.0.0/0`). A `check` in `modules/gke-foundation/validations.tf` **warns** if you use `0.0.0.0/0` (lab shortcut only). See [ADR 0006](../../docs/adr/0006-secure-by-default-gke.md).

**Stronger prod pattern:** `enable_private_endpoint = true` (API only on the VPC) **plus** authorized networks or private Google Access paths — often with VPN, Cloud Interconnect, or IAP bastion. That is a larger networking change than tfvars alone.

---

## Two ways to use `kubectl` / Terraform against the API

This module enables **`enable_dns_endpoint = true`** by default.

| Path | What restricts access |
|------|------------------------|
| **IP endpoint** (`gcloud … get-credentials` without `--dns-endpoint`) | `master_authorized_networks` (source IP) **and** IAM |
| **DNS endpoint** (`terraform output -raw configure_kubectl_dns` or `get-credentials --dns-endpoint`) | **IAM** (`container.clusters.connect`, etc.) — not the CIDR list |

So you can keep a **tight** IP allowlist (or even `[]`) and still administer the cluster from a laptop or CI using the **DNS endpoint**, as long as the identity has the right roles.

---

## Setup: single person (home lab, portfolio)

1. Find your current public IP:

   ```bash
   curl -s ifconfig.me
   ```

2. Put it in `terraform.tfvars` as a **/32** (one host):

   ```hcl
   master_authorized_networks = [
     { cidr_block = "85.123.45.67/32", display_name = "home" },
   ]
   ```

3. Prefer admin access via the DNS endpoint after apply:

   ```bash
   $(terraform output -raw configure_kubectl_dns)
   kubectl get nodes
   ```

**If your ISP changes your IP:** update the `/32` and run `terraform apply`, or rely on the DNS endpoint and use a minimal IP list.

**Throwaway test only:** `0.0.0.0/0` allows any source IP on the **IP endpoint** (still need GCP auth). Plan will warn; destroy the cluster when done.

**IP-only API, no extra public ranges:** `master_authorized_networks = []` — use the DNS endpoint for admin; the IP endpoint stays closed to arbitrary internet sources.

---

## Setup: company (team / prod)

Typical patterns:

| Pattern | `master_authorized_networks` | Notes |
|---------|------------------------------|--------|
| **Office or fixed egress** | One or more corporate CIDRs, e.g. `203.0.113.0/24` | Ask NetOps for “egress IP(s) used for internet” or VPN pool |
| **VPN** | VPN concentrator public range or internal range if using private endpoint | Same list in tfvars; names in `display_name` help ops |
| **CI runners** | Static egress IP of the runner `/32` | Or skip IP path: CI uses DNS endpoint + WIF service account |
| **Prod, stricter** | Tight CIDRs + `enable_private_endpoint = true` | Requires connectivity into the VPC (VPN / Interconnect / bastion) |

Example for office + CI:

```hcl
master_authorized_networks = [
  { cidr_block = "203.0.113.0/24", display_name = "office-egress" },
  { cidr_block = "198.51.100.10/32", display_name = "github-actions-egress" },
]
```

**Prod** in this repo uses the same variable in `prod/10-foundation/terraform.tfvars` — usually **no** `0.0.0.0/0`; use office/VPN CIDRs from your network team.

**Governance:** treat changes to this list like firewall changes (review, change ticket). They affect who can reach the API on the IP path, not application end users.

---

## Quick reference

| Value | IP endpoint | Typical use |
|-------|-------------|-------------|
| Your `/32` | Only that IP | Solo dev |
| Office `/24` | Site egress | Company |
| `[]` | No extra public IPs | DNS endpoint + IAM for admin |
| `0.0.0.0/0` | Whole internet (warned) | Short lab only |

**Does not block testing your app** — HTTP to Services, Ingress, or load balancers is separate from control plane access.

---

## Related

- [GCP authentication for Terraform](gcp-authentication-for-terraform.md) — ADC, DNS endpoint, `get-credentials`
- [Environments README](../environments/README.md) — where to set `terraform.tfvars`
- Module `validations.tf` — `control_plane_not_open_to_internet` check
