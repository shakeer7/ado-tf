# Deployment runbook

## Local mode

Use the Windows commands in the main README or the Linux Bash equivalents.
First verify Docker's Linux engine answers `docker info`. Installing a CLI does
not mean its engine is running. The scripts do not modify unrelated kubecontexts.
Build and load the sample image before deployment. Helm installs Dev with one
replica and Stage with two/PDB. No ingress, database, cloud account or registry
is required. Metrics-server is local and optional; its kubelet TLS exception is
Kind-only and is never used on AKS. Optional Prometheus/Grafana are intentionally
not deployed to save local resources; logs, health endpoints and metrics suffice.

For GitOps, install pinned Argo CD with ClusterIP, generate the independent local
Git repository and read-only Git daemon, then apply the generated AppProject and
Applications. `host.docker.internal:9418` must be reachable from pods on Docker
Desktop. On Linux set LOCAL_GITOPS_URL to a host address reachable through Kind's
Docker bridge. The daemon exports only sample source, with receive-pack disabled;
do not place secrets in it. No remote repository is created or pushed by local
setup. Existing Helm application objects are adopted by Argo; stop direct Helm
upgrades at that point. Keep platform namespaces/quotas under platform ownership.

Inspect `kubectl -n argocd get applications` and Application conditions before
claiming GitOps worked. For private Azure Repos, an Argo repository credential
must be configured through a separately approved secure workflow. Azure DevOps
ARM WIF is not automatically a Git credential for Argo CD. Do not commit PATs.
Prefer a supported read-only repository integration/credential with rotation.

## Azure mode

Azure mode is currently blocked by the discovered disabled subscription and
exhausted regional quota. The following is a future approved procedure, not an
instruction to deploy immediately.

1. Confirm the subscription is Enabled through ARM, review the actual billing
   offer/credit expiry in Azure Portal, and decide an affordable maximum exposure.
   No credits or free service allowances are assumed. Run scripts/preflight.py.
2. Check available regional AND VM-family cores. Plan for two 4-vCPU system nodes plus a
   third 4-vCPU upgrade surge node (more if enabling autoscaling/rotation). Check the exact
   Standard_D4ds_v5 candidate's restrictions, >=4 GiB RAM, ephemeral OS disk support,
   temp/cache capacity >=64 GiB and current AKS system-pool requirements. Do not
   substitute B-series. A missing quota/capacity/offer permission means stay local.
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
   Install Argo using **one** owner: install-argocd.sh OR the optional isolated
   cluster-services Terraform root. Do not run both. Use a distinct state key if
   that root has a remote backend.
10. If ACR is approved, set enable_acr and the app pipeline principal ID, review a
    new Terraform plan, and approve the change. Application CI publishes scanned
    images and proposes immutable GitOps releases. Keep app public access off;
    demonstrate with port-forward.
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
