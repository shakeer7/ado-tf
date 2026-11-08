"""Bind a sensitive saved plan to its build, target, source and expiry."""
import argparse
import hashlib
import json
import os
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

ROOT = 'terraform/environments/shared-aks'
FILES = ('plan.tfplan', 'plan.json', 'plan.txt', 'backend.json', 'provider.lock.hcl', 'inventory-before.json', 'outputs-before.json')
def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def target():
    return {k: os.environ[k] for k in ('ARM_SUBSCRIPTION_ID','STATE_RESOURCE_GROUP', 'STATE_ACCOUNT','STATE_CONTAINER','STATE_KEY')}

def verify(directory, manifest, expected_commit, expected_pipeline, expected_run, expected_target, now=None):
    now = time.time() if now is None else now
    if manifest['root'] != ROOT or manifest['branch'] != 'refs/heads/main':
        raise ValueError('Untrusted root or branch')
    if manifest['commit'] != expected_commit or str(manifest['pipeline_id']) != str(expected_pipeline) or str(manifest['run_id']) != str(expected_run):
        raise ValueError('Plan provenance does not match selected source run')
    age = now - manifest['created_at']
    if age < -60 or age > 7200:
        raise ValueError('Plan is expired or timestamp is in the future; regenerate and reapprove')
    if manifest['target'] != expected_target:
        raise ValueError('Backend or subscription mismatch')
    if set(manifest['sha256']) != set(FILES):
        raise ValueError('Unexpected artifact file list')
    for file in FILES:
        if digest(directory/file) != manifest['sha256'][file]:
            raise ValueError(f'Artifact tampered: {file}')
    if json.loads((directory/'backend.json').read_text()) != expected_target:
        raise ValueError('Backend content differs from approval target')

def trusted_build(manifest, same_run=False):
    if same_run:
        if str(manifest['run_id']) != os.environ['BUILD_BUILDID'] or str(manifest['pipeline_id']) != os.environ['SYSTEM_DEFINITIONID']:
            raise ValueError('Destroy artifact must originate in this exact run')
        return
    url = (os.environ['SYSTEM_COLLECTIONURI'] + os.environ['SYSTEM_TEAMPROJECTID'] +
           '/_apis/build/builds/' + str(manifest['run_id']) + '?api-version=7.1')
    request = urllib.request.Request(url, headers={'Authorization':'Bearer '+os.environ['SYSTEM_ACCESSTOKEN']})
    with urllib.request.urlopen(request, timeout=30) as response:
        build = json.load(response)
    if (str(build['definition']['id']) != str(manifest['pipeline_id']) or
        build['result'] != 'succeeded' or build['reason'] != 'manual' or
        build['sourceBranch'] != 'refs/heads/main' or build['sourceVersion'] != manifest['commit'] or
        build['repository']['id'] != os.environ['BUILD_REPOSITORY_ID']):
        raise ValueError('Selected run is not a successful trusted main-branch manual plan')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action',choices=['create','verify'])
    parser.add_argument('directory',type=Path)
    parser.add_argument('--destroy',action='store_true')
    parser.add_argument('--same-run',action='store_true')
    args = parser.parse_args()
    d = args.directory
    if args.action == 'create':
        manifest = {'root':ROOT,'branch':os.environ['BUILD_SOURCEBRANCH'],
                    'commit':os.environ['BUILD_SOURCEVERSION'],'pipeline_id':os.environ['SYSTEM_DEFINITIONID'],
                    'run_id':os.environ['BUILD_BUILDID'],'created_at':time.time(),'target':target(),
                    'destroy':args.destroy,'sha256':{f:digest(d/f) for f in FILES}}
        (d/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    else:
        manifest = json.loads((d/'manifest.json').read_text())
        if manifest['destroy'] != args.destroy:
            raise ValueError('Wrong plan operation')
        verify(d, manifest, os.environ['BUILD_SOURCEVERSION'],
               os.environ['TRUSTED_PIPELINE_ID'],os.environ['TRUSTED_RUN_ID'], target())
        trusted_build(manifest,args.same_run)
        current = Path(ROOT)/'.terraform.lock.hcl'
        if digest(current) != digest(d/'provider.lock.hcl'):
            raise ValueError('Provider lock differs from the approved source')
        print('Plan provenance, target, age and integrity verified')

if __name__ == '__main__':
    try:
        main()
    except (ValueError,KeyError,OSError) as exc:
        sys.exit(str(exc))
