# Validation evidence

Run: 2026-11-07T07:09:42.5959196+05:30. All cloud checks below are static or use mock providers.

| Check | Status | Log |
|---|---|---|
| terraform-fmt | PASS | reports/terraform-fmt.log |
| init-bootstrap | PASS | reports/init-bootstrap.log |
| validate-bootstrap | PASS | reports/validate-bootstrap.log |
| init-terraform-environments-shared-aks | PASS | reports/init-terraform-environments-shared-aks.log |
| validate-terraform-environments-shared-aks | PASS | reports/validate-terraform-environments-shared-aks.log |
| init-terraform-environments-cluster-services | PASS | reports/init-terraform-environments-cluster-services.log |
| validate-terraform-environments-cluster-services | PASS | reports/validate-terraform-environments-cluster-services.log |
| terraform-safety | PASS | reports/terraform-safety.log |
| terraform-acr-module | PASS | reports/terraform-acr-module.log |
| tflint | PASS | reports/tflint.log |
| helm-dev | PASS | reports/helm-dev.log |
| schema-dev | PASS | reports/schema-dev.log |
| helm-stage | PASS | reports/helm-stage.log |
| schema-stage | PASS | reports/schema-stage.log |
| schema-platform | PASS | reports/schema-platform.log |
| checkov-bootstrap | PASS | reports/checkov-bootstrap.log |
| trivy-bootstrap | PASS | reports/trivy-bootstrap.log |
| checkov-terraform-modules | PASS | reports/checkov-terraform-modules.log |
| trivy-terraform-modules | PASS | reports/trivy-terraform-modules.log |
| checkov-out | PASS | reports/checkov-out.log |
| trivy-out | PASS | reports/trivy-out.log |
| checkov-kubernetes | PASS | reports/checkov-kubernetes.log |
| trivy-kubernetes | PASS | reports/trivy-kubernetes.log |
| checkov-dockerfile | PASS | reports/checkov-dockerfile.log |
| trivy-secrets | PASS | reports/trivy-secrets.log |
| trivy-dependencies | PASS | reports/trivy-dependencies.log |
| application-and-safety-tests | PASS | reports/application-and-safety-tests.log |

No Azure resource-changing operation was executed. Azure DevOps server compilation, protected checks, WIF exchange, Key Vault CSI access and Azure deployment remain unverified.

The original validation did not establish image builds, AKS rollout or Argo reconciliation. AKS is now the only supported deployment target. Follow the Azure runbook for integration validation. The results above predate removal of the alternate deployment path.

A clean scanner result includes documented, resource-scoped lab exceptions. See security-exceptions.md. Logs and JSON scanner reports are retained locally under reports/ and excluded from Git.

## Final follow-up checks

- 23 application/repository tests passed, including an actual Uvicorn HTTP startup, immutable promotion and Git revert. One upstream Starlette/httpx deprecation warning remains.
- Final shared-root mock plan tests: 3 passed (default off, approval required, approved two-node shape). The separate ACR module mock test also passed. No real provider apply was executed.
- Bootstrap provider validation passed after isolating pipeline identities and bootstrap state, adding the deletion lock and constraining firewall inputs. Its Checkov scan passed 6 checks with 4 documented resource-scoped exceptions.
- PowerShell and Python syntax checks and pipeline/generated Argo definition parsing passed.
- Argo CD chart 10.14.0 rendered successfully with the configured 3.6.1 application image. Installation/reconciliation remains unverified without a healthy Docker engine.

## Azure-only follow-up - 8 November 2026

After removal of the alternate deployment path:

- 29 application/repository tests passed, including registry digest requirements,
  rejection of cached-image pull policies, matching chart copies and explicit
  approved AKS context guards. One upstream Starlette/httpx warning remains.
- Terraform recursive formatting and cluster-services provider validation passed.
- Stage Helm lint with the static image fixture passed. Tests also rendered the
  optional workload identity, autoscaling and disruption budget resources.
- PowerShell parsing and Bash syntax checks passed; pipeline YAML parsing passed.
- No AKS deployment, registry push, Argo reconciliation or live Azure operation
  was performed. The earlier scanner results above were not rerun in this change.
