# Authenticating Terraform to GCP

Terraform’s **Google provider** uses **Application Default Credentials (ADC)**. How you populate ADC depends on whether you run Terraform on a **workstation** or in **CI / automation**.

**Applies to every root** in [`environments/`](../environments/) (`dev`/`prod` × `10-foundation`/`20-platform`) and [`examples/argocd-platform`](../../examples/argocd-platform/).

**Control plane IP allowlist** (`master_authorized_networks` in `10-foundation`) is separate from ADC/IAM: see [Master authorized networks](master-authorized-networks.md).

---

## 1. Local development (human user)

### Option A — Recommended: user login (no key file)

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud auth application-default login
```

`application-default login` writes credentials where the **Google client libraries** (and Terraform’s provider) expect them. After this, `terraform plan` / `apply` use **your user** for the Google API.

**Also install** **`gke-gcloud-auth-plugin`** (required for **`kubectl`** / **`gcloud container clusters get-credentials`** on modern GKE; Terraform uses ADC tokens for the Google/Kubernetes/Flux providers, but you still want this for local `kubectl`):

- **Install via `gcloud`** (when the SDK component manager is enabled):

  ```bash
  gcloud components install gke-gcloud-auth-plugin
  ```

- **Debian / Ubuntu `apt`** — if you see **`component manager is disabled`**, add [Google’s cloud-sdk apt repo](https://cloud.google.com/sdk/docs/install) and install:

  ```bash
  sudo apt-get install -y google-cloud-cli-gke-gcloud-auth-plugin
  ```

  Confirm: `which gke-gcloud-auth-plugin`

The **same** ADC backs **`data.google_client_config`** (access token) for Terraform’s **Kubernetes**, **Flux** (`20-platform`), and **Helm** (`examples/argocd-platform`) providers against GKE. **`kubectl`** still needs **`gke-gcloud-auth-plugin`** when using **`gcloud container clusters get-credentials`**.

### Option B — Service account key file (simple CI / legacy)

1. In GCP Console: **IAM & Admin → Service Accounts → Keys → Add key (JSON)**.  
2. **Do not commit** the JSON file.  
3. Point ADC at it for the shell session:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/sa-key.json"
export GOOGLE_CLOUD_PROJECT="YOUR_PROJECT_ID"
terraform plan
```

**Downside:** Long-lived keys; prefer **Workload Identity Federation** for GitHub Actions / GitLab CI when you can.

---

## 2. What permissions this repo needs

Rough minimum for **creating VPC + GKE** (dev project; tighten for prod):

- **Compute / VPC:** networks, subnets, routers, NAT, firewalls.
- **GKE:** cluster and node pool lifecycle — often **`roles/container.admin`** for bootstrap.
- **IAM:** node service account creation and project-level bindings (module default).
- **APIs enabled:** Kubernetes Engine, Compute, IAM, Service Usage, …

For **Helm / Kubernetes / Flux** providers after the cluster exists, the same identity must **call the cluster API** (e.g. **Kubernetes Engine Developer** or **Admin**, plus RBAC if using granular IAM).

**Flux Phase 2** additionally needs **Git write access** to your fleet repo (PAT or SSH) in `terraform.tfvars.secrets` — not GCP IAM; see [`environments/README.md`](../environments/README.md).

---

## 3. CI (GitHub Actions, GitLab, etc.) — sketch

- **Preferred:** [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines) — no JSON key in the repo.  
- **Quick path:** service account key as a **CI secret** + `GOOGLE_APPLICATION_CREDENTIALS` in the job.

State: use GCS backend — [`terraform-remote-state.md`](terraform-remote-state.md).

---

## 4. Verify before Terraform

```bash
gcloud auth application-default print-access-token   # should succeed
gcloud config get-value project
```

Then pick an environment:

```bash
cd terraform/environments/dev/10-foundation
terraform init -backend-config=../../backend.tfvars
terraform plan
```

---

## 5. Relation to providers in this repo

| Root | Providers | Cluster API auth in Terraform |
|------|-----------|------------------------------|
| **`<env>/10-foundation`** | `google`, `google-beta` (required by `terraform-google-modules/network`) | none (GCP APIs only) |
| **`<env>/20-platform`** | `google`, `kubernetes`, `flux` (HTTPS + SSH alias) | `data.google_client_config` token → **DNS endpoint** (IAM-gated) |
| **`examples/argocd-platform`** | `google`, `kubernetes`, `helm`, `kubectl`, `time` | Same pattern |

Credentials come from **ADC**, not from `terraform.tfvars`. Git credentials for Flux live in **`terraform.tfvars.secrets`** (gitignored).

With the DNS endpoint, the caller needs **`container.clusters.connect`** (included in `roles/container.developer` and `roles/container.admin`). No IP allowlist is needed, which is what makes CI runners work.

**Argo example only:** the `Application` CR uses **`kubectl_manifest`** (alekc/kubectl), because **`kubernetes_manifest`** needs the API during plan.

**Apply order:** `10-foundation` → `20-platform`, each a single `terraform apply`. Destroy in reverse.

---

## 6. Troubleshooting: `Error setting access_token` / `oauth2: "invalid_grant" "Bad Request"`

ADC refresh token missing, expired, or revoked — not a Terraform syntax error.

**Fix (user ADC):**

```bash
gcloud auth application-default revoke
gcloud auth application-default login
```

Then retry `terraform plan`.

**Also check:**

| Check | Why |
|--------|-----|
| **`echo $GOOGLE_APPLICATION_CREDENTIALS`** | Overrides ADC; stale key → `invalid_grant` |
| **`gcloud auth login` vs `application-default login`** | Terraform needs **`application-default login`** |
| **System clock** | Skew breaks OAuth |
| **Service account key** | Rotate if deleted |

---

## 7. `gcloud container clusters get-credentials` (for **kubectl**, not Terraform)

Terraform uses **`data.google_client_config`** (§5). **`kubectl`**, **`flux` CLI**, and ad-hoc **`helm`** use **kubeconfig** + **`gke-gcloud-auth-plugin`**.

**Requirements:** gcloud access to the project; **`gke-gcloud-auth-plugin`** installed; IAM to get cluster credentials.

**Examples** (adjust `project_id`, `region`, cluster name from `terraform output configure_kubectl`):

```bash
# DNS-based control-plane endpoint (IAM-gated; no authorized-networks entry needed)
gcloud container clusters get-credentials platform-ref-gke-dev \
  --region europe-west1 \
  --project <PROJECT_ID> \
  --dns-endpoint

# prod: platform-ref-gke-prod. Drop --dns-endpoint to use the IP endpoint (needs master_authorized_networks)
```

**Use for:** `kubectl get nodes`, `flux check`, port-forwards, manual YAML — **not** required for `terraform apply` (providers use ADC tokens).

After Phase 2 Flux bootstrap, install the [Flux CLI](https://fluxcd.io/flux/installation/) separately if you want `flux get kustomizations` locally.

---

## Further reading

- [Application Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials)  
- [Terraform Google provider authentication](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication)  
- [`../ARCHITECTURE.md`](../ARCHITECTURE.md) — module vs environment layout
