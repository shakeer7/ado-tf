# Azure Platform DevOps Lab

A local-first platform engineering project: Terraform, Azure DevOps, AKS,
federated identity, Key Vault CSI, Docker, Kind, Helm and Argo CD.

**Default Azure spend: zero.** No Azure resource has been deployed by the setup
or validation commands. Azure deployment, registry publication, cloud identity
changes and infrastructure destruction require separate explicit approval.
AKS Free covers cluster management; it does not make nodes or networking free.

## Start here

1. Read [validation results](docs/validation.md) for what actually ran.
2. Read [discovery](docs/discovery.md): the checked subscription was **Disabled**
   in ARM and Central India regional vCPU quota was **4/4 used**. Use local mode.
3. Follow [the deployment runbook](docs/deployment-guide.md).
4. Explore [the fourteen diagrams](docs/architecture.md) and
   [the interview guide](docs/interview-guide.md).

## Local mode on Windows

Docker Desktop must be running with Linux containers. The scripts always target
the dedicated `kind-platform-lab` context. Reserve approximately 6–8 GB for Docker
when including Argo CD. Existing clusters are not deleted automatically.

```powershell
# Tool binaries are workspace-local. Install dependencies once if needed.
./scripts/install-tools.ps1
./scripts/python.ps1 -m pytest application/tests tests -q
./scripts/validate.ps1
./scripts/lab.ps1 create
./scripts/lab.ps1 deploy
./scripts/lab.ps1 metrics
./scripts/lab.ps1 verify
kubectl --context kind-platform-lab -n dev port-forward svc/sample-application 8080:80
# Browse http://localhost:8080

# Optional local GitOps, using a read-only Git daemon for the sample repository:
./scripts/lab.ps1 argocd
./scripts/lab.ps1 gitops
kubectl --context kind-platform-lab -n argocd get applications
```

The local image is built once and explicitly loaded into Kind's separate
containerd image store. No registry account is required. Do not use `latest`.
Once Argo adopts the applications, release through Git rather than Helm upgrades.
See [rollback exercises](docs/rollback.md) for release, failure, drift and revert.

## Linux, WSL or a local Azure DevOps agent

Use an actual supported Linux Python installation and Docker engine, then:

```bash
bash scripts/install-tools.sh
export PATH="$PWD/.tools:$PATH"
python -m venv .venv
source .venv/bin/activate
python -m pip install --require-hashes -r application/requirements-dev.txt
python -m venv .tools/checkov-env
.tools/checkov-env/bin/pip install checkov==3.4.3
export PATH="$PWD/.tools/checkov-env/bin:$PATH"
bash scripts/validate.sh
bash scripts/create-kind.sh
bash scripts/deploy-local.sh
bash scripts/install-metrics.sh
KUBE_CONTEXT=kind-platform-lab bash scripts/install-argocd.sh
bash scripts/setup-local-gitops.sh
```

Git Bash on Windows is suitable for shell syntax checks; use `lab.ps1` for the
Windows lab because the system `python` alias may point at the Microsoft Store.

## Optional Azure mode

[Azure setup](docs/deployment-guide.md#azure-mode) covers billing eligibility,
quota, exact regional Kubernetes version, current retail prices, backend
bootstrap and WIF service connections. No deployment is enabled by a default
variable. Hosted CI agents are optional; every pipeline accepts an agent pool.
Azure Repos PR validation is configured through branch policies.

One cluster hosts dev/stage namespaces. The default node candidate is a
pair of 4-vCPU `Standard_D4ds_v5` nodes with 64-GB ephemeral OS disks, subject to verified
availability, capacity and quota. Upgrade surge requires a third node. A paid
outbound standard load balancer and public IP are part of this Azure design.
ACR, autoscaling and paid monitoring are off by default.

## Repository map

| Path | Purpose |
|---|---|
| bootstrap | Protected backend, platform RG, scoped identities and subscription budget |
| terraform/modules | Nine reusable infrastructure modules |
| terraform/environments/shared-aks | One optional shared Azure cluster root |
| terraform/environments/cluster-services | Optional alternative Terraform owner for Argo CD |
| pipelines | Static CI, saved-plan CD, application CI, promotion and protected destroy |
| application | FastAPI, HTML/JS, Dockerfile, hashed dependency locks and tests |
| kubernetes | Platform namespaces, quotas, LimitRange, policies and observer RBAC |
| helm/sample-application | Executable application resources and environment values |
| argocd | Installation values and generator instructions for Applications/AppProject |
| gitops-repo | Complete independent GitOps repository seed |
| scripts | Local lab, checks, plan provenance, cost/preflight and guarded lifecycle tools |
| docs | Architecture, setup, costs, security, operations and interview material |

Provider locks belong to their Terraform roots. There is intentionally no
misleading top-level provider lock. Do not commit plans, state, kubeconfigs,
credentials or real secret values. Sensitive plan artifacts need restricted
retention/access in Azure DevOps. Review [pipeline controls](docs/pipeline-flow.md)
and [security decisions](docs/security.md) before enabling any cloud pipeline.

## Costs and cleanup

```powershell
./scripts/python.ps1 scripts/estimate-cost.py --local
# Read-only discovery, after checking account access:
./scripts/python.ps1 scripts/preflight.py --region centralindia
./scripts/python.ps1 scripts/estimate-cost.py --discover
# Fill and review cost-inputs.example.json before calculating an Azure estimate.
./scripts/python.ps1 scripts/estimate-cost.py --input reviewed-cost-inputs.json
# Deletes only this local lab, after inventory:
./scripts/lab.ps1 cleanup -Confirmation 'DELETE platform-lab'
```

Azure cleanup is a separate manual, approved saved-destroy-plan pipeline. It
retains bootstrap resources. Key Vault purge protection retains deleted secret
data until retention expires. Persistent data and backend deletion need a
separate reviewed procedure. Budget alerts are not spending limits.
