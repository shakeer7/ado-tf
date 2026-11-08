"""Promote immutable release metadata without editing unrelated environment values."""
import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path
import yaml

def validate_release(release):
    image = release['image']
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9./:_-]*', image['repository']):
        raise ValueError('Invalid image repository')
    if not re.fullmatch(r'sha256:[a-f0-9]{64}',image['digest']):
        raise ValueError('Cloud releases require an immutable SHA256 digest')
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]{0,127}', release['version']) or release['version']=='latest':
        raise ValueError('Invalid release version')
    return release

def read_release(repo, env):
    data = yaml.safe_load((Path(repo)/f'helm/sample-application/values-{env}.yaml').read_text())
    return validate_release({k:data[k] for k in ('image','version','deployedAt')})

def update(repo, env, release):
    if env not in ('dev','stage'):
        raise ValueError('Unsupported environment')
    release=validate_release(release)
    path=Path(repo)/f'helm/sample-application/values-{env}.yaml'
    values=yaml.safe_load(path.read_text())
    values.update(release)
    path.write_text(yaml.safe_dump(values,sort_keys=False))

def main():
    p=argparse.ArgumentParser()
    sub=p.add_subparsers(dest='action',required=True)
    release=sub.add_parser('update')
    release.add_argument('--repo',required=True); release.add_argument('--env',choices=['dev','stage'],required=True)
    release.add_argument('--image',required=True); release.add_argument('--digest',required=True); release.add_argument('--version',required=True)
    snap=sub.add_parser('snapshot'); snap.add_argument('--repo',required=True); snap.add_argument('--output',required=True)
    args=sub.add_parser('release-args'); args.add_argument('file')
    a=p.parse_args()
    if a.action=='snapshot':
        Path(a.output).write_text(json.dumps(read_release(a.repo,'dev'),indent=2)+'\n')
    elif a.action=='update':
        update(a.repo,a.env,{'image':{'repository':a.image,'digest':a.digest,'tag':a.version,'pullPolicy':'Always'},'version':a.version,
                            'deployedAt':datetime.now(timezone.utc).isoformat()})
    else:
        r=validate_release(json.loads(Path(a.file).read_text()))
        print(r['image']['repository']); print(r['image']['digest']); print(r['version'])
if __name__=='__main__':
    main()
