# GCP GKE Reference Platform — agent map

Cursor agent entry point. **Independent portfolio repo** (sister to `aws-eks-reference-platform`) — not tied to any employer.

**Owner:** Tihomir Nikolov · **GitHub target:** `Tycho-1/gcp-gke-reference-platform`

---

## What this repo is

Terraform reference platform for **GKE on Google Cloud**:

- `terraform/modules/gke-foundation` — project APIs + VPC + NAT + regional private GKE (terraform-google-modules)
- `terraform/environments/{dev,prod}/10-foundation` — calls the module with env opinions as literals
- `terraform/environments/{dev,prod}/20-platform` — Flux `flux_bootstrap_git`; finds cluster via data source (separate state)
- `terraform/bootstrap/` — one-time GCS state bucket
- `examples/argocd-platform/` — alternative platform layer (Argo CD via Helm)
- `examples/` — `flux-fleet-sample/` (primary), `gitops-argocd-sample/`, `gitops-flux-sample/` (legacy)

**Read first:** [`README.md`](README.md) · [`terraform/ARCHITECTURE.md`](terraform/ARCHITECTURE.md) · [`todolist.md`](todolist.md)

---

## Commands

| Command | Purpose |
|---------|---------|
| `cd terraform/bootstrap && terraform init && terraform apply` | Create GCS state bucket (once per GCP project) |
| `cp terraform/environments/backend.tfvars.example terraform/environments/backend.tfvars` | Shared backend bucket (prefix is per layer in `backend.tf`) |
| `terraform init -backend-config=../../backend.tfvars` | Init any `environments/<env>/<layer>` root |
| `terraform apply` (in `<env>/10-foundation`) | VPC + GKE |
| `terraform apply -var-file=terraform.tfvars.secrets` (in `<env>/20-platform`) | Flux bootstrap (cluster must exist) |
| `terraform destroy` | Reverse order: `20-platform` then `10-foundation` — **always remind cost** |
| `bash scripts/terraform-validate.sh` | `fmt -check` + `validate` for every root |
| `tflint --init && tflint --recursive --config "$PWD/.tflint.hcl"` | Lint (recommended preset + Google ruleset) |
| `trivy config terraform --skip-dirs '**/.terraform' --ignorefile .trivyignore.yaml --severity HIGH,CRITICAL` | IaC misconfig scan (same as CI) |
| `pre-commit run -a` | All local hooks |

CI: `.github/workflows/ci.yml` — see [`.github/README.md`](.github/README.md) (fmt/validate, tflint, Trivy, kubeconform on every PR).

**Auth:** `gcloud auth application-default login` — see [`terraform/docs/gcp-authentication-for-terraform.md`](terraform/docs/gcp-authentication-for-terraform.md).

---

## Layout rules (do not break)

| Layer | Tool | Path |
|-------|------|------|
| **Foundation** | Terraform (`google`) | `terraform/modules/`, `environments/<env>/10-foundation` |
| **Platform bootstrap** | `fluxcd/flux` + `kubernetes` | `environments/<env>/20-platform` only |
| **Argo alternative** | Helm provider | `examples/argocd-platform/` only |
| **App / K8s add-ons** | Helm / manifests / GitOps | **fleet repo** — **not** in this Terraform monorepo |
| **State** | GCS | `bootstrap/` bucket; one prefix per env × layer (hard-coded in each `backend.tf`) |

**Environments = lifecycle stages** (`dev`, `prod`). Env opinions are literals in `10-foundation/main.tf`; variables only for per-user values. Layers don't read each other's state.

**One GitOps tool per cluster** — never apply `examples/argocd-platform` and `20-platform` to the same cluster.

**Module contract:** `modules/gke-foundation` = GCP only (no Helm/Kubernetes/Flux providers inside the module).

**GCP alignment:** [`terraform/README.md`](terraform/README.md) — HashiCorp + Google Cloud Terraform guidance.

---

## Conventions

- Match existing style: terraform-google-modules pins, `europe-west4` default region, dev/prod parity (change both when changing one).
- Minimize scope — focused diffs; no unrelated refactors.
- No secrets in git — use `*.example` files + gitignored `terraform.tfvars`, `terraform.tfvars.secrets`, `backend.tfvars`.
- Document decisions in `ARCHITECTURE.md` or env README when non-obvious.
- **Karpenter:** not used on GKE — cluster autoscaler + node pool min/max.
- **Secure by default:** security settings stay on in every tier ([ADR 0006](docs/adr/0006-secure-by-default-gke.md)); only cost/lifecycle knobs (`spot`, zones, `deletion_protection`) differ. `master_authorized_networks` has no default — never add `0.0.0.0/0` back as one.
- **Decisions:** non-obvious choices get an ADR in `docs/adr/`.

---

## Priority (from `todolist.md`)

1. **P0:** `git init`, push GitHub, one successful `apply` + screenshot, portfolio card
2. **P1:** Artifact Registry in TF, Workload Identity, optional rename env → `dev`
3. **P2:** ESO, cert-manager, demo Helm chart, HPA + load test
4. **P3:** `.gitlab-ci.yml` — Kaniko → AR → helm upgrade

---

## Sister repo

| | AWS | GCP (this repo) |
|--|-----|-----------------|
| Repo | [aws-eks-reference-platform](https://github.com/Tycho-1/aws-eks-reference-platform) | here |
| Node scale | Karpenter | Cluster autoscaler |
| GitOps | Flux (`cilium-karpenter` env) | **Flux** (`<env>/20-platform`) or **Argo** (`examples/argocd-platform`) |

Keep portfolio narrative symmetric on tycho-1.github.io.

---

## What NOT to do

- Do not add employer-, client-, or job-application-specific content to this repo.
- Do not put application Deployments in Terraform long-term.
- Do not commit `terraform.tfstate`, `.terraform/`, or tfvars with real project IDs.
- Do not force-push `main` without user request.
- Do not leave GKE clusters running without noting cost.

---

## Cursor

Rules: `.cursor/rules/gke-platform.mdc`

---

## Claude Code

Entry point: [CLAUDE.md](CLAUDE.md) — same content as this file.
