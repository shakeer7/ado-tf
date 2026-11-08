#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export PATH="$REPO_ROOT/.tools:$PATH"
require_local() {
  [[ "${KUBE_CONTEXT:-kind-platform-lab}" == kind-platform-lab ]] || { echo 'Only the lab Kind context is allowed'; exit 2; }
  kubectl --context kind-platform-lab cluster-info >/dev/null
}
require_target() {
  : "${KUBE_CONTEXT:?Set the intended Kubernetes context explicitly}"
  [[ "$KUBE_CONTEXT" == kind-platform-lab || "$KUBE_CONTEXT" == "${APPROVED_AKS_CONTEXT:-__not_set__}" ]] || { echo 'Unapproved Kubernetes context'; exit 2; }
  kubectl --context "$KUBE_CONTEXT" cluster-info >/dev/null
}
