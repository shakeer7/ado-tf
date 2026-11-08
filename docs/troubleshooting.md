# Troubleshooting

| Symptom | Evidence to inspect | Safe response |
|---|---|---|
| CLI says Enabled, deployment fails | ARM subscription GET, billing/offer status | Trust authoritative ARM state; keep Azure deployment disabled |
| No VM capacity | Regional/family used-vCPU limits, SKU restrictions, surge needs | Request an approved quota/region change; never assume a smaller B-series system node works |
| Terraform provider socket failure on Windows | Localhost RPC/permission error | Run validation through the approved execution permission path; not an Azure auth fix |
| Backend 403 | Blob RBAC propagation, Entra data-plane token, firewall egress IP | Fix exact role/CIDR; do not enable keys or public blobs |
| State locked | Active pipeline and blob lease ID | Wait; only approve force-unlock after proving no writer exists |
| WIF issuer mismatch | Exact connection issuer/subject, tenant/client ID | Use returned connection fields; do not guess old/new formats |
| Token expires mid-apply | OIDC request-token/URI and connection-ID environment | Use renewable request flow; do not freeze one idToken |
| Apply rejects plan | Commit/run/definition, target, age, hashes, state serial | Create a new plan and obtain new approval; never bypass validation |
| Agent cannot reach API/storage | Static outbound IP vs API/storage allowlists | Use an approved routed self-hosted agent; avoid broad firewall ranges |
| Argo cannot fetch Git | repo-server logs, pod-to-Git route, URL, credential validity | Configure a reachable read-only repository integration; ARM WIF does not automatically authenticate Git |
| Stage changes unexpectedly | Repository branch ACLs, release PR and environment checks | Deny bypass/direct main pushes; verify snapshot digest matches tested Dev |
| CSI mount failure | Pod events, exact service-account subject, federation issuer, secret name, vault firewall | Fix identity/scopes/routing; never copy the secret value into Git as a workaround |
| HPA unknown metrics | Metrics API, CPU requests, metrics-server readiness | Inspect AKS metrics components and API availability |
| Quota prevents rollout | Namespace requests/limits, maxSurge and pod counts | Review capacity and values rather than removing quotas |
| Monitoring cost spike | Ingestion, container logs, quota behavior and DCR/config | Reduce approved collection scope; budget alerts do not stop billing |
| Destroy leaves resources | Cleanup report and original node RG inventory | Classify ownership/data retention, approve individual cleanup separately |

Use `kubectl --context CONTEXT -n NAMESPACE describe pod NAME`, events, rollout
status and application JSON logs. Collect minimal diagnostic data; do not print
tokens, actual secret files or sensitive Terraform plan JSON into public tickets.
