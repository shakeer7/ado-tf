#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
if [[ "${1:-}" != local ]]; then
  echo 'Azure cleanup is available only through pipelines/destroy.yml and protected approval.'; exit 2
fi
[[ "${CONFIRM_LOCAL_DELETE:-}" == platform-lab ]] || { echo 'Set CONFIRM_LOCAL_DELETE=platform-lab to delete only the local lab cluster'; exit 2; }
kind get clusters | grep -qx platform-lab
kubectl --context kind-platform-lab get all -A
kind delete cluster --name platform-lab
