param([switch]$Cluster)
$ErrorActionPreference = 'Stop'
$root=Split-Path $PSScriptRoot -Parent
Set-Location $root
$env:PYTHONPATH="$root/.tools/pydeps"
$python='C:\Program Files\Microsoft SDKs\Azure\CLI2\python.exe'
New-Item -ItemType Directory -Force reports,out | Out-Null
$results=[System.Collections.Generic.List[object]]::new()
function Check([string]$Name,[string]$Command,[string[]]$Arguments) {
    $file="reports/$Name.log"
    try {
        & $Command @Arguments *> $file
        $status=if ($LASTEXITCODE -eq 0) {'PASS'} else {'FAIL'}
    } catch { $_ | Out-File $file; $status='FAIL' }
    $results.Add([pscustomobject]@{name=$Name;status=$status;log=$file})
    Write-Output "$status $Name"
}
Check terraform-fmt ./.tools/terraform.exe @('fmt','-recursive','-check')
foreach ($target in @('bootstrap','terraform/environments/shared-aks','terraform/environments/cluster-services')) {
    $name=$target.Replace('/','-')
    Check "init-$name" ./.tools/terraform.exe @("-chdir=$target",'init','-backend=false','-input=false','-lockfile=readonly')
    Check "validate-$name" ./.tools/terraform.exe @("-chdir=$target",'validate','-no-color')
}
Check terraform-safety ./.tools/terraform.exe @('-chdir=terraform/environments/shared-aks','test','-no-color')
Check init-acr-module ./.tools/terraform.exe @('-chdir=terraform/modules/acr','init','-backend=false','-input=false','-lockfile=readonly')
Check terraform-acr-module ./.tools/terraform.exe @('-chdir=terraform/modules/acr','test','-no-color')
Check tflint ./.tools/tflint.exe @('--recursive','--config',"$root/.tflint.hcl")
foreach ($namespace in @('dev','stage')) {
    Check "helm-$namespace" ./.tools/helm.exe @('lint','helm/sample-application','-f',"helm/sample-application/values-$namespace.yaml",'--strict')
    & ./.tools/helm.exe template sample-application helm/sample-application --namespace $namespace -f "helm/sample-application/values-$namespace.yaml" | Set-Content -Encoding utf8 "out/$namespace.yaml"
    if ($LASTEXITCODE) { throw 'Helm rendering failed' }
    Check "schema-$namespace" ./.tools/kubeconform.exe @('-strict','-summary','-kubernetes-version','1.37.0',"out/$namespace.yaml")
}
Check schema-platform ./.tools/kubeconform.exe @('-strict','-summary','-kubernetes-version','1.37.0','kubernetes')
$env:PYTHONPATH="$root/.tools/scan-deps"
foreach ($target in @('bootstrap','terraform/modules','out','kubernetes')) {
    $name=$target.Replace('/','-')
    Check "checkov-$name" $python @('.tools/scan-deps/bin/checkov','--config-file','.checkov.yaml','--directory',$target)
    Check "trivy-$name" ./.tools/trivy.exe @('config','--severity','HIGH,CRITICAL','--exit-code','1',$target)
}
Check checkov-dockerfile $python @('.tools/scan-deps/bin/checkov','--config-file','.checkov.yaml','--file','application/Dockerfile')
Check trivy-secrets ./.tools/trivy.exe @('fs','--scanners','secret','--exit-code','1','--skip-dirs','.tools','--skip-dirs','.git','--skip-dirs','reports','.')
Check trivy-dependencies ./.tools/trivy.exe @('fs','--scanners','vuln','--severity','HIGH,CRITICAL','--exit-code','1','application')
$env:PYTHONPATH="$root/.tools/pydeps"
Check application-and-safety-tests $python @('-m','pytest','application/tests','tests','-q')
if ($Cluster) {
    Check kind-connection ./.tools/kubectl.exe @('--context','kind-platform-lab','cluster-info')
    if (($results | Where-Object name -eq kind-connection).status -eq 'PASS') {
        foreach ($namespace in @('dev','stage')) { Check "kubectl-dry-run-$namespace" ./.tools/kubectl.exe @('--context','kind-platform-lab','apply','--dry-run=client','-f',"out/$namespace.yaml") }
    }
}
$results | ConvertTo-Json | Set-Content -Encoding utf8 reports/validation.json
$lines=@('# Validation evidence','',"Run: $([DateTimeOffset]::Now.ToString('o')). All cloud checks below are static or use mock providers.",'','| Check | Status | Log |','|---|---|---|')
foreach ($result in $results) { $lines += "| $($result.name) | $($result.status) | $($result.log) |" }
$lines += @('','No Azure resource-changing operation was executed. Azure DevOps server compilation, protected checks, WIF exchange, Key Vault CSI access and Azure deployment remain unverified.','',
'Docker engine health checks timed out after Docker Desktop was launched; no targetable Docker window was available through Computer Use. No image build, Kind cluster creation, rollout, Argo reconciliation or live cluster dry-run was claimed. Follow the local runbook after the engine is healthy.','',
'A clean scanner result includes documented, resource-scoped lab exceptions. See security-exceptions.md. Logs and JSON scanner reports are retained locally under reports/ and excluded from Git.')
$lines | Set-Content -Encoding utf8 docs/validation.md
if ($results | Where-Object status -eq FAIL) { exit 1 }
