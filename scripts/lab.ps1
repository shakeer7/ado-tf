param(
    [ValidateSet('create','deploy','argocd','metrics','gitops','verify','cleanup')][string]$Action = 'verify',
    [string]$Version = '0.1.0-local',
    [string]$Confirmation = ''
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$env:PATH = "$root/.tools;$root/.tools/pydeps/bin;" + $env:PATH
$env:PYTHONPATH = "$root/.tools/pydeps"
$python = 'C:\Program Files\Microsoft SDKs\Azure\CLI2\python.exe'
$context = 'kind-platform-lab'
function Run([string]$Command, [string[]]$Arguments) {
    & $Command @Arguments
    if ($LASTEXITCODE) { throw "$Command failed with exit $LASTEXITCODE" }
}
function CheckCluster { Run kubectl @('--context',$context,'cluster-info') }
$versions = Get-Content versions.json | ConvertFrom-Json
switch ($Action) {
    create {
        Run docker @('info','--format','{{.OSType}}')
        $clusters = & kind get clusters
        if ($LASTEXITCODE) { throw 'Kind could not inspect clusters' }
        if ($clusters -notcontains 'platform-lab') { Run kind @('create','cluster','--name','platform-lab','--config','kind/cluster.yaml','--image',$versions.kind_node,'--wait','180s') }
        CheckCluster
    }
    deploy {
        CheckCluster
        if ($Version -notmatch '^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$' -or $Version -eq 'latest') { throw 'Use a versioned image tag' }
        Run docker @('build','-t',"platform-sample:$Version",'application')
        Run kind @('load','docker-image',"platform-sample:$Version",'--name','platform-lab')
        foreach ($folder in @('namespaces','resource-quotas','network-policies','rbac')) { Run kubectl @('--context',$context,'apply','-f',"kubernetes/$folder") }
        foreach ($namespace in @('dev','stage')) {
            Run helm @('upgrade','--install','sample-application','helm/sample-application','--kube-context',$context,'--namespace',$namespace,'-f',"helm/sample-application/values-$namespace.yaml",'--set-string',"image.tag=$Version",'--set-string',"version=$Version",'--set-string',"deployedAt=$([DateTime]::UtcNow.ToString('o'))",'--wait','--timeout','180s')
        }
    }
    argocd {
        CheckCluster
        Run helm @('repo','add','argo','https://argoproj.github.io/argo-helm')
        Run helm @('repo','update','argo')
        Run helm @('upgrade','--install','argocd','argo/argo-cd','--version',$versions.argocd_chart,'--namespace','argocd','--create-namespace','--kube-context',$context,'-f','argocd/installation/values.yaml','--wait','--timeout','600s')
    }
    metrics {
        CheckCluster
        Run kubectl @('--context',$context,'apply','-f',"https://github.com/kubernetes-sigs/metrics-server/releases/download/v$($versions.metrics_server)/components.yaml")
        $patch = '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
        Run kubectl @('--context',$context,'-n','kube-system','patch','deployment','metrics-server','--type=json',"--patch=$patch")
        Run kubectl @('--context',$context,'-n','kube-system','rollout','status','deployment/metrics-server','--timeout=180s')
    }
    gitops {
        CheckCluster
        if (-not (Test-Path out/gitops.git)) {
            Run $python @('scripts/export-gitops.py','out/gitops-work')
            Run git @('-C','out/gitops-work','init','-b','main')
            Run git @('-C','out/gitops-work','add','.')
            Run git @('-C','out/gitops-work','-c','user.name=Lab','-c','user.email=lab@localhost','commit','-m','Initialize local GitOps')
            Run git @('clone','--bare','out/gitops-work','out/gitops.git')
            Run git @('-C','out/gitops-work','remote','add','origin',"$root/out/gitops.git")
        }
        # Only the sample repository is exported, with receive-pack disabled.
        $gitDaemon = Start-Process -FilePath (Get-Command git.exe).Source -ArgumentList @('daemon','--reuseaddr',"--base-path=$root/out",'--export-all','--listen=0.0.0.0','--port=9418',"$root/out/gitops.git") -WindowStyle Hidden -PassThru
        $gitDaemon.Id | Set-Content out/git-daemon.pid
        Run $python @('scripts/configure-argocd.py','--repo-url','git://host.docker.internal:9418/gitops.git')
        Run kubectl @('--context',$context,'apply','-f','out/argocd')
    }
    verify {
        CheckCluster
        Run kubectl @('--context',$context,'get','nodes','-o','wide')
        foreach ($namespace in @('dev','stage')) {
            Run kubectl @('--context',$context,'-n',$namespace,'rollout','status','deployment/sample-application','--timeout=180s')
            Run kubectl @('--context',$context,'-n',$namespace,'exec','deployment/sample-application','--','python','-c','import json,urllib.request; assert json.load(urllib.request.urlopen("http://127.0.0.1:8080/health/ready"))["status"]=="ready"')
        }
    }
    cleanup {
        if ($Confirmation -ne 'DELETE platform-lab') { throw 'Pass -Confirmation "DELETE platform-lab" to remove this local cluster only' }
        CheckCluster
        Run kubectl @('--context',$context,'get','all','-A')
        Run kind @('delete','cluster','--name','platform-lab')
    }
}
