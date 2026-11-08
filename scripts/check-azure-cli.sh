#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
expected=$(python -c 'import json,sys; print(json.load(open(sys.argv[1]))["azure_cli"])' "$root/versions.json")
actual=$(az version --output json | python -c 'import json,sys; print(json.load(sys.stdin)["azure-cli"])')
if [[ "$actual" != "$expected" ]]; then
  echo "Azure deployment agents require Azure CLI $expected; found $actual. Provision the pinned agent toolchain before continuing."
  exit 2
fi
