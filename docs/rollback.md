# Release, failure, rollback and drift exercises

Run these only against the dedicated local lab. The unit suite also tests release
promotion and a real local Git revert in an isolated temporary repository. Those
tests are not evidence that a Kubernetes rollout or Argo reconciliation occurred.

## Helm-only exercise before Argo adoption

Build a second immutable local tag with scripts/deploy-local.sh 0.2.0-local (or
lab.ps1 deploy -Version 0.2.0-local). Inspect `/api/info`. For a failed rollout,
temporarily deploy a nonexistent tag with a separate `helm upgrade` using the
Kind context; observe ImagePullBackOff, readiness and rollout timeout. Do not
delete healthy replicas. Use `helm history` and `helm rollback` to return to a
known release, then verify HTTP readiness. Helm rollback is only for Helm-owned
releases; after Argo adoption, use Git revert instead.

## GitOps exercise

1. Build platform-sample:0.2.0-local and load it with
   `kind load docker-image platform-sample:0.2.0-local --name platform-lab`.
2. In out/gitops-work/helm/sample-application/values-dev.yaml set
   image.repository=platform-sample, image.tag=0.2.0-local, image.digest="", version
   0.2.0-local and a release timestamp. Commit and push **to the local filesystem
   origin only**. Wait for sample-dev Synced/Healthy and verify `/api/info`.
3. Commit a nonexistent local image tag to Dev. Observe Argo Degraded/Progressing,
   pod events and an ImagePullBackOff while the rolling strategy retains healthy
   replicas. Record the failed release commit SHA.
4. In the local GitOps checkout use `git revert FAILED_SHA` and push main to the
   local origin. Argo reconciles the previous image; verify rollout and health.
5. To demonstrate drift, scale the Dev Deployment to two in the dedicated Kind
   context. Observe Argo self-heal restoring Git's one replica. This is an
   intentionally local operational exercise, not the application release method.
6. Promote the tested Dev release metadata into Stage values after reviewing the
   tests. Preserve Stage replicas/PDB values. Cloud promotion uses the protected
   pipeline and review PR; the same digest is copied from its tested snapshot.

In Azure, use scanned registry digests, a reviewed Git revert PR and the same
branch policies as a forward release. Do not use Argo revision rollback with
auto-sync still pointing at a bad Git commit: Git remains the source of truth.
Infrastructure rollback is a separately reviewed Terraform plan, not a state-file
restore or an application `kubectl rollout undo`. State restore is disaster recovery.
