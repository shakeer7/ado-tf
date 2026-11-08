# Architecture and ownership

Mode A is the default. No Azure login is needed for application tests, rendering,
scanner checks or the local Kind workflow. Mode B requires a reviewed cost sheet,
an approved bootstrap and protected Azure DevOps resources.

| Owner | Resources |
|---|---|
| bootstrap Terraform root | State RG, storage/container, platform RG, deployment identities and their scoped roles; optional Entra administrator group |
| shared-aks Terraform root | VNet/subnets/NSG, AKS, workload identities, Key Vault, optional ACR/monitoring/budget |
| cluster-services Terraform root OR Helm installer | Argo CD and its namespace; choose one owner |
| platform namespace manifests | Namespaces, quota, LimitRange, namespace RBAC |
| Argo CD application chart | Application Deployment, ClusterIP, ConfigMap, service account, NetworkPolicy, optional CSI/HPA/PDB |
| AKS service | Node RG, VMSS, disks, outbound standard load balancer and managed public IP |

Dev and Stage share a cluster to reduce lab cost. This provides namespace isolation,
not separate failure, network or administrative boundaries. No production root is
executable. Terraform does not own application releases.

## Overall workflow
```mermaid
flowchart LR
  D[Developer] --> R[Azure Repos PR]
  R --> CI[Credential-free checks]
  CI --> P[Trusted main manual Azure plan]
  P --> A[Private saved-plan artifact]
  A --> G[Protected environment and connection approval]
  G --> TF[Terraform saved-plan apply via WIF]
  TF --> AKS[One AKS Free-tier cluster]
  R --> APP[Application CI and image scan]
  APP --> REG[Optional ACR immutable digest]
  REG --> PR[GitOps release PR]
  PR --> ARGO[Argo CD]
  ARGO --> DEV[Dev]
  DEV --> PROM[Tests and promotion approval]
  PROM --> ST[Stage]
```

## Free account Azure layout
```mermaid
flowchart TB
  S[Subscription eligibility and quota checked] --> B[State RG: protected storage]
  S --> R[Bootstrap-owned platform RG]
  R --> V[VNet and AKS subnet with NSG]
  V --> K[AKS Free management: two 4-vCPU-or-larger paid nodes]
  K --> E[Managed node RG: ephemeral OS disks and paid outbound LB and IP]
  R --> KV[Key Vault with firewall and RBAC]
  R -. optional .-> ACR[Basic ACR]
  R -. optional paid .-> MON[Log Analytics and alerts]
  K --> N[Dev and Stage: ClusterIP only]
```

## Terraform modules
```mermaid
flowchart TB
  B[bootstrap] --> RG[resource-group]
  B --> MI[managed-identity]
  B --> RA[role-assignment]
  S[shared-aks] --> NET[networking: VNet subnet NSG]
  S --> AKS[aks]
  S --> KV[key-vault]
  S --> MI
  S --> RA
  S -. optional .-> ACR[acr]
  S -. optional .-> M[monitoring]
  S --> C[cost-budget]
```

## State and locking
```mermaid
sequenceDiagram
  participant T as Terraform root
  participant E as Entra WIF
  participant B as Private Blob container
  T->>E: Request short-lived token
  E-->>T: Storage data-plane access
  T->>B: Acquire blob lease on root-specific key
  T->>B: Read state and write new version
  T->>B: Release lease
  Note over B: Versioning, soft delete, prevent_destroy; independent RG
```

## Azure DevOps identity
```mermaid
sequenceDiagram
  participant P as Authorized Azure Pipeline
  participant O as Azure DevOps OIDC
  participant E as Entra federated identity
  participant A as ARM and Storage
  P->>O: Service connection token request
  O-->>P: ID token: exact issuer and subject
  P->>E: Exchange token with audience api://AzureADTokenExchange
  E-->>P: Short-lived Azure token
  P->>A: Scoped reader or deployer operations
```

