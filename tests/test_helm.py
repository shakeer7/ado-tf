import shutil
import subprocess
from pathlib import Path
import pytest
import yaml

ROOT=Path(__file__).resolve().parents[1]
HELM=str(ROOT/'.tools/helm.exe') if (ROOT/'.tools/helm.exe').exists() else shutil.which('helm')
pytestmark=pytest.mark.skipif(not HELM,reason='Helm not installed')

def template(*extra):
    return subprocess.run([HELM,'template','sample-application',str(ROOT/'helm/sample-application'),'--namespace','stage','-f',str(ROOT/'helm/sample-application/values-stage.yaml'),'-f',str(ROOT/'tests/fixtures/image.yaml'),*extra],text=True,capture_output=True)

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


@pytest.mark.parametrize('value', ['image.digest=', 'image.digest=sha256:abc', 'image.pullPolicy=IfNotPresent'])
def test_azure_image_policy_is_required(value):
    result=template('--set-string',value)
    assert result.returncode!=0 and 'schema' in result.stderr.lower()


@pytest.mark.parametrize('chart', ['helm/sample-application', 'gitops-repo/helm/sample-application'])
def test_chart_requires_a_real_release_configuration(chart):
    result=subprocess.run([HELM,'template','sample-application',str(ROOT/chart)],text=True,capture_output=True)
    assert result.returncode!=0 and 'schema' in result.stderr.lower()


def test_gitops_seed_uses_the_same_azure_chart():
    source=ROOT/'helm/sample-application'
    seed=ROOT/'gitops-repo/helm/sample-application'
    for file in source.rglob('*'):
        if file.is_file():
            assert file.read_bytes()==(seed/file.relative_to(source)).read_bytes(), file
