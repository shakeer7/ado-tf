#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
cd "$REPO_ROOT"
mkdir -p out reports
terraform fmt -recursive -check
for root in bootstrap terraform/environments/shared-aks terraform/environments/cluster-services; do
  terraform -chdir="$root" init -backend=false -input=false -lockfile=readonly
  terraform -chdir="$root" validate
done
terraform -chdir=terraform/environments/shared-aks test
terraform -chdir=terraform/modules/acr init -backend=false -input=false
terraform -chdir=terraform/modules/acr test
tflint --init
tflint --recursive --config="$REPO_ROOT/.tflint.hcl"
for env in dev stage; do
  helm lint helm/sample-application -f "helm/sample-application/values-$env.yaml" -f tests/fixtures/image.yaml --strict
  helm template sample-application helm/sample-application --namespace "$env" -f "helm/sample-application/values-$env.yaml" -f tests/fixtures/image.yaml > "out/$env.yaml"
  kubeconform -strict -summary -kubernetes-version 1.37.0 "out/$env.yaml"
done
for folder in bootstrap terraform/modules out kubernetes; do
  checkov --config-file .checkov.yaml --directory "$folder"
done
checkov --config-file .checkov.yaml --file application/Dockerfile
for folder in bootstrap terraform/modules out kubernetes; do
  trivy config --severity HIGH,CRITICAL --exit-code 1 "$folder"
done
trivy fs --scanners secret --exit-code 1 --skip-dirs .tools --skip-dirs .git .
kubeconform -strict -summary -kubernetes-version 1.37.0 kubernetes
python -m pytest application/tests tests
if [[ "${VALIDATE_CLUSTER:-false}" == true ]]; then
  require_target
  kubectl --context "$KUBE_CONTEXT" apply --dry-run=client -f kubernetes/namespaces
  for env in dev stage; do
    kubectl --context "$KUBE_CONTEXT" apply --dry-run=client -f "out/$env.yaml"
  done
else
  echo 'SKIP kubectl dry-run: no explicit configured cluster requested'
fi
