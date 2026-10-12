terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.39.0, < 8.6.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.27.0, < 4.0.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.2.0, < 2.0.0"
    }
  }
}
