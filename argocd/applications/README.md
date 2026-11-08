# Generate Applications

`python scripts/configure-argocd.py --repo-url YOUR_REACHABLE_GITOPS_URL`
creates executable Dev/Stage Applications and an AppProject in out/argocd. Both
environments reconcile Git. Stage release changes require a protected promotion
environment and reviewed PR. Do not use Argo UI changes as release approval.
