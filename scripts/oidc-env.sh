#!/usr/bin/env bash
# Source inside AzureCLI@2, addSpnToEnvironment:true. Never enable shell tracing.
set -euo pipefail
bash scripts/check-azure-cli.sh
: "${servicePrincipalId:?WIF service connection required}" "${tenantId:?Tenant missing}"
: "${SYSTEM_ACCESSTOKEN:?Azure DevOps OAuth token required}" "${SYSTEM_OIDCREQUESTURI:?OIDC request URL required}" "${SERVICE_CONNECTION_ID:?Service connection ID required}"
export ARM_CLIENT_ID="$servicePrincipalId" ARM_TENANT_ID="$tenantId"
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
export ARM_USE_OIDC=true ARM_USE_AZUREAD=true
export ARM_OIDC_REQUEST_TOKEN="$SYSTEM_ACCESSTOKEN"
export ARM_OIDC_REQUEST_URL="$SYSTEM_OIDCREQUESTURI"
export ARM_ADO_PIPELINE_SERVICE_CONNECTION_ID="$SERVICE_CONNECTION_ID"
export ARM_OIDC_AZURE_SERVICE_CONNECTION_ID="$SERVICE_CONNECTION_ID"
export TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
export TF_VAR_enable_azure=true TF_VAR_deployment_approved=true TF_VAR_cost_acknowledged=true
