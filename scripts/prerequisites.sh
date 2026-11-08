#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
missing=0
for cmd in python terraform docker kind kubectl helm git tflint checkov trivy kubeconform; do
  if ! command -v "$cmd" >/dev/null; then echo "MISSING $cmd"; missing=1; fi
done
python --version; terraform version; helm version --short
docker info >/dev/null || { echo 'Start Docker Desktop with Linux containers'; missing=1; }
exit "$missing"
