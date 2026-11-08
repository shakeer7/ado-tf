# Independent GitOps repository

Export this directory using scripts/export-gitops.py, initialize Git and publish
to your chosen Git repository only after approval. Argo reads this repository;
the infrastructure repository pipelines create release PRs against it.

The seeded local release uses a versioned image tag loaded into Kind. Azure CI
replaces image references with a registry digest. Protect main with required
reviewers/build checks. Limit pipeline Build Service access to create branches
and PRs; deny policy bypass, force pushes and direct writes to main.

Dev and Stage values are independent. Promotion copies the tested Dev digest,
and rollback reverts a release commit. Never place credentials or secret values
in either repository. The local read-only Git daemon is for this sample only.
