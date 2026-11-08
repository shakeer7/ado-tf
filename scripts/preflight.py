"""Read-only Azure eligibility, capacity and version discovery. Fails closed."""
import argparse,json,shutil,subprocess,sys
from pathlib import Path
AZ=shutil.which('az')
def az(*args):
    print('Read-only Azure check:',args[0],flush=True)
    result=subprocess.run([AZ,*args,'-o','json'],text=True,capture_output=True,timeout=60)
    if result.returncode:
        raise RuntimeError(result.stderr.strip())
    return json.loads(result.stdout)

def main():
    p=argparse.ArgumentParser(); p.add_argument('--region',default='centralindia'); p.add_argument('--sku',default='Standard_D4ds_v5'); p.add_argument('--output',default='reports/preflight.json')
    a=p.parse_args(); report={'region':a.region,'sku':a.sku,'blockers':[]}
    if not AZ: raise SystemExit('Azure CLI not installed')
    account=az('account','show')
    policy=az('rest','--method','get','--url',f"https://management.azure.com/subscriptions/{account['id']}?api-version=2022-12-01")
    report['subscription']={k:policy.get(k) for k in ('displayName','state','subscriptionPolicies')}
    if policy.get('state')!='Enabled': report['blockers'].append('ARM subscription is not Enabled')
    if report['blockers']:
        report['capacity_checks']='Skipped because the subscription is disabled; prior quota observations are documented in docs/discovery.md'
        output=Path(a.output); output.parent.mkdir(parents=True,exist_ok=True); output.write_text(json.dumps(report,indent=2)+'\n')
        print(json.dumps({'blockers':report['blockers'],'report':str(output)},indent=2))
        return 2
    usage=az('vm','list-usage','--location',a.region)
    report['quota']=[x for x in usage if x['name']['value'].lower() in ('cores','standardddsv5family')]
    for quota in report['quota']:
        if int(quota['limit'])-int(quota['currentValue'])<12:
            report['blockers'].append(f"Insufficient {quota['name']['value']} quota for two 4-vCPU system nodes plus one upgrade surge node")
    skus=az('vm','list-skus','--location',a.region,'--size',a.sku,'--all')
    report['skus']=[s for s in skus if s.get('name')==a.sku and s.get('resourceType')=='virtualMachines']
    if not report['skus'] or any(s.get('restrictions') for s in report['skus']):
        report['blockers'].append('Exact VM SKU unavailable or restricted for this subscription')
    for sku in report['skus']:
        capabilities={x['name']:x['value'] for x in sku['capabilities']}
        if int(capabilities.get('vCPUs','0'))<4 or float(capabilities.get('MemoryGB','0'))<4:
            report['blockers'].append('System pool requires at least 4 vCPUs and 4 GiB')
        if capabilities.get('EphemeralOSDiskSupported')!='True':
            report['blockers'].append('Selected SKU does not support the configured ephemeral OS disk')
        local_gib=max(float(capabilities.get('CachedDiskBytes','0'))/(1024**3),float(capabilities.get('MaxResourceVolumeMB','0'))/1024)
        if local_gib<64:
            report['blockers'].append('Verify ephemeral OS cache/temp capacity: less than configured 64 GiB was reported')
    report['aks_versions']=az('aks','get-versions','--location',a.region)
    report['credit_check']='MANUAL: inspect Azure Portal credits/expiry/billing offer; no universal remaining-credit API is assumed'
    report['approval']='Deployment is not approved by this report. Review pricing, quota, API access and subscription billing.'
    output=Path(a.output); output.parent.mkdir(parents=True,exist_ok=True); output.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'region':a.region,'blockers':report['blockers'],'report':str(output)},indent=2))
    return 2 if report['blockers'] else 0
if __name__=='__main__':
    try: sys.exit(main())
    except (RuntimeError,OSError,subprocess.TimeoutExpired) as error: sys.exit(str(error))
