# GitHub automation

## Continuous integration

Workflow: [`workflows/ci.yml`](workflows/ci.yml)

**Triggers:** pull requests, pushes to `main`, manual `workflow_dispatch`.

| Job | What it runs | Blocking? |
|-----|----------------|-------------|
| **terraform fmt + validate** | [`scripts/terraform-validate.sh`](../scripts/terraform-validate.sh) — `fmt -check` on `terraform/` + `examples/`, then `init -backend=false` + `validate` on every Terraform root | yes |
| **tflint** | `tflint --recursive` with [`.tflint.hcl`](../.tflint.hcl) (recommended preset + Google ruleset) | yes |
| **trivy** | `trivy config terraform` (HIGH/CRITICAL, `.trivyignore.yaml`); example manifests report-only; `trivy fs` secret scan | yes (misconfig + secrets) |
| **kubeconform** | Strict validation of YAML under `examples/flux-fleet-sample`, `gitops-argocd-sample`, `gitops-flux-sample` | yes |

Terraform **plan/apply** is not run in CI (no GCP credentials in GHA by default). See P3 in [`todolist.md`](../todolist.md) for optional WIF + plan on PR.

### Run the same checks locally

```bash
bash scripts/terraform-validate.sh
tflint --init && tflint --recursive --config "$PWD/.tflint.hcl"
trivy config terraform --skip-dirs '**/.terraform' --ignorefile .trivyignore.yaml --severity HIGH,CRITICAL
pre-commit run -a    # fmt, validate, tflint hooks + generic file checks
```

Pin versions: workflow `env` block (`TFLINT_VERSION`, `TRIVY_VERSION`, `KUBECONFORM_VERSION`) and `hashicorp/setup-terraform` (`~1.16`).

## Dependabot

[`dependabot.yml`](dependabot.yml) — weekly updates for **GitHub Actions** and **Terraform** provider/module lockfiles in all roots listed there.
