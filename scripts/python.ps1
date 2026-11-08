# Workspace-only dependencies; leaves the Azure CLI installation untouched.
$env:PYTHONPATH = Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/pydeps'
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\python.exe' @args
exit $LASTEXITCODE
