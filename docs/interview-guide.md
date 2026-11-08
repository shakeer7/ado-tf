# Interview guide

## A natural three-minute explanation

I built this platform to demonstrate how I would manage infrastructure and
application releases while keeping a personal Azure lab affordable. The default
mode runs locally with Docker and Kind, so practicing CI, Helm, GitOps and rollback
does not depend on Azure credits. The optional Azure mode uses one shared AKS
cluster with Dev and Stage namespaces. That is a lab cost decision; I would not
present namespace isolation as equivalent to separate production environments.

Terraform owns Azure infrastructure through reusable modules. A separate
bootstrap owns the state account and platform resource group. Blob state uses
Entra access, leases, versioning and soft deletion. Each root has its own key and
no root owns another root's resources. Backend destruction is outside the
ordinary cleanup workflow.

Pull requests run checks without cloud credentials. A trusted manual main run
uses a read-oriented WIF connection to produce a saved Terraform plan. The artifact
records the run, commit, target, hashes and expiry. Apply uses the exact approved
binary plan after external environment and connection checks. If it is stale,
we make a new plan and approve it again. Pipeline YAML alone is not an approval
boundary; I also restrict service connections and environment administration.

Application CI tests FastAPI, scans dependencies, builds and scans an image,
then optionally publishes it to ACR using federation. Release PRs contain an
immutable digest in a separate GitOps repository. Argo reconciles Dev and Stage.
Promotion copies the tested Dev digest after approval and review. Rollback is a
Git revert, so the desired state and audit trail agree. I keep Argo away from
Terraform-owned resources to prevent ownership fights.

AKS uses Entra authentication, Azure RBAC, CNI Overlay, network policies and
workload identity. A namespace-specific identity retrieves a test secret through
Key Vault CSI without putting its value in Terraform or Git. The application
reports readiness and deployment metadata but never returns the secret. Paid
monitoring and ACR are optional. I explicitly account for nodes, outbound load
balancer and IP costs; the Free management tier does not make the cluster free.

Cleanup is a separate manual pipeline: inventory, saved destroy plan, approval,
apply and orphan verification. It retains state and never offers a production
target. I also keep an honest validation report: unit/static checks, actual local
rollouts and real Azure integration are different levels of evidence.

## Questions and answers

**Why Terraform?** It provides reviewable desired state, a dependency graph,
reusable interfaces and a plan artifact that can be approved independently from
execution. It still needs protected state, identities and operational discipline.

**Why remote state?** Multiple operators need a consistent mapping of configuration
to resources and a locking mechanism. Blob leases reduce simultaneous writers;
versioning and backups help recovery. State is sensitive even when outputs are
marked sensitive, because that flag only affects presentation.

**Why federation?** Short-lived workload tokens remove the need to store and
rotate a long-lived client secret. Exact issuer, subject, audience, connection
authorization and RBAC scopes remain necessary. Pipeline WIF and pod workload
identity are separate trust relationships.

**How are environments managed?** Shared Azure infrastructure has one state root;
Dev/Stage have independent namespace values and release metadata. A single shared
cluster reduces cost but shares nodes, control plane and administrative blast
radius. Production would use separate subscriptions/clusters and data boundaries.

**How do you approve plans?** A protected-main manual plan publishes a sensitive
artifact bound to source, target, run and time. External checks approve the apply
stage/connection. Integrity and REST build provenance are verified immediately
before Terraform consumes the same saved plan.

**How do you handle drift?** Terraform drift is detected with a refreshed plan and
reviewed against the intended infrastructure. Argo self-heals application drift
according to Git. I do not restore state files to undo normal infrastructure drift.

**Why no public ingress?** Port-forward demonstrates the application without
adding a public app load balancer. Azure outbound dependencies still need a
reviewed egress design and have their own costs.

**How do you protect destruction?** Separate manual pipeline and identity, fixed
lab target, typed confirmation, inventory, saved destroy plan, external approval,
same-run provenance, protected backend and post-destroy resource checks. A failed
orphan check reports leftovers; it does not delete unknown disks.

**What would change in an enterprise?** Separate environments/subscriptions,
private endpoints and APIs, routed ephemeral agents, multiple failure domains,
sufficient node/surge quota, production SLAs, governance policies, image signing,
artifact attestations, centralized audit, tested backup/restore, SLOs, tenant-wide
identity controls, formal security exceptions and cost allocation. I would first
gather availability, compliance, throughput and recovery requirements rather
than simply making this lab bigger.

**What remains unproven without a live environment?** Azure policy/offer eligibility,
regional capacity, federated token exchange, service connection checks, real Key
Vault access, server-side pipeline compilation and actual cluster rollouts. Static
validation cannot establish those facts.
