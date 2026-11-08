# Deployment runbook

## Azure AKS deployment

AKS is the only deployment target. Build and static validation run on workstations
or CI agents without deploying a Kubernetes cluster. Docker is required for image
builds. All cluster operations require an explicit approved AKS context.

The 7 November 2026 discovery found a disabled subscription and insufficient
quota. Recheck these conditions before using this approval-based procedure.

1. Confirm the subscription is Enabled through ARM, review the actual billing
   offer/credit expiry in Azure Portal, and decide an affordable maximum exposure.
   No credits or free service allowances are assumed. Run scripts/preflight.py.
2. Check available regional AND VM-family cores. Plan for two 4-vCPU system nodes plus a
   third 4-vCPU upgrade surge node (more if enabling autoscaling/rotation). Check the exact
   Standard_D4ds_v5 candidate's restrictions, >=4 GiB RAM, ephemeral OS disk support,
   temp/cache capacity >=64 GiB and current AKS system-pool requirements. Do not
   substitute B-series. A missing quota/capacity/offer permission means keep deployment disabled.
3. Use `az aks get-versions -l REGION -o json`, inspect patchVersions and isPreview,
   and pin one exact GA regional patch. Check upgrade support and kubectl skew.
4. Run the official retail-price discovery script, review Linux consumption rates,
   currency/meter units and all networking/storage/monitoring costs. Fill the cost
   input sheet; no null/unverified price is accepted by the calculator. Add burst,
   rolling-upgrade and egress contingency. Approve the costs before bootstrap.
5. Obtain separate explicit approval for bootstrap cloud identities/permissions
   and state resources, then follow bootstrap/README.md. Migrate state only after
   the backend exists. An administrator separately approves/registers missing
   Microsoft resource providers; provider auto-registration stays off.
6. Finish Azure DevOps protected connection/environment/branch setup. Copy the
   shared root example tfvars and backend file and fill all external IDs, exact
   patch, static API CIDRs, group IDs, monthly budget/email/start date and tags.
   Set enable_azure/deployment_approved/cost_acknowledged only after approval.
7. Manually generate the trusted Azure plan, review costs and plan text, and select
   that CI run for CD. Approve protected checks only after reviewing the artifact.
   This design creates one cluster and does not create a LoadBalancer application
   service. Its outbound load balancer and public IP are still billable.
8. Use `az aks get-credentials --resource-group RG --name CLUSTER --file PATH`
   to a protected local file, convert its exec login with `kubelogin ... -l azurecli`
   if required, and set an explicit APPROVED_AKS_CONTEXT/KUBE_CONTEXT for scripts.
   Never retrieve an admin credential; local AKS accounts are disabled.
9. Apply only platform namespace/quota/network-policy/RBAC manifests using the
   approved AKS context. Give observer Roles to explicitly approved principals.
   Export `gitops-repo` with `scripts/export-gitops.py` into a separate checkout
   and publish it to the approved GitOps repository. Protect main and configure
   Argo with a read-only repository credential through a secure workflow; ARM
   WIF is not a Git credential. Generate manifests using
   `python scripts/configure-argocd.py --repo-url YOUR_GITOPS_URL`.
   Install Argo using **one** owner: install-argocd.sh OR the optional isolated
   cluster-services Terraform root. Do not run both. Use a distinct state key if
   that root has a remote backend.
10. For the integrated application delivery flow, approve ACR, set enable_acr and
    the app pipeline principal ID, review a new Terraform plan, and approve it. Application CI publishes scanned
    images and proposes immutable GitOps releases. Keep app public access off;
    demonstrate with port-forward using the explicit AKS context.
    The seed has empty image settings: merge the first Dev digest release before
    applying `out/argocd/project.yaml` and `out/argocd/sample-dev.yaml`. Add the
    Stage Application after the first approved Stage promotion PR is merged.
    Never deploy `tests/fixtures/image.yaml`; it is for static checks only.
11. If Key Vault testing is approved, create a harmless test secret securely outside
    Terraform, set environment-specific workloadIdentity client/tenant/vault IDs
    and secretName in GitOps values, and enable CSI. Do not put its value in logs,
    tfvars or Git. Check readiness and identity/firewall errors before promotion.
12. Enable paid monitoring only with an approved cost estimate. Apply the optional
    collection ConfigMap after enabling Container Insights. Confirm the intended
    ingestion scope, daily quota and metric alert charges. Quotas/budgets can be
    delayed and are not a hard spending cap.

Stop/start scripts require a typed action and exact cluster name. Stopped cluster
state is temporary; review AKS stop/start limits and supported behavior before
depending on it. Billing for retained resources may continue. Cleanup uses the
manual protected destroy pipeline; inspect orphan disks/IPs and costs afterward.