## Terraform CI/CD
```mermaid
flowchart LR
  PR[PR branch policy] --> STATIC[fmt validate tests lint scans]
  MAIN[Reviewed main manual run] --> STATIC
  STATIC --> PLAN[Reader WIF plan]
  PLAN --> ART[Plan JSON, binary, checksums, commit, run and backend metadata]
  ART --> REVIEW[Protected deployment environment]
  REVIEW --> CHECK[Verify trusted run, main commit, age, hashes and target]
  CHECK --> APPLY[Apply exact binary plan under exclusive lock]
```

## Application delivery
```mermaid
flowchart LR
  C[Reviewed commit] --> T[Tests and dependency scan]
  T --> B[Build image]
  B --> S[Image and secret scan]
  S --> P[Approved optional ACR push]
  P --> D[Registry digest]
  D --> G[GitOps PR with immutable digest]
  G --> A[Argo reconciliation]
  A --> H[Dev rollout and HTTP smoke check]
```

## GitOps ownership
```mermaid
flowchart LR
  I[Infrastructure repository] --> TF[Azure and cluster services]
  I --> SPLIT[Export chart to separate GitOps repository]
  SPLIT --> VAL[Dev and Stage values]
  VAL --> AR[Argo CD polls repository]
  AR --> K[Application objects only]
  K --> DR[Drift detected and reconciled]
```

## Promotion
```mermaid
flowchart LR
  DEV[Healthy Dev digest] --> TEST[HTTP and rollout tests]
  TEST --> APPROVAL[Protected stage environment check]
  APPROVAL --> PR[Stage PR copies identical digest]
  PR --> POLICY[Branch reviewers and build validation]
  POLICY --> ARGO[Argo Stage sync]
  ARGO --> VALIDATE[Stage rollout and HTTP validation]
```

## AKS networking
```mermaid
flowchart LR
  OP[Allowed operator or agent public CIDR] --> API[Entra-authenticated AKS API]
  API --> V[VNet AKS node subnet and NSG]
  V --> O[Azure CNI Overlay pod CIDR]
  O --> D[Dev default deny plus DNS and app rules]
  O --> S[Stage default deny plus DNS and app rules]
  D --> CL[ClusterIP port 80 to container 8080]
  O --> LB[Paid outbound standard LB and public IP]
  LB --> WEB[Required image and Azure endpoints]
```

## Key Vault integration
```mermaid
sequenceDiagram
  participant P as Pod service account per namespace
  participant E as Entra workload identity
  participant C as Secrets Store CSI Azure provider
  participant K as Key Vault with firewall
  P->>E: Projected OIDC token for exact namespace subject
  C->>E: Exchange token for workload identity
  C->>K: Get named test secret under Secrets User role
  K-->>P: Read-only mounted file
  Note over P: Health API reports availability only, never value
```

## Monitoring
```mermaid
flowchart LR
  P[Application JSON stdout] --> KL[kubectl logs]
  N[Node metrics] --> MS[metrics-server local optional]
  MS --> TOP[kubectl top and optional HPA]
  P -. paid optional .-> LA[Container Insights and Log Analytics]
  LA -. optional .-> AL[Selected Azure metric alert]
```

## Safe destruction
```mermaid
flowchart LR
  M[Manual target and typed confirmation] --> INV[Resource inventory]
  INV --> DP[Terraform destroy plan for shared root only]
  DP --> AR[Reviewable private artifact]
  AR --> G[Protected destroy environment and connection]
  G --> V[Provenance and expiry validation]
  V --> A[Apply exact destroy plan]
  A --> OR[Inspect platform and node RG orphans]
  OR --> B[Backend and platform RG retained by bootstrap]
```

## Modes
```mermaid
flowchart TD
  START[Default: no Azure resources] --> LOCAL[Docker and Kind]
  LOCAL --> H[Helm Dev and Stage]
  H --> G[Optional Argo with reachable Git repository]
  START -. explicit approval .-> PRE[Azure eligibility, quota and price review]
  PRE --> APPROVED[Approved bootstrap and pipeline setup]
  APPROVED --> AZ[One AKS shared lab]
  PRE -->|unsupported or unaffordable| LOCAL
```
