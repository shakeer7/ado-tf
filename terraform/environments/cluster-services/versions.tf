terraform {
  required_version = "= 1.17.1"
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = "= 3.5.0" }
    helm       = { source = "hashicorp/helm", version = "= 3.3.0" }
  }
}
