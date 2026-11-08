import copy
import importlib.util
import json
import os
import shutil
import subprocess
from pathlib import Path
import pytest
import yaml
import plan_artifact
import gitops_update

ROOT=Path(__file__).resolve().parents[1]

@pytest.fixture
def artifact(tmp_path):
    for name in plan_artifact.FILES:
        (tmp_path/name).write_text('{}' if name=='backend.json' else 'approved')
    manifest={'root':plan_artifact.ROOT,'branch':'refs/heads/main','commit':'abc','pipeline_id':10,
              'run_id':20,'created_at':1000,'target':{},'sha256':{n:plan_artifact.digest(tmp_path/n) for n in plan_artifact.FILES}}
    return tmp_path,manifest

def test_saved_plan_integrity_and_expiry(artifact):
    path,m=artifact
    plan_artifact.verify(path,m,'abc',10,20,{},now=1001)
    with pytest.raises(ValueError,match='expired'):
        plan_artifact.verify(path,m,'abc',10,20,{},now=9000)
    (path/'plan.tfplan').write_text('tampered')
    with pytest.raises(ValueError,match='tampered'):
        plan_artifact.verify(path,m,'abc',10,20,{},now=1001)

@pytest.mark.parametrize('field,value', [('commit','wrong'),('pipeline_id',11),('run_id',21),('branch','refs/pull/1/merge'),('root','bootstrap')])
def test_plan_rejects_wrong_provenance(artifact,field,value):
    path,m=artifact; m[field]=value
    with pytest.raises(ValueError): plan_artifact.verify(path,m,'abc',10,20,{},now=1001)

def test_plan_rejects_other_subscription(artifact):
    path,m=artifact
    with pytest.raises(ValueError,match='mismatch'): plan_artifact.verify(path,m,'abc',10,20,{'subscription':'other'},now=1001)

def run_git(repo,*args):
    return subprocess.check_output(['git','-C',str(repo),*args],text=True,stderr=subprocess.STDOUT)

def test_promotion_and_git_revert(tmp_path):
    chart=tmp_path/'helm/sample-application'; chart.mkdir(parents=True)
    old={'environment':'stage','replicaCount':2,'pdb':{'enabled':True},'image':{'repository':'lab.azurecr.io/app','digest':'sha256:'+'a'*64,'tag':'a'},'version':'a','deployedAt':'before'}
    for env in ('dev','stage'): (chart/f'values-{env}.yaml').write_text(yaml.safe_dump(old))
    run_git(tmp_path,'init','-b','main'); run_git(tmp_path,'config','user.name','Test'); run_git(tmp_path,'config','user.email','test@localhost')
    run_git(tmp_path,'add','.'); run_git(tmp_path,'commit','-m','initial')
    release={'image':{'repository':'lab.azurecr.io/app','digest':'sha256:'+'b'*64,'tag':'b'},'version':'b','deployedAt':'after'}
    gitops_update.update(tmp_path,'stage',release)
    values=yaml.safe_load((chart/'values-stage.yaml').read_text())
    assert values['replicaCount']==2 and values['pdb']['enabled']
    assert gitops_update.read_release(tmp_path,'dev')['version']=='a'
    run_git(tmp_path,'add','.'); run_git(tmp_path,'commit','-m','release'); run_git(tmp_path,'revert','--no-edit','HEAD')
    assert gitops_update.read_release(tmp_path,'stage')['image']['digest']=='sha256:'+'a'*64

@pytest.mark.parametrize('digest',['latest','sha256:abc','', 'sha256:'+'g'*64])
def test_release_requires_digest(digest):
    with pytest.raises(ValueError): gitops_update.validate_release({'image':{'repository':'registry/app','digest':digest},'version':'release'})

def bash_path():
    windows=Path('C:/Program Files/Git/bin/bash.exe')
    return str(windows) if windows.exists() else shutil.which('bash')

def test_shell_syntax_and_aks_context_guard():
    bash=bash_path()
    if not bash: pytest.skip('Bash unavailable')
    for script in (ROOT/'scripts').glob('*.sh'):
        result=subprocess.run([bash,'-n',str(script)],capture_output=True,text=True)
        assert result.returncode==0, (script,result.stderr)
    env=dict(os.environ, KUBE_CONTEXT='unapproved-cluster', APPROVED_AKS_CONTEXT='approved-aks')
    result=subprocess.run([bash,'-c','source scripts/common.sh; require_target'],cwd=ROOT,env=env,capture_output=True,text=True)
    assert result.returncode==2 and 'Unapproved Kubernetes context' in result.stdout
    env.pop('APPROVED_AKS_CONTEXT')
    result=subprocess.run([bash,'-c','source scripts/common.sh; require_target'],cwd=ROOT,env=env,capture_output=True,text=True)
    assert result.returncode!=0 and 'Set the approved AKS context' in result.stderr

def walk(value):
    if isinstance(value,dict):
        yield value
        for child in value.values(): yield from walk(child)
    elif isinstance(value,list):
        for child in value: yield from walk(child)

def test_pipeline_safety_structure():
    for file in (ROOT/'pipelines').rglob('*.yml'):
        data=yaml.safe_load(file.read_text())
        assert isinstance(data,dict),file
    cd=yaml.safe_load((ROOT/'pipelines/terraform-cd.yml').read_text())
    destroy=yaml.safe_load((ROOT/'pipelines/destroy.yml').read_text())
    assert cd['trigger']=='none' and destroy['trigger']=='none'
    assert any(x.get('environment')=='azure-lab-apply' for x in walk(cd))
    assert any(x.get('environment')=='azure-lab-destroy' for x in walk(destroy))
    assert destroy['parameters'][0]['values']==['shared-aks']
    assert 'terraform apply' not in (ROOT/'pipelines/terraform-ci.yml').read_text()
    assert '--same-run' in (ROOT/'pipelines/destroy.yml').read_text()

def test_chart_and_namespace_invariants():
    for env in ('dev','stage'):
        quota=list(yaml.safe_load_all((ROOT/f'kubernetes/resource-quotas/{env}.yaml').read_text()))[0]
        assert str(quota['spec']['hard']['services.loadbalancers'])=='0'
    dep=(ROOT/'helm/sample-application/templates/deployment.yaml').read_text()
    for text in ('readOnlyRootFilesystem: true','allowPrivilegeEscalation: false','runAsNonRoot: true','/health/ready','fieldPath: metadata.name'):
        assert text in dep

def test_cost_requires_verified_rates():
    spec=importlib.util.spec_from_file_location('cost',ROOT/'scripts/estimate-cost.py'); module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    with pytest.raises(ValueError,match='Only Azure'):
        module.calculate({'mode':'unsupported'})
    with pytest.raises(ValueError,match='Review'):
        module.calculate(json.loads((ROOT/'cost-inputs.example.json').read_text()))
