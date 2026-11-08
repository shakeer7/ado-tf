import argparse,json
from pathlib import Path
from urllib.parse import urlparse
p=argparse.ArgumentParser()
p.add_argument('--repo-url',required=True); p.add_argument('--revision',default='main'); p.add_argument('--output',default='out/argocd')
a=p.parse_args()
if urlparse(a.repo_url).scheme not in ('https','ssh','git'):
    raise SystemExit('Use a Git URL reachable from cluster pods, never a host filesystem path')
d=Path(a.output); d.mkdir(parents=True,exist_ok=True)
project={'apiVersion':'argoproj.io/v1alpha1','kind':'AppProject','metadata':{'name':'platform-lab','namespace':'argocd'},'spec':{
    'sourceRepos':[a.repo_url], 'destinations':[{'server':'https://kubernetes.default.svc','namespace':env} for env in ('dev','stage')],
    'clusterResourceWhitelist':[], 'namespaceResourceWhitelist':[
        {'group':'','kind':kind} for kind in ('Service','ServiceAccount','ConfigMap')]+[
        {'group':'apps','kind':'Deployment'},{'group':'networking.k8s.io','kind':'NetworkPolicy'},
        {'group':'policy','kind':'PodDisruptionBudget'},{'group':'autoscaling','kind':'HorizontalPodAutoscaler'},
        {'group':'secrets-store.csi.x-k8s.io','kind':'SecretProviderClass'}]}}
(d/'project.yaml').write_text(json.dumps(project,indent=2)+'\n')
for env in ('dev','stage'):
    app={'apiVersion':'argoproj.io/v1alpha1','kind':'Application','metadata':{'name':'sample-'+env,'namespace':'argocd'},'spec':{
        'project':'platform-lab', 'source':{'repoURL':a.repo_url,'targetRevision':a.revision,'path':'helm/sample-application',
        'helm':{'releaseName':'sample-application','valueFiles':['values.yaml','values-'+env+'.yaml']}},
        'destination':{'server':'https://kubernetes.default.svc','namespace':env},
        'syncPolicy':{'automated':{'prune':True,'selfHeal':True},'retry':{'limit':3}}}}
    (d/('sample-'+env+'.yaml')).write_text(json.dumps(app,indent=2)+'\n')
