# GCP GKE Reference Platform — Claude Code

Same map as [AGENTS.md](AGENTS.md). Read that file first.

**Quick start:** `terraform/bootstrap` apply once → `cp terraform/environments/backend.tfvars.example terraform/environments/backend.tfvars` → `dev/10-foundation`: `terraform init -backend-config=../../backend.tfvars && terraform apply` → push `examples/flux-fleet-sample/` → `dev/20-platform`: same init, `terraform apply -var-file=terraform.tfvars.secrets`. Full guide: [terraform/environments/README.md](terraform/environments/README.md).

**Argo CD instead of Flux:** apply `examples/argocd-platform/` instead of `20-platform`.

**Docs:** [README.md](README.md) · [terraform/ARCHITECTURE.md](terraform/ARCHITECTURE.md) · [docs/adr/](docs/adr/)

**Priority:** see [todolist.md](todolist.md) P0 (git init, apply + screenshot, GitHub push).
