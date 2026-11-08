# Alternative owner to scripts/install-argocd.sh. Never use both.
variable "enable_addons" {
  type        = bool
  default     = false
  description = "Opt into installing cluster services on the explicit context"
}
variable "kubeconfig_path" {
  type        = string
  description = "Explicit local kubeconfig; never commit this file"
}
variable "kube_context" {
  type        = string
  default     = "kind-platform-lab"
  description = "Exact intended context; use kubelogin azurecli authentication for AKS"
}
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}
provider "helm" {
  kubernetes = { config_path = var.kubeconfig_path, config_context = var.kube_context }
}
resource "kubernetes_namespace_v1" "argocd" {
  count = var.enable_addons ? 1 : 0
  metadata { name = "argocd" }
}
resource "helm_release" "argocd" {
  count      = var.enable_addons ? 1 : 0
  name       = "argocd"
  namespace  = kubernetes_namespace_v1.argocd[0].metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "10.14.0"
  values     = [file("${path.module}/../../../argocd/installation/values.yaml")]
  wait       = true
  timeout    = 600
}
