# Cost model and controls

Static validation creates **zero Azure resources**. Azure deployment incurs
charges for enabled resources. A personal Free Account can
be disabled, out of credits, quota-limited or ineligible for a requested SKU.
Promotional credits, free monthly allowances and ordinary billable usage are
different concepts. Never assume a $200 balance or that free eligibility persists.

The official retail API snapshot on 7 November 2026 returned $0.244/node-hour for
Linux Standard_D4ds_v5 in Central India. Two workers at 730 hours cost $356.24/month
or $11.71/day in compute alone. This is a subtotal, not an approved full deployment
estimate. A third surge node adds $0.244/hour while present. The same snapshot
returned $0.005/hour for a Standard static IPv4, $0.1666/day for optional Basic ACR,
and $0.03 per 10,000 Standard Key Vault operations. No credit/allowance was deducted.
Check the full meter snapshot in reports/retail-price-candidates.json locally and
refresh prices before deployment. Load-balancer/data-processing and storage
transaction meters still need explicit matching in the reviewed input sheet.

| Component | Azure exposure | Estimate basis |
|---|---|---|
| AKS management | Free tier management only; no SLA | Official AKS Free-tier policy |
| Worker VMs | Two >=4-vCPU Linux D4ds_v5 nodes | 2 x regional hourly rate x running hours, plus surge |
| Managed disks | Ephemeral 64-GB OS disk configured; no app PVC | 0 persistent OS capacity if SKU supports it; separately price any replacement/PVC/snapshot |
| Public IPv4 | One managed outbound Standard IP | Hourly rate x hours retained |
| Load balancer | Standard outbound LB | Base/rules plus data processing meter |
| ACR | Basic only, disabled by default | Registry/day and excess storage/transfer |
| Key Vault | Standard, RBAC and CSI operations | Transactions, rotation frequency, any enabled diagnostics |
| State storage | Standard LRS and retained Blob versions | Capacity, transactions, retained versions, egress |
| Azure Monitor | Disabled by default | Ingestion GB, retention, alert rules and notifications |

The cost calculator uses 730 hours/month and 730/24 days/month. It reports daily
averages and monthly totals from explicit reviewed prices and usage assumptions.
It refuses null prices instead of inventing a free allowance. `--discover` saves
current official Azure Retail Prices candidates with units and timestamp; choose
the exact Linux, region, currency, consumption and meter match. Retail pricing
is not the final subscription invoice. Taxes, exchange rate, offer discounts,
transfer and temporary upgrade capacity need separate review. Do not sum a
per-day meter as hourly or count Windows/Spot/reserved prices as Linux PAYG.

Bootstrap has subscription budget alerts so AKS-generated node-RG costs are
included; shared infrastructure also has a platform-RG budget. Recurring identities
are not granted permissions over a node RG merely to create another budget.
Budget alerts at 50/100% (subscription) and 50/80/100% (RG) do not stop resources.
Daily monitoring ingestion caps can be delayed/overshot and do not cap the bill.

Keep ACR, paid monitoring and autoscaling off unless needed. A node image upgrade
or immutable pool rotation may temporarily require a second pool/node; quota and
cost estimates must cover it. Autoscaling has a two-node minimum and three-node
maximum; review the extra capacity before enabling it. Current system-pool
requirements rule out the historical one-node example. Two workers remain a lab
configuration; production availability and maintenance need a separate design.

Stop AKS when idle only through the explicit guarded script after approval. OS
ephemeral data is disposable; storage, IPs, registry and Key Vault can remain
billable. Inspect resource inventory before destruction, preserve the backend,
check the original managed node RG for disks and IPs afterward, and verify Cost
Analysis again after billing data catches up. Never auto-delete an unknown disk.

Sources: [AKS tiers](https://learn.microsoft.com/azure/aks/free-standard-pricing-tiers),
[system pools](https://learn.microsoft.com/azure/aks/use-system-pools),
[Retail Prices API](https://learn.microsoft.com/rest/api/cost-management/retail-prices/azure-retail-prices),
[budgets](https://learn.microsoft.com/azure/cost-management-billing/costs/tutorial-acm-create-budgets),
[stop/start](https://learn.microsoft.com/azure/aks/start-stop-cluster).
