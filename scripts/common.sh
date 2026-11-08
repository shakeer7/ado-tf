#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export PATH="$REPO_ROOT/.tools:$PATH"
require_target() {
  : "${KUBE_CONTEXT:?Set the intended Kubernetes context explicitly}"
  : "${APPROVED_AKS_CONTEXT:?Set the approved AKS context explicitly}"
  [[ "$KUBE_CONTEXT" == "$APPROVED_AKS_CONTEXT" ]] || { echo 'Unapproved Kubernetes context'; exit 2; }
  kubectl --context "$KUBE_CONTEXT" cluster-info >/dev/null
}
