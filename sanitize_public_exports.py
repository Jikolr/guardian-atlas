
"""Remove private extraction exports and local source paths before publishing."""
from pathlib import Path
import json,re,gzip
B=Path(__file__).resolve().parent;D=B/'dist'
BLOCKED={'Extraction tools-'+n for n in ('decode_scripts.py','decode_static.py','decode_maps.py')}
def clean(s):
 s=re.sub(r'(?i)[A-Z]:[\\/]+Users[\\/]+[^\\/\r\n]+[\\/]+OneDrive - [^\\/\r\n]+[\\/]+Desktop[\\/]+','',s)
 s=re.sub(r'(?i)[A-Z]:[\\/]+Users[\\/]+[^\\/\r\n]+[\\/]+(?:Downloads|Desktop)[\\/]+','',s)
 s=re.sub(r'(?i)[A-Z]:[\\/]+Users[\\/]+[^\\/\r\n]+','LOCAL_HOME',s)
 s=re.sub(r'(?i)[A-Z]:[\\/]+Codex[\\/]+','',s)
 return s
def walk(x):
 if isinstance(x,str):return clean(x)
 if isinstance(x,list):return [walk(v) for v in x]
 if isinstance(x,dict):return {clean(k):walk(v) for k,v in x.items()}
 return x
def sanitize():
 evidence=D/'data/research/evidence'
 for name in BLOCKED:
  p=evidence/name
  assert p.resolve().parent==evidence.resolve()
  p.unlink(missing_ok=True)
 for p in list(evidence.glob('*.py'))+list(evidence.glob('*.md'))+[D/'data/visual/assets.json']:
  if not p.exists():continue
  s=p.read_text(encoding='utf8')
  text=json.dumps(walk(json.loads(s)),ensure_ascii=False,separators=(',',':')) if p.suffix=='.json' else clean(s)
  if text!=s:p.write_text(text,encoding='utf8')
 for p in [D/'data/research/evidence.json',D/'data/file-catalog.json']:
  x=json.loads(p.read_text(encoding='utf8'))
  def allowed(r):return not any(Path(r.get(k,'')).name in BLOCKED for k in ('url','path'))
  if isinstance(x,list):
   x=[r for r in x if allowed(r)]
   for r in x:
    target=D/r.get('url','')
    if target.is_file():r['bytes']=target.stat().st_size
  else:
   x['files']=[r for r in x['files'] if allowed(r)]
   for r in x['files']:
    target=D/r.get('url','')
    if target.is_file():r['bytes']=target.stat().st_size
  p.write_text(json.dumps(x,ensure_ascii=False,separators=(',',':')),encoding='utf8')
 settings=json.loads((D/'admin/settings.json').read_text(encoding='utf8'))
 if settings.get('authBaseUrl'):raise ValueError('Authentication URL must be configured privately in the admin browser.')
 print('Public exports sanitized; decryption tools excluded; authentication URL absent.')
if __name__=='__main__':sanitize()

