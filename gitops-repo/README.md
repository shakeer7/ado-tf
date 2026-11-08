# Independent Azure GitOps repository

Export this directory with `scripts/export-gitops.py`, initialize Git and publish
the repository through your approved setup process. Argo CD on AKS reads it;
the infrastructure repository pipelines create release PRs against it.

The seed contains no deployable image by default. Before enabling an Application,
merge a release PR with a real registry repository, immutable SHA256 digest,
version and timestamp in that environment's values file. The application pipeline
creates the first Dev release; approved promotion creates the first Stage release.
The integrated publication pipeline uses ACR, which must be enabled first.

Protect main with reviewers and build validation. Grant the pipeline Build
Service only the required read/branch/PR permissions; deny policy bypass, force
pushes and direct main writes. Promotion copies the tested Dev digest while
preserving Stage replica/PDB settings. Rollback reverts a release commit through
a reviewed PR. Never store credentials or secret values in either repository.
