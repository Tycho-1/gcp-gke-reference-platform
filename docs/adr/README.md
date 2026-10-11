# Architecture Decision Records

Short records of decisions that shape this platform. Format: context → decision → consequences.
New ADRs get the next number; superseded ones stay, with status updated.

| # | Decision | Status |
|---|----------|--------|
| [0001](0001-module-and-environment-split.md) | GCP-only foundation module + thin environment roots | Accepted |
| [0002](0002-gke-standard-over-autopilot.md) | GKE Standard (not Autopilot) | Accepted |
| [0003](0003-one-gitops-tool-per-cluster.md) | One GitOps tool per cluster (Argo *or* Flux) | Accepted |
| [0004](0004-cluster-autoscaler-not-karpenter.md) | GKE cluster autoscaler, not Karpenter | Accepted |
| [0005](0005-terraform-state-in-gcs.md) | Terraform state in versioned GCS | Accepted |
| [0006](0006-secure-by-default-gke.md) | Secure-by-default GKE settings | Accepted |
| [0007](0007-lifecycle-environments-and-layers.md) | `dev`/`prod` environments split into foundation + platform layers | Accepted |
