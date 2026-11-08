#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
cd "$REPO_ROOT"
docker info >/dev/null
image=$(python -c 'import json; print(json.load(open("versions.json"))["kind_node"])')
if ! kind get clusters | grep -qx platform-lab; then
  kind create cluster --name platform-lab --config kind/cluster.yaml --image "$image" --wait 180s
fi
require_local
kubectl --context kind-platform-lab wait --for=condition=Ready node --all --timeout=180s
