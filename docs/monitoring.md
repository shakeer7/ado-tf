# Monitoring

Locally install pinned metrics-server only on Kind. `kubectl top pods -A`,
`kubectl top nodes`, JSON stdout logs and `/health/live`, `/health/ready` and
`/api/info` provide basic visibility. Prometheus/Grafana are optional future
extensions and are not depicted as deployed components.

Azure Log Analytics/Container Insights defaults off. If approved, the workspace
uses 30-day retention and a 0.1-GB daily ingestion quota. The quota is not an
instant spending cap. Apply monitoring/container-azm-ms-agentconfig.yaml to exclude
system/Argo namespaces from application stdout/stderr collection. Collection
settings and Azure's supported schema must be verified on the chosen AKS version.
The optional monitoring module accepts cluster_id to create a paid CPU metric
alert; no alert receiver/action group is provisioned. The shared root can enable
the separately defined CPU alert. Without an action group the rule records state
but does not send notifications. Review ingestion, retention, alert evaluation,
notification and data-transfer meters before enabling paid monitoring.

Example KQL, after confirming these tables are collected:

```kusto
// Container failure events
KubeEvents
| where TimeGenerated > ago(1h) and Reason in ("BackOff", "Failed", "Unhealthy")
| project TimeGenerated, Namespace, Name, Reason, Message

// Restart count: cumulative inventory snapshots, not a sum of all snapshots
KubePodInventory
| where TimeGenerated > ago(1h)
| summarize arg_max(TimeGenerated, *) by ClusterId, Namespace, Name, ContainerName
| where ContainerRestartCount > 0
| project Namespace, Name, ContainerName, ContainerRestartCount

// CPU nanocores and memory bytes when Perf is collected
Perf
| where TimeGenerated > ago(1h) and ObjectName == "K8SContainer"
| where CounterName in ("cpuUsageNanoCores", "memoryWorkingSetBytes")
| summarize Average=avg(CounterValue) by CounterName, InstanceName, bin(TimeGenerated, 5m)

// Structured app errors
ContainerLogV2
| where TimeGenerated > ago(1h) and PodNamespace in ("dev", "stage")
| extend Event=parse_json(LogMessage)
| where toint(Event.status) >= 500 or tostring(Event.level) == "ERROR"
| project TimeGenerated, PodNamespace, PodName, Event
```

Do not claim an empty query proves health if the table/collection is disabled.
Keep secret values out of logs and set appropriate log RBAC and retention.
