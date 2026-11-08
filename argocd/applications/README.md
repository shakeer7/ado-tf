# Generate Applications

`python scripts/configure-argocd.py --repo-url YOUR_REACHABLE_GITOPS_URL`
creates executable Dev/Stage Applications and an AppProject in out/argocd. Both
environments reconcile Git. Stage release changes require a protected promotion
environment and reviewed PR. Do not use Argo UI changes as release approval.

Use a repository reachable from AKS with securely configured read-only access.
The seed has no image release: merge a real Dev registry digest before enabling
sample-dev, and merge the first approved Stage promotion before enabling
sample-stage. Static validation image fixtures must never be deployed.
