terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.39.0, < 8.7.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.3.0, < 4.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.27.0, < 4.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0, < 1.0.0"
    }
    # Argo Application CR: hashicorp/kubernetes kubernetes_manifest often fails with
    # "no client config" on GKE; alekc/kubectl applies the same manifest reliably.
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.0, < 3.0.0"
    }
  }
}
