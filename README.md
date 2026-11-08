# Azure Platform DevOps Lab

An Azure AKS platform engineering project using Terraform, Azure DevOps,
federated identity, Key Vault CSI, Docker, Helm and Argo CD. AKS is the only
supported deployment target. Docker is used to build application images.

Azure resource creation defaults off. Validation does not deploy resources.
Cloud deployment, registry publication, identity changes and infrastructure
removal use explicit approval workflows. AKS Free covers cluster management;
nodes, networking and other Azure services remain billable.

## Start here

1. Read [validation evidence](docs/validation.md) for what actually ran.
2. Read [discovery](docs/discovery.md). The 7 November 2026 check found a Disabled
   subscription and insufficient quota. Recheck eligibility before deployment.
3. Follow the [Azure deployment runbook](docs/deployment-guide.md).
4. Review [architecture](docs/architecture.md), [pipeline setup](docs/pipeline-flow.md)
   and [security controls](docs/security.md).

## Build and validate without deployment

On Windows, install workspace tools with `scripts/install-tools.ps1`, run
`scripts/python.ps1 -m pytest application/tests tests -q`, then
`scripts/validate.ps1`. PowerShell script execution must be permitted by your
machine policy. On Linux or an Azure DevOps agent, use the same dependency setup
as [the pipeline tools template](pipelines/templates/tools.yml), then run
`bash scripts/validate.sh`.

These checks need no Azure credentials. Helm renders use
`tests/fixtures/image.yaml`, a synthetic image that must never be deployed.
The deployable chart defaults deliberately leave the registry and digest empty;
a release must supply a real scanned registry image and immutable SHA256 digest.

## Azure deployment

Bootstrap creates protected Terraform state storage, platform resource group,
federated pipeline identities and scoped permissions. The shared Terraform root
creates one AKS cluster with Dev and Stage namespaces, networking, identities,
Key Vault and budgets. Optional ACR, autoscaling and paid monitoring default off.
For this repository's integrated image publication flow, approve and enable ACR
before running the application publish stage.

The node candidate is two 4-vCPU `Standard_D4ds_v5` instances with 64-GB ephemeral
OS disks. Verify regional capacity, quota and pricing, including a third upgrade
surge node. The outbound Standard load balancer and public IP are billable.

Infrastructure changes use a reviewed saved Terraform plan and protected apply
pipeline. Application changes use scanned images, release PRs in a separate
GitOps repository and Argo CD reconciliation. Stage receives the tested Dev
digest through an approved promotion. Rollback is a reviewed Git revert.

## Repository map

| Path | Purpose |
|---|---|
| bootstrap | Protected state backend, platform RG, scoped identities and subscription budget |
| terraform/modules | Nine reusable infrastructure modules |
| terraform/environments/shared-aks | Shared Azure AKS platform root |
| terraform/environments/cluster-services | Optional Terraform owner for Argo CD on an explicit AKS context |
| pipelines | Static CI, saved-plan CD, application CI, promotion and protected destroy |
| application | FastAPI, HTML/JS, Dockerfile, dependency locks and tests |
| kubernetes | Platform namespaces, quotas, limits, network policies and observer RBAC |
| helm/sample-application | Application chart and environment values |
| argocd | Installation values and Application/AppProject generator instructions |
| gitops-repo | Independent GitOps repository seed |
| scripts | Validation, plan provenance, cost/preflight and guarded AKS lifecycle tools |
| docs | Architecture, setup, costs, security and operations |

Provider locks belong to their Terraform roots. Do not commit state, plans,
kubeconfigs, credentials or secret values. Restrict sensitive plan artifacts.

## Costs and cleanup

Run `python scripts/preflight.py --region centralindia` for read-only eligibility
checks and `python scripts/estimate-cost.py --discover` for retail-price candidates.
Fill and review `cost-inputs.example.json`, then calculate with
`python scripts/estimate-cost.py --input reviewed-cost-inputs.json`.

Cleanup uses the manual protected `pipelines/destroy.yml` saved-plan workflow.
It retains bootstrap resources. Backend deletion and retained data require a
separate reviewed procedure. Budget alerts do not cap spending.
