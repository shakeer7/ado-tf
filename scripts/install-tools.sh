#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .tools
v() { python -c "import json; print(json.load(open('versions.json'))['$1'])"; }
fetch() { curl --fail --silent --show-error --location --retry 3 "$1" -o "$2"; }
verify() {
  local archive=$1 sums=$2
  python - "$archive" "$sums" <<'PY'
import hashlib,sys
from pathlib import Path
archive, sums = map(Path, sys.argv[1:])
lines = [line.split()[0] for line in sums.read_text().splitlines() if archive.name in line]
if len(lines) != 1 or hashlib.sha256(archive.read_bytes()).hexdigest() != lines[0]:
    raise SystemExit('Checksum mismatch or missing entry: '+archive.name)
PY
}
tf=$(v terraform); helm=$(v helm); lint=$(v tflint); trivy=$(v trivy); kc=$(v kubeconform)
if [[ ! -x .tools/terraform ]]; then
  a="terraform_${tf}_linux_amd64.zip"; base="https://releases.hashicorp.com/terraform/$tf"
  fetch "$base/$a" ".tools/$a"; fetch "$base/terraform_${tf}_SHA256SUMS" .tools/tf.sums
  verify ".tools/$a" .tools/tf.sums; unzip -o -q ".tools/$a" -d .tools
fi
if [[ ! -x .tools/helm ]]; then
  a="helm-v${helm}-linux-amd64.tar.gz"; fetch "https://get.helm.sh/$a" ".tools/$a"
  fetch "https://get.helm.sh/$a.sha256sum" .tools/helm.sums; verify ".tools/$a" .tools/helm.sums
  tar -xzf ".tools/$a" -C .tools; cp .tools/linux-amd64/helm .tools/helm
fi
if [[ ! -x .tools/tflint ]]; then
  a=tflint_linux_amd64.zip; base="https://github.com/terraform-linters/tflint/releases/download/v$lint"
  fetch "$base/$a" ".tools/$a"; fetch "$base/checksums.txt" .tools/tflint.sums
  verify ".tools/$a" .tools/tflint.sums; unzip -o -q ".tools/$a" -d .tools
fi
if [[ ! -x .tools/trivy ]]; then
  a="trivy_${trivy}_Linux-64bit.tar.gz"; base="https://github.com/aquasecurity/trivy/releases/download/v$trivy"
  fetch "$base/$a" ".tools/$a"; fetch "$base/trivy_${trivy}_checksums.txt" .tools/trivy.sums
  verify ".tools/$a" .tools/trivy.sums; tar -xzf ".tools/$a" -C .tools
fi
if [[ ! -x .tools/kubeconform ]]; then
  a=kubeconform-linux-amd64.tar.gz; base="https://github.com/yannh/kubeconform/releases/download/v$kc"
  fetch "$base/$a" ".tools/$a"; fetch "$base/CHECKSUMS" .tools/kubeconform.sums
  verify ".tools/$a" .tools/kubeconform.sums; tar -xzf ".tools/$a" -C .tools
fi
echo "##vso[task.prependpath]$PWD/.tools"
if [[ ! -x .tools/kubectl ]]; then
  kubectl=$(v kubectl)
  fetch "https://dl.k8s.io/release/v$kubectl/bin/linux/amd64/kubectl" .tools/kubectl
  fetch "https://dl.k8s.io/release/v$kubectl/bin/linux/amd64/kubectl.sha256" .tools/kubectl.sha256
  python -c 'import hashlib,pathlib; p=pathlib.Path(".tools/kubectl"); assert hashlib.sha256(p.read_bytes()).hexdigest()==pathlib.Path(".tools/kubectl.sha256").read_text().strip()'
  chmod +x .tools/kubectl
fi
echo 'Local shell: export PATH="$PWD/.tools:$PATH"'
