# Azure application rollback and promotion

Application releases are owned by Argo CD on AKS. Use scanned registry images
referenced by immutable digests and reviewed PRs in the independent GitOps repo.
The unit suite tests promotion and Git revert in an isolated temporary repository;
these tests do not establish that AKS or Argo reconciliation occurred.

## Release and promotion

1. Run application CI to test, build and scan the image. After approval, publish
   it to ACR and merge the Dev release PR through repository branch policies.
2. Wait for `sample-dev` to be Synced/Healthy and verify rollout, `/health/ready`
   and `/api/info` on the explicit approved AKS context.
3. Run the promotion pipeline. It snapshots the tested Dev digest before Stage
   approval, then proposes that same digest in a Stage PR. Preserve Stage's
   replica and PodDisruptionBudget values.
4. Merge the reviewed Stage PR and verify Stage reconciliation and health.

## Rollback

Identify the failing release commit in the GitOps repository. Create a branch,
revert that commit, and open a PR using the normal reviewers and build checks.
After merge, Argo reconciles the previously declared image digest. Verify rollout,
readiness and release metadata. Confirm the previous image still exists in ACR.

Do not use Argo revision rollback while auto-sync still points at a bad Git
commit. Git remains the source of truth; direct Helm upgrades or `kubectl rollout
undo` would conflict with Argo ownership. Review live drift/failure experiments
separately before changing an Azure workload.

Infrastructure rollback uses a separately reviewed Terraform plan. State-file
restoration is disaster recovery, not the normal infrastructure rollback method.
