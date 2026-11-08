"""Calculate from reviewed rates, or discover live Azure Retail Prices candidates."""
import argparse,json,urllib.parse,urllib.request
from datetime import datetime,timezone
from pathlib import Path

COMPONENTS=('workers','managed_disks','public_ip','load_balancer','acr','key_vault','state_storage','monitoring')
def calculate(inputs):
    if inputs.get('mode') != 'azure':
        raise ValueError('Only Azure cost inputs are supported')
    lines=[]
    for name in COMPONENTS:
        item=inputs['components'][name]
        if item['unit_price'] is None or item['monthly_units'] is None or not item['source']:
            raise ValueError('Review a current price, usage assumption and source for '+name)
        if item['unit_price']<0 or item['monthly_units']<0: raise ValueError('Negative cost inputs are invalid')
        monthly=item['unit_price']*item['monthly_units']
        lines.append({'component':name,'monthly':round(monthly,4),'daily_average':round(monthly/(730/24),4)})
    total=sum(x['monthly'] for x in lines)
    return {'mode':'azure','currency':inputs['currency'],'hours_per_month':730,'lines':lines,
            'control_plane_management':0,'monthly':round(total,2),'daily_average':round(total/(730/24),2),
            'limitations':'Retail estimates exclude taxes, FX changes, surge/rotation nodes, egress beyond input assumptions and credits. Budgets are alerts, not spending limits.'}

def discover(region,sku):
    queries={
      'workers':f"armRegionName eq '{region}' and serviceName eq 'Virtual Machines' and armSkuName eq '{sku}' and priceType eq 'Consumption'",
      'network':f"armRegionName eq '{region}' and (serviceName eq 'Load Balancer' or serviceName eq 'Virtual Network') and priceType eq 'Consumption'",
      'acr':f"armRegionName eq '{region}' and serviceName eq 'Container Registry' and priceType eq 'Consumption'",
      'key_vault':f"armRegionName eq '{region}' and serviceName eq 'Key Vault' and priceType eq 'Consumption'",
      'storage':f"armRegionName eq '{region}' and serviceName eq 'Storage' and skuName eq 'Standard LRS' and priceType eq 'Consumption'",
      'monitoring':f"armRegionName eq '{region}' and serviceName eq 'Log Analytics' and priceType eq 'Consumption'"}
    result={'retrieved_at':datetime.now(timezone.utc).isoformat(),'region':region,'sku':sku,'candidates':{}}
    for name,query in queries.items():
        url='https://prices.azure.com/api/retail/prices?'+urllib.parse.urlencode({'$filter':query,'currencyCode':"'USD'"})
        rows=[]
        while url:
            with urllib.request.urlopen(url,timeout=60) as response: page=json.load(response)
            rows.extend(page['Items']); url=page.get('NextPageLink')
        result['candidates'][name]=rows
    return result

def main():
    p=argparse.ArgumentParser()
    mode=p.add_mutually_exclusive_group(required=True)
    mode.add_argument('--input',type=Path); mode.add_argument('--discover',action='store_true')
    p.add_argument('--region',default='centralindia'); p.add_argument('--sku',default='Standard_D4ds_v5')
    p.add_argument('--output',default='reports/cost-estimate.json',type=Path); a=p.parse_args()
    if a.discover: result=discover(a.region,a.sku)
    elif a.input: result=calculate(json.loads(a.input.read_text()))
    a.output.parent.mkdir(parents=True,exist_ok=True); a.output.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2) if not a.discover else 'Official retail candidates saved to '+str(a.output))
if __name__=='__main__': main()
