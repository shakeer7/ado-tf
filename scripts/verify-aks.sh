#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
: "${AZURE_RESOURCE_GROUP:?}" "${AKS_NAME:?}"
az aks show -g "$AZURE_RESOURCE_GROUP" -n "$AKS_NAME" --query '{state:provisioningState,power:powerState.code,version:kubernetesVersion,nodeRG:nodeResourceGroup}' -o json
if [[ -n "${KUBE_CONTEXT:-}" ]]; then
  require_target
  kubectl --context "$KUBE_CONTEXT" get nodes -o wide
  kubectl --context "$KUBE_CONTEXT" get pods -A
  kubectl --context "$KUBE_CONTEXT" get networkpolicy -A
  kubectl --context "$KUBE_CONTEXT" get --raw='/readyz'
fi
