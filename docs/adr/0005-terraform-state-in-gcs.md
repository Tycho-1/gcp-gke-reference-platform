# 0005 — Terraform state in versioned GCS

- **Status:** Accepted
- **Date:** 2026-09-29

## Context

State contains resource IDs and, for the Kubernetes/Flux stacks, credentials (Git tokens, Argo repo
secrets). Local state is easy to lose and cannot be shared or locked across machines/CI.

## Decision

- `terraform/bootstrap/` creates one GCS bucket per project (`<project>-tfstate`) with uniform
  bucket-level access, public access prevention, and object versioning (last 5 versions kept).
- Each environment × layer root uses its own state **prefix** (`dev/10-foundation`,
  `prod/20-platform`, …), hard-coded in its `backend.tf` so two roots can never share state.
  Only the bucket name comes from `-backend-config`. GCS provides native state locking.
- For a separate prod project, use a separate bucket (`backend.prod.tfvars`).

## Consequences

- Recoverable state history and safe concurrent use.
- The bootstrap stack itself uses local state (chicken-and-egg); it is tiny and re-importable.
- Because state can hold secrets, bucket access must be limited to the Terraform identity.
  Next steps: CMEK on the bucket and Workload Identity Federation for CI so no long-lived keys exist.
