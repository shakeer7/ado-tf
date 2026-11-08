#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
cd "$REPO_ROOT"
require_local
mkdir -p out
if [[ ! -d out/gitops.git ]]; then
  python scripts/export-gitops.py out/gitops-work
  git -C out/gitops-work init -b main
  git -C out/gitops-work add .
  git -C out/gitops-work -c user.name=Lab -c user.email=lab@localhost commit -m 'Initialize local GitOps release'
  git clone --bare out/gitops-work out/gitops.git
  git -C out/gitops-work remote add origin "$REPO_ROOT/out/gitops.git"
fi
# Receive-pack is disabled: the network endpoint exports this public sample read-only.
# Local pushes use the filesystem remote; no credentials or secrets belong here.
if [[ ! -f out/git-daemon.pid ]] || ! kill -0 "$(cat out/git-daemon.pid)" 2>/dev/null; then
  git daemon --reuseaddr --base-path="$REPO_ROOT/out" --export-all --listen=0.0.0.0 --port=9418 --detach --pid-file="$REPO_ROOT/out/git-daemon.pid" "$REPO_ROOT/out/gitops.git"
fi
python scripts/configure-argocd.py --repo-url "${LOCAL_GITOPS_URL:-git://host.docker.internal:9418/gitops.git}"
# Transfer application ownership from Helm to Argo by adopting matching objects;
# do not run helm upgrades again while Argo owns these releases.
kubectl --context kind-platform-lab apply -f out/argocd
echo 'Local commits: git -C out/gitops-work commit; git -C out/gitops-work push origin main'
