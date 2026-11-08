#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
cd "$REPO_ROOT"
destination=${1:?artifact directory}; operation=${2:-}
[[ -z "$operation" || "$operation" == --destroy ]] || exit 2
[[ "$BUILD_SOURCEBRANCH" == refs/heads/main && "$BUILD_REASON" == Manual ]] || { echo 'Only trusted manual main runs may plan Azure'; exit 2; }
[[ "$STATE_KEY" == shared-aks.tfstate ]] || exit 2
mkdir -p "$destination" out
python scripts/backend-config.py
terraform -chdir=terraform/environments/shared-aks init -input=false -lockfile=readonly -backend-config="$REPO_ROOT/out/backend.hcl"
az resource list --resource-group "$TF_VAR_resource_group_name" -o json > "$destination/inventory-before.json"
terraform -chdir=terraform/environments/shared-aks output -json > "$destination/outputs-before.json"
terraform -chdir=terraform/environments/shared-aks plan ${operation:+-destroy} -input=false -lock-timeout=120s -out="$destination/plan.tfplan"
terraform -chdir=terraform/environments/shared-aks show -json "$destination/plan.tfplan" > "$destination/plan.json"
terraform -chdir=terraform/environments/shared-aks show -no-color "$destination/plan.tfplan" > "$destination/plan.txt"
cp terraform/environments/shared-aks/.terraform.lock.hcl "$destination/provider.lock.hcl"
python - "$destination/backend.json" <<'PY'
import sys,json
sys.path.insert(0,'scripts')
from plan_artifact import target
open(sys.argv[1],'w').write(json.dumps(target(),indent=2)+'\n')
PY
python scripts/plan_artifact.py create "$destination" ${operation:+--destroy}
