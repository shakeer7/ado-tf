param([string]$Python = 'C:\Program Files\Microsoft SDKs\Azure\CLI2\python.exe')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$v = Get-Content "$root/versions.json" | ConvertFrom-Json
$toolsDir = Join-Path $root '.tools'
New-Item -ItemType Directory -Force $toolsDir | Out-Null
function Get-VerifiedZip($url, $sumUrl, $name, $exePath) {
    $zip = Join-Path $toolsDir "$name.zip"
    Invoke-WebRequest $url -OutFile $zip
    $sum = (Invoke-WebRequest $sumUrl).Content
    if ($sum -is [byte[]]) { $sum = [System.Text.Encoding]::UTF8.GetString($sum) }
    $file = ($url -split '/')[-1]
    $line = ($sum -split "`n" | Where-Object { $_ -match [regex]::Escape($file) } | Select-Object -First 1)
    if (-not $line -and $sum.Trim() -match '^[a-fA-F0-9]{64}$') { $line = $sum.Trim() }
    if (-not $line) { throw "No checksum found for $file" }
    $expected = ($line.Trim() -split '\s+')[0].ToLower()
    $actual = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
    if ($expected -ne $actual) { throw "Checksum mismatch: $name" }
    Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $toolsDir $name) -Force
    Copy-Item (Join-Path $toolsDir "$name/$exePath") (Join-Path $toolsDir "$name.exe") -Force
}
Get-VerifiedZip "https://releases.hashicorp.com/terraform/$($v.terraform)/terraform_$($v.terraform)_windows_amd64.zip" "https://releases.hashicorp.com/terraform/$($v.terraform)/terraform_$($v.terraform)_SHA256SUMS" terraform terraform.exe
Get-VerifiedZip "https://get.helm.sh/helm-v$($v.helm)-windows-amd64.zip" "https://get.helm.sh/helm-v$($v.helm)-windows-amd64.zip.sha256sum" helm windows-amd64/helm.exe
Get-VerifiedZip "https://github.com/terraform-linters/tflint/releases/download/v$($v.tflint)/tflint_windows_amd64.zip" "https://github.com/terraform-linters/tflint/releases/download/v$($v.tflint)/checksums.txt" tflint tflint.exe
Get-VerifiedZip "https://github.com/aquasecurity/trivy/releases/download/v$($v.trivy)/trivy_$($v.trivy)_windows-64bit.zip" "https://github.com/aquasecurity/trivy/releases/download/v$($v.trivy)/trivy_$($v.trivy)_checksums.txt" trivy trivy.exe
Get-VerifiedZip "https://github.com/yannh/kubeconform/releases/download/v$($v.kubeconform)/kubeconform-windows-amd64.zip" "https://github.com/yannh/kubeconform/releases/download/v$($v.kubeconform)/CHECKSUMS" kubeconform kubeconform.exe
Invoke-WebRequest "https://dl.k8s.io/release/v$($v.kubectl)/bin/windows/amd64/kubectl.exe" -OutFile "$toolsDir/kubectl.exe"
$kubectlSum = (Invoke-WebRequest "https://dl.k8s.io/release/v$($v.kubectl)/bin/windows/amd64/kubectl.exe.sha256").Content
if ($kubectlSum -is [byte[]]) { $kubectlSum = [System.Text.Encoding]::UTF8.GetString($kubectlSum) }
if ((Get-FileHash "$toolsDir/kubectl.exe").Hash.ToLower() -ne $kubectlSum.Trim()) { throw 'Kubectl checksum mismatch' }
Invoke-WebRequest "https://kind.sigs.k8s.io/dl/v$($v.kind)/kind-windows-amd64" -OutFile "$toolsDir/kind.exe"
$kindSum = (Invoke-WebRequest "https://kind.sigs.k8s.io/dl/v$($v.kind)/kind-windows-amd64.sha256sum").Content
if ($kindSum -is [byte[]]) { $kindSum = [System.Text.Encoding]::UTF8.GetString($kindSum) }
$expected = ($kindSum.Trim() -split '\s+')[0]
if ((Get-FileHash "$toolsDir/kind.exe").Hash.ToLower() -ne $expected.ToLower()) { throw 'Kind checksum mismatch' }
& $Python -m pip install --target "$toolsDir/pydeps" "pip-tools==$($v.pip_tools)" "pytest==$($v.pytest)" "httpx==$($v.httpx)" "PyYAML==$($v.pyyaml)" "fastapi==$($v.fastapi)" "uvicorn==$($v.uvicorn)"
if ($LASTEXITCODE) { throw 'App dependencies failed' }
& $Python -m pip install --target "$toolsDir/scan-deps" -c "$root/tools/checkov.constraints.txt" "checkov==$($v.checkov)"
if ($LASTEXITCODE) { throw 'Dependency installation failed' }
Write-Output 'Workspace tools installed. No cloud resources were modified.'
