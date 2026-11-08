# Verified dependencies

Verified on 7 November 2026 through publisher release APIs and package metadata.
Search indexes can lag releases: the live AzureRM API returned 5.13.0. The
machine's installed versions were recorded separately in discovery.md.

| Dependency | Pin |
|---|---|
| terraform | `1.17.1` |
| azurerm | `5.13.0` |
| azuread | `3.10.0` |
| kubernetes provider | `3.5.0` |
| helm provider | `3.3.0` |
| helm | `4.3.1` |
| kubectl | `1.37.2` |
| argocd | `3.6.1` |
| argocd chart | `10.14.0` |
| tflint | `0.65.0` |
| trivy | `0.76.2` |
| kubeconform | `0.8.0` |
| checkov | `3.4.3` |
| fastapi | `0.162.0` |
| uvicorn | `0.54.0` |
| pytest | `9.2.0` |
| httpx | `0.28.1` |
| pyyaml | `6.0.3` |
| pip tools | `7.6.2` |
| Azure regional Kubernetes snapshot | `1.37.1` (Central India; recheck eligibility) |
| Azure CLI deployment-agent pin | `2.92.0` (discovery used installed 2.85.0) |
| Docker CLI installed | `29.4.0` (engine validation blocked) |
| Python CI/scanner runtime | `3.13.18` |

Python container: 3.15.2 slim-trixie, from the Docker Official Images
[version manifest](https://github.com/docker-library/python/blob/master/versions.json).
Local tests use the installed Python 3.13.11. The application source supports both;
container runtime validation is reported separately. Hosted-agent OS images are
rolling; use a managed, versioned self-hosted image when full OS reproducibility
is required. Azure task major versions are pinned to supported task interfaces;
Azure DevOps controls their servicing patches.

Terraform 1.17.1 and AzureRM 5.13.0 were selected together and checked against the
actual provider schema. AzureRM 5 uses `user_assigned_identity_id` on federation
and subnet `service_endpoint` blocks. Provider locks include published checksums.
Helm provider 3 uses object-form Kubernetes configuration. Kubernetes provider
3.5.0 and Helm provider 3.3.0 are isolated in the optional cluster-services root,
avoiding same-apply AKS endpoint initialization. AzureAD is confined to the
optional administrator group in bootstrap; recurring infrastructure runs need
no Microsoft Graph application permissions.

The application uses GA APIs supported by Kubernetes 1.34â€“1.37. AKS versions are regional and
subscription dependent: select and pin an exact GA patch in the environment tfvars
and protected pipeline variable group after preflight. No global AKS patch is
invented. The kubectl client should match that minor (supported skew is Â±1).
Argo chart 10.14.0 is pinned and its application image is explicitly 3.6.1.
The Helm chart contains no floating chart dependencies. Checkov runs in a separate
environment because its packaging dependency conflicts with current pytest. The resolved scanner dependencies are pinned in tools/checkov.constraints.txt.

## Official verification sources

- [Terraform release API](https://api.github.com/repos/hashicorp/terraform/releases/latest)
- [AzureRM release API](https://api.github.com/repos/hashicorp/terraform-provider-azurerm/releases/latest)
- [AzureAD releases](https://github.com/hashicorp/terraform-provider-azuread/releases)
- [Kubernetes provider releases](https://github.com/hashicorp/terraform-provider-kubernetes/releases)
- [Helm provider releases](https://github.com/hashicorp/terraform-provider-helm/releases)
- [Helm releases](https://github.com/helm/helm/releases)
- [Argo CD releases](https://github.com/argoproj/argo-cd/releases/tag/v3.6.1)
- [Argo Helm releases](https://github.com/argoproj/argo-helm/releases/tag/argo-cd-10.14.0)
- [TFLint releases](https://github.com/terraform-linters/tflint/releases)
- [Trivy releases](https://github.com/aquasecurity/trivy/releases)
- [Kubeconform releases](https://github.com/yannh/kubeconform/releases)
- [FastAPI metadata](https://pypi.org/pypi/fastapi/json)
- [Checkov metadata](https://pypi.org/pypi/checkov/json)
- [AKS system-pool requirements](https://learn.microsoft.com/azure/aks/use-system-pools)

Refresh pins in a reviewed change, regenerate locks and rerun validation. Do not
automatically resolve latest versions inside deployment pipelines.
