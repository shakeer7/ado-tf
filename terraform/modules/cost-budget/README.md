# cost-budget

Reusable AzureRM module called by the bootstrap or shared-aks root. Provider
configuration belongs to the root. Run `terraform init -backend=false` and
`terraform validate` here for schema validation. Input types and validation are
in variables.tf; public outputs are in outputs.tf. All resources are conditional
at the calling root, and Azure deployment defaults to disabled.

Review docs/security.md and docs/cost-optimization.md before use. This module
does not authenticate through stored secrets. Azure role assignments need a
separately authorized bootstrap identity or constrained RBAC delegation.
