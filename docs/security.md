# Security model

PR validation has no cloud connection. Azure plan is a manual trusted-main run
using a Reader identity plus Blob lease access. Apply and destroy use separate
federated identities with Contributor only on the bootstrap-owned platform RG.
Their delegated role-assignment administrator grants are constrained to specific
role definitions: Network Contributor, AcrPull, AcrPush, Key Vault Secrets User
and AKS RBAC Cluster Admin. They cannot grant Owner/Contributor or modify backend
RBAC. The bootstrap key has a separate private bootstrap-state container; pipeline
Blob roles cover only the shared-root tfstate container. Review these powerful but bounded grants before bootstrap. The plan identity
can manipulate its authorized state blobs, so trusted pipelines and protected
state access remain essential even for planning.

Pipeline identities and their federation credentials live in the protected state
RG, outside recurring Contributor scope. A deployment identity cannot rewrite its
own federation to obtain a path around Azure DevOps protected-resource checks.
Workload/cluster identities remain in the managed platform RG.

No client secret is stored. AzureCLI tasks obtain WIF through service connections.
Terraform uses renewable Azure DevOps OIDC request credentials rather than
freezing a short-lived idToken across a long deployment. Exact issuer/subject
and service connection IDs are external setup values. Never echo tokens or run
shell tracing. Plan files and JSON may contain sensitive data; restrict artifact
read access/retention and agent filesystem access. Checksums detect tampering
after trusted download; trust comes from restricted build provenance and Azure
DevOps permissions, not from an unsigned manifest alone.

## Protected resources

Create azure-lab-apply, azure-lab-destroy, azure-lab-app-publish and stage-promotion
**before** enabling pipelines. Add external Approvals and Checks, branch control
for protected main and an exclusive lock to each relevant environment. Disable
self-approval. Grant only the intended CD/destroy/promotion definition access.
Apply the same controls to write-capable service connections and protect the
lab-config variable group. Use a required template check where available. Deny
Build Service administration of environments, checks, service endpoints, pipeline
definitions and repository policy bypass. Do not grant 'all pipelines' access.
Connection checks protect credentials even if a changed YAML removes an
environment reference. Platform administrators can still change checks; record
and audit that trust boundary. YAML alone cannot create or prove these controls.

## Kubernetes and secrets

Entra authentication and Azure RBAC are enabled; AKS local admin accounts are off.
The API allows only explicit public CIDRs. Prefer private APIs with private agents
in production. Azure CNI Overlay and Cilium enforce network policies on AKS.
Test isolation rather than assuming it.
Dev/Stage have restricted Pod Security, quotas (including zero LoadBalancer/PVC
allowance), limits, default-deny policies, scoped observer roles and distinct
workload identities. Bind observer Roles only to approved user/group subjects;
the sample application has no Kubernetes API rights and no automounted API token.

Key Vault uses RBAC, purge protection, soft delete and a deny-by-default firewall
with the AKS service-endpoint subnet and approved operator IPs. Each namespace's
OIDC subject is bound to its own managed identity. The lab identities currently
have Secrets User at the shared vault scope; stronger isolation uses separate
vaults or reviewed per-secret scopes. No secret value is created by Terraform.
After explicit approval, an operator creates a harmless test secret through a
secure portal/session, updates secretName in the environment values and enables
the CSI integration with the corresponding client/tenant/vault IDs. The pod mounts
a read-only file and readiness checks availability without returning content.
No Kubernetes Secret synchronization is enabled. Rotation is eventual; a missing
value blocks readiness, not liveness. Unit tests simulate the mounted file;
they cannot demonstrate a real Entra exchange or Key Vault firewall.

## Gates and exceptions

TFLint, Terraform validation/mock tests, Checkov, Trivy config/secret/dependency
and image scans, Helm schema/lint and Kubeconform are gates. No soft-fail or
blanket ignore flag is permitted. Image scans block HIGH/CRITICAL findings,
including unfixed findings; investigate/upstream-patch before release. Secret
scan output must be reviewed as sensitive data.

Any exception must identify the exact resource, scanner/check ID, evidence,
mitigation, owner, expiry and production alternative in security-exceptions.md.
Inline exceptions should be narrowly scoped; provider-schema false positives
must cite schema evidence. Do not suppress unknown findings to get a green build.
