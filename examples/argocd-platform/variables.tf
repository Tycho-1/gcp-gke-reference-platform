variable "project_id" {
  description = "GCP project ID of the target cluster."
  type        = string
}

variable "region" {
  description = "Region of the regional cluster."
  type        = string
  default     = "europe-west4"
}

variable "cluster_name" {
  description = "Existing cluster created by an environment's 10-foundation layer."
  type        = string
  default     = "platform-ref-gke-dev"
}

variable "use_dns_endpoint" {
  description = "Reach the API via the IAM-gated DNS endpoint (true) or the IP endpoint + CA (false)."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Argo CD
# -----------------------------------------------------------------------------

variable "install_argocd" {
  description = "Install Argo CD via Helm (namespace + release managed by Terraform)."
  type        = bool
  default     = true
}

variable "argocd_namespace" {
  description = "Kubernetes namespace for Argo CD."
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "argo-cd Helm chart version (argo-helm repo). Bump via artifacthub.io/packages/helm/argo/argo-cd."
  type        = string
  default     = "9.4.11"
}

variable "argocd_server_service_type" {
  description = "Argo CD server Service type: ClusterIP (port-forward), LoadBalancer (public LB; dev only)."
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "LoadBalancer", "NodePort"], var.argocd_server_service_type)
    error_message = "Must be ClusterIP, LoadBalancer, or NodePort."
  }
}

variable "argocd_global_domain" {
  description = "Optional Argo CD global.domain (e.g. argocd.example.com). Leave empty when using port-forward or Ingress you manage separately."
  type        = string
  default     = ""
}

variable "argocd_admin_enabled" {
  description = "Enable local admin user + bootstrap secret. Set false after SSO is configured (prod)."
  type        = bool
  default     = true
}

variable "argocd_helm_wait" {
  description = "Wait for Kubernetes resources to become ready."
  type        = bool
  default     = true
}

variable "argocd_helm_timeout" {
  description = "Helm install/upgrade timeout (seconds); Argo CD can take several minutes on first install."
  type        = number
  default     = 900
}

variable "argocd_helm_atomic" {
  description = "If upgrade fails, roll back to the previous release."
  type        = bool
  default     = true
}

variable "argocd_helm_cleanup_on_fail" {
  description = "Allow deletion of new resources on failed install."
  type        = bool
  default     = true
}

variable "argocd_helm_max_history" {
  description = "Helm release history to retain."
  type        = number
  default     = 5
}

variable "argocd_helm_wait_for_jobs" {
  description = "Wait for Jobs (e.g. hooks) to complete. Set false if a chart hook hangs in your environment."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Argo CD — Git-driven sample app (no UI): push manifests to Git, Application CRD
# -----------------------------------------------------------------------------

variable "argocd_gitops_repo_url" {
  description = "HTTPS or SSH Git URL for the GitOps repo (e.g. https://github.com/org/prod-gitops.git). In production this is almost always a private repo — set argocd_gitops_https_password or argocd_gitops_ssh_private_key. Empty = skip kubectl_manifest Application."
  type        = string
  default     = ""
}

variable "argocd_gitops_target_revision" {
  description = "Branch, tag, or commit for Argo CD to track."
  type        = string
  default     = "HEAD"
}

variable "argocd_gitops_repo_path" {
  description = "Path inside the repo to the Kustomize root (directory with kustomization.yaml)."
  type        = string
  default     = "apps/sample-app"
}

variable "argocd_gitops_application_name" {
  description = "Name of the Argo CD Application resource in the argocd namespace."
  type        = string
  default     = "sample-app-gitops"
}

variable "argocd_gitops_destination_namespace" {
  description = "Target namespace for synced workloads (must match Kustomize namespace / manifests)."
  type        = string
  default     = "sample-app"
}

variable "argocd_gitops_crds_wait_seconds" {
  description = "Delay after Helm installs Argo CD before applying Application CRD (CRD registration)."
  type        = number
  default     = 45
}

# Argo CD discovers repo credentials from Secrets in the argocd namespace labeled
# argocd.argoproj.io/secret-type=repository (see Argo declarative repo setup).
# Public HTTPS repos need none of the following. Private: set either PAT or SSH, not both.

variable "argocd_gitops_https_username" {
  description = "For private HTTPS Git (e.g. GitHub): username for the repo Secret. GitHub PAT flows often use \"git\" or your GitHub username."
  type        = string
  default     = "git"
}

variable "argocd_gitops_https_password" {
  description = "For private HTTPS Git: token or PAT (stored in Kubernetes Secret; also in Terraform state unless you use env/remote secret injection). Do not set together with argocd_gitops_ssh_private_key."
  type        = string
  default     = ""
  sensitive   = true
}

variable "argocd_gitops_ssh_private_key" {
  description = "For private Git over SSH: PEM/OpenSSH private key matching a deploy key or user key on the repo. Use an SSH repoURL in argocd_gitops_repo_url (e.g. git@github.com:org/repo.git). Do not set together with argocd_gitops_https_password."
  type        = string
  default     = ""
  sensitive   = true
}

variable "argocd_gitops_repo_credential_url_prefix" {
  description = "URL prefix Argo matches to this credential (longest prefix wins). Empty = derive from argocd_gitops_repo_url by stripping a trailing .git (must match how you use repo URLs)."
  type        = string
  default     = ""
}
