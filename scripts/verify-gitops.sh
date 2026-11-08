#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
require_target
env_name=${1:?dev or stage}
[[ "$env_name" == dev || "$env_name" == stage ]] || exit 2
# Polling permits the reviewed release PR to merge. No automatic merge is performed.
for i in $(seq 1 60); do
  observed=$(kubectl --context "$KUBE_CONTEXT" -n "$env_name" get configmap sample-application -o jsonpath='{.data.APP_VERSION}' 2>/dev/null || true)
  observed_image=$(kubectl --context "$KUBE_CONTEXT" -n "$env_name" get deployment sample-application -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)
  if [[ ( -z "${EXPECTED_VERSION:-}" || "$observed" == "$EXPECTED_VERSION" ) && ( -z "${EXPECTED_IMAGE:-}" || "$observed_image" == "$EXPECTED_IMAGE" ) ]]; then break; fi
  if [[ "$i" == 60 ]]; then echo 'Release not reconciled within 10 minutes'; exit 1; fi
  sleep 10
done
kubectl --context "$KUBE_CONTEXT" -n "$env_name" rollout status deployment/sample-application --timeout=180s
kubectl --context "$KUBE_CONTEXT" -n "$env_name" exec deployment/sample-application -- python -c \
  'import json,urllib.request; r=json.load(urllib.request.urlopen("http://127.0.0.1:8080/health/ready")); assert r["status"]=="ready"'
if [[ -n "${EXPECTED_VERSION:-}" ]]; then
  kubectl --context "$KUBE_CONTEXT" -n "$env_name" exec deployment/sample-application -- python -c \
    'import json,urllib.request,sys; r=json.load(urllib.request.urlopen("http://127.0.0.1:8080/api/info")); assert r["version"]==sys.argv[1]' "$EXPECTED_VERSION"
fi
kubectl --context "$KUBE_CONTEXT" -n "$env_name" auth can-i get secrets --as="system:serviceaccount:$env_name:sample-application" | grep -qx no
