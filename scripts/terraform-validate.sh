#!/usr/bin/env bash
# fmt check + validate for every Terraform root (bootstrap, each env layer, Argo example).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIRS=(
  "${ROOT}/terraform/bootstrap"
  "${ROOT}/terraform/environments/dev/10-foundation"
  "${ROOT}/terraform/environments/dev/20-platform"
  "${ROOT}/terraform/environments/prod/10-foundation"
  "${ROOT}/terraform/environments/prod/20-platform"
  "${ROOT}/examples/argocd-platform"
)

echo "==> terraform fmt -check"
terraform fmt -check -recursive "${ROOT}/terraform" "${ROOT}/examples"

for dir in "${TF_DIRS[@]}"; do
  echo "==> validate: ${dir#"${ROOT}/"}"
  (
    cd "${dir}"
    terraform init -backend=false -input=false >/dev/null
    terraform validate
  )
done

echo "OK"
