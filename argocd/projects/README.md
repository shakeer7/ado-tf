# Restricted project

The configure script emits an exact repository allowlist, only dev/stage
destinations and an explicit namespace-object allowlist. No cluster-scoped
resources, namespaces, Kubernetes Secrets or Terraform resources are permitted.
