import json,os,urllib.parse,urllib.request
url=urllib.parse.urlparse(os.environ['GITOPS_URL'])
parts=url.path.strip('/').split('/')
if url.scheme!='https' or url.hostname!='dev.azure.com' or len(parts)!=4 or parts[2]!='_git':
    raise SystemExit('GitOps PR automation expects https://dev.azure.com/ORG/PROJECT/_git/REPO')
org,project,_,repo=parts
endpoint=f'https://dev.azure.com/{org}/{project}/_apis/git/repositories/{repo}/pullrequests?api-version=7.1'
body={'sourceRefName':'refs/heads/'+os.environ['GITOPS_BRANCH'],'targetRefName':'refs/heads/main',
      'title':'Promote '+os.environ['GITOPS_BRANCH'],'description':'Immutable release prepared by the authorized application/promotion pipeline. Review digest and tests before merging.'}
request=urllib.request.Request(endpoint,data=json.dumps(body).encode(),headers={
    'Authorization':'Bearer '+os.environ['SYSTEM_ACCESSTOKEN'],'Content-Type':'application/json'})
with urllib.request.urlopen(request,timeout=30) as response:
    result=json.load(response)
print('Review PR:',result['_links']['web']['href'])
