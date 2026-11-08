# Bootstrap and remote state

This root initially uses **local state**. It owns a separate state RG, protected
storage account/container, the platform RG, optional Entra admin group, WIF
identities and subscription budget. All Azure resources default to disabled.

## Before an approved bootstrap

Confirm subscription billing state, credits/expiry in the portal, quota, region,
current prices, static agent/operator public IPv4 and provider registrations.
Bootstrap needs permission to create RGs/storage/managed identities, scoped role
assignments and a subscription budget. Creating an Entra group separately requires
Graph permissions; use an existing group when unavailable. Recurring pipelines
receive RG-scoped roles, never subscription Contributor. Their identities live in
the protected state RG so they cannot rewrite their own federation. Provider auto-registration
is disabled; missing registrations require a separate approved operator action.

Create the four Azure DevOps ARM WIF connections manually without granting all
pipelines access. Copy their exact issuer and subject into federations with keys
`plan`, `apply`, `destroy`, `app`. Manual connection creation/verification may need
two steps: create a draft connection, bootstrap the identity/federation, then
save/verify with the output client ID. Existing user-assigned identities may be
imported rather than duplicated. Never invent issuer/subject strings: new and
older Azure DevOps connections can use different issuer formats.

After explicit approval only, copy terraform.tfvars.example, fill external values
and set both enable_azure/deployment_approved true. Use the pinned Terraform CLI:

```bash
terraform init
terraform plan -out=bootstrap.tfplan
# Review resource count, costs, role scopes, firewall and budget. Separate approval:
terraform apply bootstrap.tfplan
```

Initial Blob RBAC propagation may take several minutes; retry a failed container
creation after verifying Storage Blob Data Contributor and firewall access. Do
not enable account keys to work around propagation.

## Migrate only after storage exists

1. Back up local state to an encrypted location outside Git.
2. Copy backend.migrate.tf.example to backend.tf.
3. Copy bootstrap.backend.hcl.example to bootstrap.backend.hcl and fill its storage
   account/RG. Use the dedicated bootstrap-state container and an operator identity.
4. Run `terraform init -migrate-state -backend-config=bootstrap.backend.hcl` interactively.
5. Check `terraform state list`, Blob version history and a no-change plan. Keep
   the encrypted backup until restore is verified; do not delete it automatically.

Shared infrastructure uses shared-aks.tfstate in the tfstate container. Pipeline
identities are scoped only to tfstate and cannot access bootstrap-state. If using the
optional cluster-services Terraform owner remotely, allocate cluster-services.tfstate
and independently provision its container-scoped identity access. Local bootstrap
state is also supported if securely backed up. No root references an uncreated
backend during initial initialization.

Storage keys and public blobs are disabled. HTTPS/TLS1.2, versioning, 14-day blob
and container soft deletion, IP firewall allowlisting and prevent_destroy protect
state. A CanNotDelete lock also protects the backend RG from accidental ARM
deletion. The public endpoint is limited to approved static public IPv4s; this is a
documented lab tradeoff. Private endpoints and routable agents belong in production.
prevent_destroy protects Terraform actions, not privileged portal/API deletions.
Restrict Owner and resource deletion permissions separately.

## Recovery

For a lease: find the running pipeline first. Never force-unlock an active apply.
After proving no writer exists, record the lock ID and have an authorized operator
approve `terraform force-unlock LOCK_ID` for the correct root/key. This changes
backend state and is not an automatic script operation.

For corruption: stop writers, save the current blob and metadata, identify a known
good version, restore to an isolated test key and inspect lineage/serial/resources.
Approve the restore before replacing the active state. Prefer a tested blob
version restore; `terraform state push` is a recovery operation requiring review.
Never edit JSON by hand or use `-force` to conceal lineage mismatches. Reconcile
actual resources with a reviewed refresh-only plan before normal deployment.

The ordinary destroy pipeline never initializes or destroys this root. Deleting
backend resources, subscription budgets, retained vault data or the platform RG
requires an independent data-retention and billing review.
