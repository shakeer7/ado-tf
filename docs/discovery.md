# Discovery â€” 7 November 2026, Asia/Calcutta

This is a historical setup record. The project now supports Azure AKS deployment
only; previously downloaded cluster tooling is not a supported deployment path.

The workspace began empty. Tools found: Terraform 1.15.0, Helm 4.2.2, kubectl
1.34.1, Azure CLI 2.85.0, Git 2.53.0 and Docker Desktop binaries. Kind, TFLint,
Checkov and Trivy were absent. Python Store aliases were unusable. Azure CLI
contains Python 3.13.11 without venv; workspace-only dependency directories are
used by scripts/python.ps1. System Python/CLI packages were not modified.

Official release APIs were checked before selecting versions in versions.json.
Pinned Terraform, Helm, Kind, TFLint and Trivy binaries were downloaded into
.tools and their published SHA256 checksums checked. Terraform generated real
provider locks. Hash-locked application dependencies were resolved with pip-tools.

## Read-only Azure observations

| Check | Observation |
|---|---|
| Cached `az account show` | Enabled |
| Authoritative ARM subscription GET | **Disabled** |
| Offer quota ID | FreeTrial_2014-09-01 |
| Spending limit policy | On |
| Central India regional cores | 4 used / 4 allowed |
| Central India standardDSv5Family | 4 used / 4 allowed |
| Microsoft.ContainerService registration | Registered |
| AKS versions endpoint | Central India advertised 1.37.1 under KubernetesOfficial support, not marked preview; recheck before deployment |
| Selected Ddsv5 family quota | 0 used / 4 allowed; insufficient for two 4-vCPU nodes plus surge |
| Selected D4ds_v5 capability | 4 vCPUs, 16 GiB RAM, ephemeral OS supported, 150 GiB resource disk |
| Selected SKU restrictions | Zonal NotAvailableForSubscription restrictions reported for zones 1 and 3; regional deployment availability is not proven |
| Promotional balance/expiry | Not verified; no universal credit-balance API assumed |

ARM state takes precedence over cached CLI status. No Azure apply, destroy,
resource registration, group deletion, secret creation or permission change was
performed. Existing resource usage was observed only; nothing was stopped or deleted.
Do not assume that a free-trial spending-limit policy is a budget-based cap after
conversion to another subscription offer.
