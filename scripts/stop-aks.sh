#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
bash "$REPO_ROOT/scripts/check-azure-cli.sh"
: "${AZURE_RESOURCE_GROUP:?}" "${AKS_NAME:?}" "${CONFIRM_AZURE_ACTION:?Set STOP followed by the exact cluster name}"
[[ "$CONFIRM_AZURE_ACTION" == "STOP $AKS_NAME" ]] || exit 2
az aks show -g "$AZURE_RESOURCE_GROUP" -n "$AKS_NAME" --query '{name:name,state:powerState.code,nodeRG:nodeResourceGroup}' -o table
az aks stop -g "$AZURE_RESOURCE_GROUP" -n "$AKS_NAME"
echo 'Disks, public IPs and other retained services can remain billable while stopped.'
