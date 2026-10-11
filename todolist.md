# Todo — GCP GKE Reference Platform

Aligned with [`platform-requirements.md`](platform-requirements.md). Priority order for portfolio + depth.

---

## P0 — Publishable foundation (done / in progress)

- [x] Generalize Terraform from a private lab into this repo
- [x] Root README, platform-requirements, todolist
- [x] LICENSE, CI (fmt / validate / tflint / Trivy / kubeconform), pre-commit, Dependabot
- [x] Secure-by-default GKE (Dataplane V2, security posture, DNS endpoint, required APIs)
- [x] ADRs in `docs/adr/`
- [ ] `git init` + push to **Tycho-1/gcp-gke-reference-platform** on GitHub
- [ ] Portfolio card on [tycho-1.github.io](https://tycho-1.github.io)
- [x] Verify `terraform apply` on the old `gke-flux` root — cluster + Flux bootstrap + sample app sync **2026-09-22**
- [x] Re-verify on `dev/10-foundation` + `dev/20-platform` (after secure defaults + layer split) — **2026-10-08**
- [ ] Screenshot / short demo note in README (optional)
- [x] Verify `terraform destroy` in reverse (`20` then `10`) — **2026-10-08**
- [ ] Clean re-apply regression on empty project (optional)

---

## P1 — Terraform hardening

- [x] **GCS remote state** — `terraform/bootstrap/` + `backend.tf` per env
- [x] **Lifecycle envs** `dev` / `prod`, split into `10-foundation` / `20-platform` (separate state, no `-target`) — [ADR 0007](docs/adr/0007-lifecycle-environments-and-layers.md)
- [ ] Module version pinning via git tags (`?ref=vX.Y.Z`) for prod
- [ ] **Workload Identity** bindings in module (ESO, demo app)
- [ ] **Artifact Registry** repository in TF
- [ ] Optional third env `staging` (folder copy of `prod`; consider `modules/flux-bootstrap` then)

---

## P2 — Kubernetes platform add-ons

- [ ] **External Secrets Operator** + Secret Manager demo
- [ ] **cert-manager** + sample Certificate
- [ ] **ingress-nginx** or GKE Ingress + demo app Helm chart
- [ ] **HPA** + `scripts/load-test.sh` (not in repo yet) + README results section
- [ ] Document **cluster autoscaler** behaviour (screenshot HPA → nodes)

---

## P3 — CI/CD (GitLab)

- [ ] **`.gitlab-ci.yml`** — build (Kaniko) → AR → `helm upgrade`
- [ ] Review env per branch (`review-$CI_COMMIT_REF_SLUG`)
- [ ] Doc: GitLab self-hosted ops vs GitLab.com for lab
- [ ] Keyless CI auth: Workload Identity Federation (GitHub OIDC → GCP) in `bootstrap/`
- [ ] `terraform plan` on PR + manual-approval `apply` workflow

---

## P4 — Edge & media-scale patterns

- [ ] **Cloud CDN + global HTTP(S) LB** module or doc + TF stub
- [ ] Cache headers note for app teams
- [ ] Compare with [[aws-eks-reference-platform]] edge story

---

## P5 — Security & governance

- [ ] **Kyverno** or Pod Security Standards doc
- [ ] Container image scan in **deploy** pipeline (IaC Trivy already in GHA CI)
- [ ] NetworkPolicy examples

---

## P6 — Observability

- [ ] Managed Prometheus or kube-prometheus-stack (light)
- [ ] Cloud Monitoring integration notes
- [ ] Alerting example

---

## Done

- [x] 2026-09-20 — Repo scaffold (generalized from a private lab)
- [x] 2026-09-21 — `gke-flux` env: Flux bootstrap, `flux-fleet-sample`, validate script updated
- [x] 2026-09-21 — `AGENTS.md` / `CLAUDE.md` / cursor rules synced with dual GitOps envs
- [x] 2026-09-22 — Rename `modules/gke-default` → `gke-foundation`, `environments/gke-default` → `gke-argo`, `module.gke_foundation`
- [x] 2026-09-22 — **End-to-end Flux test** on `gke-flux` (cluster + `flux_bootstrap_git` + fleet sample app)
- [x] 2026-09-29 — CI gates, secure defaults, ADRs; restructure into `dev`/`prod` × `10-foundation`/`20-platform`, Argo moved to `examples/argocd-platform`
- [x] 2026-10-08 — **Dev E2E** on layer split: apply/destroy `10`+`20`, Flux SSH bootstrap, fleet app (Bank of Anthos); docs sync for publish
