#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
cd "$REPO_ROOT"
require_target
version=$(python -c 'import json; print(json.load(open("versions.json"))["argocd_chart"])')
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update argo
helm upgrade --install argocd argo/argo-cd --version "$version" --namespace argocd --create-namespace \
  --kube-context "$KUBE_CONTEXT" -f argocd/installation/values.yaml --wait --timeout 600s
echo 'Argo CD is ClusterIP only. Port-forward svc/argocd-server 8443:443 in namespace argocd.'
