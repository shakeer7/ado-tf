$env:PYTHONPATH = Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/scan-deps'
$env:LOG_LEVEL = 'ERROR'
& 'C:\Program Files\Microsoft SDKs\Azure\CLI2\python.exe' (Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/scan-deps/bin/checkov') @args
exit $LASTEXITCODE
