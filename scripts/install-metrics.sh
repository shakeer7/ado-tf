#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
require_local
version=$(python -c 'import json; print(json.load(open("versions.json"))["metrics_server"])')
kubectl --context kind-platform-lab apply -f "https://github.com/kubernetes-sigs/metrics-server/releases/download/v$version/components.yaml"
# Kind kubelet certificates are not signed for pod access. This exception is LOCAL ONLY.
kubectl --context kind-platform-lab -n kube-system patch deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl --context kind-platform-lab -n kube-system rollout status deployment/metrics-server --timeout=180s
