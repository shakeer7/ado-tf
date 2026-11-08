#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
cd "$REPO_ROOT"
directory=${1:?approved artifact}; operation=${2:-}
[[ -z "$operation" || "$operation" == --destroy ]] || exit 2
[[ "$BUILD_SOURCEBRANCH" == refs/heads/main && "$BUILD_REASON" == Manual ]] || exit 2
python scripts/backend-config.py
terraform -chdir=terraform/environments/shared-aks init -input=false -lockfile=readonly -backend-config="$REPO_ROOT/out/backend.hcl"
# Verification is repeated immediately before the only resource-changing operation.
args=(); if [[ "$operation" == --destroy ]]; then args+=(--destroy --same-run); fi
python scripts/plan_artifact.py verify "$directory" "${args[@]}"
mkdir -p reports
terraform -chdir=terraform/environments/shared-aks apply -input=false -lock-timeout=120s "$directory/plan.tfplan" | tee reports/terraform-execution.txt
terraform -chdir=terraform/environments/shared-aks output -json > reports/outputs.json
if [[ "$operation" == --destroy ]]; then
  python scripts/orphan_report.py "$directory/outputs-before.json" reports
else
  rg=$(terraform -chdir=terraform/environments/shared-aks output -raw platform_resource_group)
  cluster=$(terraform -chdir=terraform/environments/shared-aks output -raw cluster_name)
  az aks show -g "$rg" -n "$cluster" --query '{state:provisioningState,power:powerState.code,version:kubernetesVersion,nodeRG:nodeResourceGroup}' -o json > reports/aks-health.json
fi
