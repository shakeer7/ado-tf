# Azure DevOps setup and pipeline flow

Create two repositories: azure-platform-devops (this tree) and platform-gitops
(scripts/export-gitops.py output). Create pipelines from the five entry YAML files.
Name Terraform CI `platform-terraform-ci` to match the CD pipeline resource. Record
its numeric definition ID as TrustedPlanPipelineId. Pipeline YAML parsing/tests
are local checks; only an Azure DevOps run can validate service permissions and
the server's complete YAML/task compilation.

## One-time manual configuration

1. In Repos → Branches → main → Branch policies, add required build validation
   for Terraform/application CI. Azure Repos ignores YAML `pr` triggers.
2. Configure WIF ARM connections named platform-plan, platform-apply,
   platform-destroy and platform-app. Follow the bootstrap README. Copy exact
   federation issuer/subject; use bootstrap outputs for client IDs. Never create
   a subscription-wide Contributor connection or store a client secret.
3. Configure protected environments, connection checks, branch control, exclusive
   locks and pipeline authorization as described in security.md. Do this before
   the first manual run; an auto-created environment has no automatic approval.
4. Create a protected `lab-config` variable group containing external values:
   StateResourceGroup, StateAccount, PlatformResourceGroup, TenantId, UniqueSuffix,
   AksVersion (exact GA patch), ApiCidrsJson, AdminGroupsJson, BudgetEmailsJson,
   BudgetStartDate (first of current month), EnableAcr/EnableMonitoring (false),
   PlanServiceConnectionId, ApplyServiceConnectionId, DestroyServiceConnectionId,
   TrustedPlanPipelineId, AcrName, AppPipelinePrincipalId (bootstrap output), GitopsUrl, KubeContext. JSON list examples use
   normal JSON strings. Do not place secret values here.
5. Authorize only intended pipeline definitions to consume protected resources.
   Set job authorization scope to the project; limit repository access. Grant the
   project Build Service read plus create-branch/PR permissions on platform-gitops,
   deny policy bypass/direct main writes and require reviewer/build checks.
6. Provision a supported Linux self-hosted pool `platform-local` if hosted minutes
   or parallel jobs are unavailable. Register the agent manually using a scoped,
   short-lived registration credential, then remove that credential. Do not store
   it in Git. Use a dedicated user and clean workspaces, never run untrusted PR
   code on an agent with access to Azure credentials or Docker production hosts.
   Protect deployment agent pools with main-branch checks and authorize only the
   intended trusted pipeline definitions; PR jobs use a separate unprivileged pool.

All entry pipelines accept a pool object. Use `{name: platform-local}` for an
existing local agent, or the default hosted ubuntu-24.04 image for credential-free
checks. Application publish/rollout and promotion require a dedicated agent with
an explicitly configured observer/exec Kubernetes context and network route to
the cluster. Prepare kubeconfig via Entra/kubelogin on that agent; do not use an
admin kubeconfig in pipeline variables. For Azure, align API/storage allowlists
to the agent's static public egress. Dynamic hosted egress is not automatically
added to firewalls. Hosted images are not a private network route.

## Terraform

Automatic PR/main CI runs checks without Azure. A manual main run with azurePlan
true creates a saved plan under the plan connection. The plan artifact includes
binary plan, review JSON/text, lock file, backend metadata, inventories and a
manifest bound to run, pipeline definition, commit, root, subscription and state
key. It is sensitive. Apply is manual; select the correct CI pipeline-resource
run in Azure DevOps. CD accepts only a successful manual main plan run from the
trusted definition/repository and requires the same source commit. It rejects
plans older than two hours. Downloaded artifacts are never treated as trusted
solely because they contain a checksum. Azure DevOps ACLs and REST build
provenance supply the trust.

External environment/connection approval happens before apply. Immediately before
execution, hashes, source, operation, target and age are checked again. Terraform
then applies the exact saved binary, never a newly generated implicit plan. A
stale state serial or expired approval requires a new plan/run and new approval.
Blob leases serialize state; the protected environment exclusive lock limits
overlapping deployment runs. Different environments using the same state key do
not magically acquire a shared environment lock, so backend locking is retained.

## Application and promotion

Application CI tests, scans locked dependencies, builds, scans and publishes a
tested image artifact. Azure publication defaults off and requires a manual main
run plus the protected publish environment. ACR authentication uses WIF and scoped
AcrPush. The release PR stores a registry digest, then Argo polls Git. The job
waits up to ten minutes for a reviewer to merge and for reconciliation. If review
needs longer, rerun validation after merge; a timeout does not auto-merge the PR.

Stage promotion verifies Dev, snapshots the immutable Dev release as an artifact,
waits for protected stage-promotion approval, and proposes exactly that digest in
a Stage PR. The PR still requires repository approval. Do not promote a mutable
tag or refetch a newer Dev digest after approval. Git revert is the normal rollback.
Argo may poll the repository; no ad hoc app kubectl deployment is required.

## Destruction

destroy.yml has no push/PR trigger and only shared-aks as a target. A manual main
run must type `DESTROY shared-aks`. A Reader plan identity records inventory and
creates a saved destroy plan. Review the artifact, then approve azure-lab-destroy
and its connection. The execution stage accepts only the exact same run's
artifact. It never runs bootstrap destroy, group deletion or a production target.
Post-checks inventory the original node RG for leftovers. No orphan is silently
deleted. Retained bootstrap resources and soft-deleted vault data need a separate
approved lifecycle. Check final cost inventory after Azure's billing delay.

## Agent versions and manual fallback

Provision Azure CLI 2.92.0 on deployment agents; WIF/publication scripts reject a different CLI. Discovery used the existing 2.85.0 read-only installation without upgrading it.

If protected checks or hosted capacity are unavailable, keep cloud CD disabled. Use a dedicated self-hosted agent, or have an authorized operator review the saved binary plan, its source/target/hash/age and costs before a separately approved interactive Terraform apply of that exact plan. Record approval and execution evidence. A YAML boolean is never a replacement for protected checks.
