#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
cd "$REPO_ROOT"
require_local
release=${1:-0.1.0-local}
[[ "$release" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}$ && "$release" != latest ]] || exit 2
docker build -t "platform-sample:$release" application
# Kind nodes do not share the host Docker image store. Load into every node.
kind load docker-image "platform-sample:$release" --name platform-lab
for folder in namespaces resource-quotas network-policies rbac; do
  kubectl --context kind-platform-lab apply -f "kubernetes/$folder"
done
for env in dev stage; do
  helm upgrade --install sample-application helm/sample-application --kube-context kind-platform-lab --namespace "$env" \
    -f "helm/sample-application/values-$env.yaml" --set-string "image.tag=$release" \
    --set-string "version=$release" --set-string "deployedAt=$(date -u +%FT%TZ)" --wait --timeout 180s
  KUBE_CONTEXT=kind-platform-lab EXPECTED_VERSION="$release" bash scripts/verify-gitops.sh "$env"
done
echo 'Open the app: kubectl --context kind-platform-lab -n dev port-forward svc/sample-application 8080:80'
