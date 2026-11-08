import json,os
from pathlib import Path
config = {'resource_group_name':os.environ['STATE_RESOURCE_GROUP'],
          'storage_account_name':os.environ['STATE_ACCOUNT'],
          'container_name':os.environ['STATE_CONTAINER'],
          'key':os.environ['STATE_KEY'],'use_azuread_auth':True,'use_oidc':True}
if config['key'] != 'shared-aks.tfstate' or config['container_name'] != 'tfstate':
    raise SystemExit('Only the independently managed shared-aks backend is allowed')
Path('out').mkdir(exist_ok=True)
Path('out/backend.hcl').write_text('\n'.join(f'{k} = {json.dumps(v)}' for k,v in config.items())+'\n')
