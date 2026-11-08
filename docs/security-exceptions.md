# Reviewed lab exceptions

Owner: personal lab maintainer. Review by 7 December 2026 and before every Azure
deployment. These are explicit architecture tradeoffs, not production approvals.

| ID | Check/resource | Reason and mitigation | Production alternative |
|---|---|---|---|
| LAB-001 | CKV2_AZURE_33 / bootstrap state storage | Private endpoint incurs additional cost and requires privately routable agents. Public endpoint is deny-by-default with approved static public IPv4s, Entra RBAC, disabled keys and private container. | Private endpoint, private DNS and dedicated agents |
| LAB-002 | CKV2_AZURE_1 / bootstrap state storage | Microsoft-managed encryption is retained; CMK creates additional key availability, permission and cost dependencies. State is encrypted at rest and TLS-protected. | Governed CMK lifecycle and recovery drills |
| LAB-003 | CKV2_AZURE_21 / state containers | Blob read-request diagnostics incur ingestion/storage costs and are opt-in. Restricted Blob RBAC and version history reduce exposure; this does not replace a data access audit. | Approved storage diagnostic settings and protected log destination |
| LAB-004 | CKV_AZURE_163 / ACR | Paid Defender scanning replaced by blocking CI Trivy image scan. | Defender and centralized vulnerability policy |
| LAB-005 | CKV_AZURE_237 / ACR | Dedicated data endpoints require Premium; optional lab uses Basic. | Premium dedicated endpoints |
| LAB-006 | CKV_AZURE_166 / ACR | Only scanned images reach reviewed GitOps releases; separate quarantine is not implemented. | Isolated registry quarantine/signature policy |
| LAB-007 | CKV_AZURE_167 / ACR | SKU-dependent untagged-retention automation omitted; inventory before approved cleanup. | Supported automated retention with recovery policy |
| LAB-008 | CKV_AZURE_233 / ACR | Basic single-region lab has no zone redundancy guarantee. | Supported zone-redundant tier |
| LAB-009 | CKV_AZURE_165 / ACR | No multi-region workloads; geo-replication is an unnecessary paid dependency. | Replicate according to recovery requirements |
| LAB-010 | CKV_AZURE_139 / ACR | Basic registry uses public Entra-authenticated endpoint, admin and anonymous access disabled. | Premium private endpoint and private agents |
| LAB-011 | CKV_AZURE_164 / ACR | Signature verification is not implemented; scanned digests and reviewed PRs mitigate image substitution. | Cosign signatures and admission verification |
| LAB-012 | CKV_AZURE_115 / AKS | API has static public CIDR restrictions; private agent routing is outside this lab. | Private API with routable agents |
| LAB-013 | CKV_AZURE_227 / AKS | Subscription host-encryption eligibility not assumed; nodes use disposable ephemeral OS and no persistent app data. | Verify supported host encryption and enable it |
| LAB-014 | CKV_AZURE_170 / AKS | Free management tier explicitly has no production SLA. | SLA-backed tier |
| LAB-015 | CKV_AZURE_232 / AKS | Applications share the system pool to avoid additional paid user pools. | Dedicated system/user pools and taints |
| LAB-016 | CKV_AZURE_171 / AKS | Exact Kubernetes patches change through reviewed Terraform upgrades. | Governed upgrade automation and maintenance windows |
| LAB-017 | CKV_AZURE_116 / AKS | Pod Security restricted admission, quotas and scanners enforce local controls; Azure Policy add-on omitted. | Azure Policy with tested admission policies |
| LAB-018 | CKV_AZURE_117 / AKS | Configured ephemeral OS disks have no managed-disk encryption-set resource. | Review CMK requirements per disk/data type |
| LAB-019 | CKV2_AZURE_32 / Key Vault | Deny firewall and AKS service-endpoint subnet avoid private endpoint cost. | Private endpoint and private DNS |
| LAB-020 | CKV_K8S_43 / local Deployment only | Kind requires an explicitly loaded version tag. Annotation is absent for digest-based cloud releases. | Registry digest enforced by release script |
| LAB-021 | CKV_K8S_15 / local Deployment only | IfNotPresent uses Kind's loaded cache without registry access. Cloud release updater sets Always. | Always policy with pinned registry digest |

Other scanner findings must remain visible until resolved or independently
documented here with resource-scoped evidence and expiry.
