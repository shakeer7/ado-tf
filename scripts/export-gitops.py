import argparse,shutil
from pathlib import Path
p=argparse.ArgumentParser(); p.add_argument('destination',type=Path); a=p.parse_args()
root=Path(__file__).resolve().parents[1]
dest=a.destination.resolve()
if dest==root or root in dest.parents and dest.parts[-1] in ('helm','application','terraform'):
    raise SystemExit('Choose a separate GitOps checkout or out/gitops-work')
shutil.copytree(root/'gitops-repo',dest,dirs_exist_ok=True)
print('Exported independent GitOps repository to',dest)
