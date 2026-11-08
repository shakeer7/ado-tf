"""Read-only post-destroy checks. Never deletes discovered leftovers."""
import json,subprocess,sys
from pathlib import Path
before=json.loads(Path(sys.argv[1]).read_text())
node_rg=before.get('node_resource_group',{}).get('value')
report={'node_resource_group':node_rg,'leftovers':[]}
platform_rg=before.get('platform_resource_group',{}).get('value')
if platform_rg:
    report['platform_resources_retained']=json.loads(subprocess.check_output(['az','resource','list','-g',platform_rg,'-o','json'],text=True))
if node_rg:
    exists=subprocess.check_output(['az','group','exists','-n',node_rg],text=True).strip()=='true'
    if exists:
        report['leftovers']=json.loads(subprocess.check_output(['az','resource','list','-g',node_rg,'-o','json'],text=True))
        report['orphan_disks_and_public_ips']=[r for r in report['leftovers'] if r.get('type','').lower() in ('microsoft.compute/disks','microsoft.network/publicipaddresses')]
Path(sys.argv[2],'orphan-report.json').write_text(json.dumps(report,indent=2)+'\n')
if report['leftovers']:
    raise SystemExit('Orphan resources remain; inspect cleanup-report. No resources were deleted by this check.')
