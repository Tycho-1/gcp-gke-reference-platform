# Helm values — Argo CD

| File | Purpose |
|------|---------|
| `argocd-values.yaml` | Opinionated defaults merged into the official **`argo-cd`** chart. |

**Terraform** loads this file in `argocd.tf` and applies a few **environment-specific** overrides via `set` (e.g. `server.service.type`, optional `global.domain`).

## Production-oriented next steps (not automated here)

1. **Ingress + TLS** — e.g. GKE Ingress or Gateway API + **cert-manager**; set `global.domain` to your hostname.
2. **SSO** — **OIDC** (`configs.cm.oidc.config`) or enable **Dex** with `dex.enabled: true` and real `dex.config`.
3. **Disable local admin** — set `configs.cm.admin.enabled: false` after SSO works; rotate/remove `argocd-initial-admin-secret`.
4. **Secrets** — store repo credentials in **External Secrets Operator** / **GCP Secret Manager**, not in Git.
5. **HA** — increase `controller.replicas`, `server.replicas`, use **redis-ha** subchart pattern from upstream docs for large fleets.
6. **NetworkPolicy** — set `global.networkPolicy.create: true` once you validate traffic paths.

Chart documentation: [Argo CD operator manual](https://argo-cd.readthedocs.io/) and [argo-helm](https://github.com/argoproj/argo-helm).
