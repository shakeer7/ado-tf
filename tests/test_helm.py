import shutil
import subprocess
from pathlib import Path
import pytest
import yaml

ROOT=Path(__file__).resolve().parents[1]
HELM=str(ROOT/'.tools/helm.exe') if (ROOT/'.tools/helm.exe').exists() else shutil.which('helm')
pytestmark=pytest.mark.skipif(not HELM,reason='Helm not installed')

def template(*extra):
    return subprocess.run([HELM,'template','sample-application',str(ROOT/'helm/sample-application'),'--namespace','stage','-f',str(ROOT/'helm/sample-application/values-stage.yaml'),*extra],text=True,capture_output=True)

def test_optional_workload_identity_and_scaling():
    result=template('--set','workloadIdentity.enabled=true','--set','workloadIdentity.clientId=00000000-0000-0000-0000-000000000001','--set','workloadIdentity.tenantId=00000000-0000-0000-0000-000000000002','--set','workloadIdentity.vaultName=test-vault','--set','autoscaling.enabled=true','--set','image.digest=sha256:'+'a'*64,'--set','image.pullPolicy=Always')
    assert result.returncode==0,result.stderr
    resources={r['kind']:r for r in yaml.safe_load_all(result.stdout) if r}
    deployment=resources['Deployment']
    assert deployment['metadata']['namespace']=='stage'
    assert 'checkov.io/skip1' not in deployment['metadata'].get('annotations',{})
    pod=deployment['spec']['template']
    assert pod['metadata']['labels']['azure.workload.identity/use']=='true'
    assert resources['ServiceAccount']['metadata']['annotations']['azure.workload.identity/client-id'].endswith('001')
    assert resources['SecretProviderClass']['spec']['parameters']['usePodIdentity']=='false'
    assert resources['HorizontalPodAutoscaler']['spec']['minReplicas']==1
    assert resources['PodDisruptionBudget']['spec']['minAvailable']==1
    assert pod['spec']['containers'][0]['image'].endswith('@sha256:'+'a'*64)

def test_latest_tag_is_rejected():
    result=template('--set','image.tag=latest')
    assert result.returncode!=0 and 'schema' in result.stderr.lower()
