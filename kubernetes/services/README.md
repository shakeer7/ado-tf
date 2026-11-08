# ClusterIP only

The chart owns its Service. Local access uses kubectl port-forward; namespace
quotas prohibit LoadBalancer services. Public application exposure is not enabled.
