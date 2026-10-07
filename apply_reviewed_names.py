
"""Apply visually reviewed names by record identity, without changing raw game fields."""
from pathlib import Path
import json,gzip,re,collections
B=Path(__file__).resolve().parent;D=B/'dist/data'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,x):p.write_text(json.dumps(x,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
def main():
 decisions=read(B/'name-review-decisions.json')['decisions']
 profiles=json.loads(gzip.decompress((D/'characters.json.gz').read_bytes()))
 bosses=read(D/'raid-simulator.json')['bosses']
 byid={p['id']:p for p in profiles};bossid={b['Id']:b for b in bosses}
 verified={};skipped=[];labels={};count=collections.Counter()
 for d in decisions:
  choice=d.get('decision');name=(d.get('note','') if choice=='correct' else d.get('proposedName','')).strip()
  if choice not in ('confirm','correct') or not name:skipped.append(d['key']);continue
  kind,ident=d['key'].split(':');ident=int(ident)
  evidence='User-confirmed by portrait review (2026-10-07); source: name-review-decisions.json, '+d['key']
  if kind=='hero':
   p=byid[ident];assert p['internal']==d['internal'],d['key']
   p.update(name=name,status='Confirmed',evidence=evidence)
   for v in p['variants']:verified['heroes:'+str(v['id'])]=dict(name=name,profileId=ident,evidence=evidence)
  else:
   b=bossid[ident];visual=b.get('VisualName') or b['Class'];assert visual==d['internal'],d['key']
   for v in bosses:
    if (v.get('VisualName') or v['Class'])==visual:verified['monsters:'+str(v['Id'])]=dict(name=name,evidence=evidence)
  labels[d['key']]=dict(name=name,internal=d['internal'],evidence=evidence);count[kind]+=1
 (D/'characters.json.gz').write_bytes(gzip.compress(json.dumps(profiles,ensure_ascii=False,separators=(',',':')).encode(),mtime=0))
 aliases=read(D/'character-aliases.json')
 for k,v in verified.items():
  if k.startswith('heroes:'):aliases[k.split(':')[1]]=dict(name=v['name'],profileId=v['profileId'],evidence=v['evidence'])
 write(D/'character-aliases.json',aliases)
 media=read(D/'visual/record-media.json')
 for k,v in verified.items():
  entry=media.setdefault(k,{})
  entry.update(name=v['name'],aliasSource=v['evidence'])
  if 'profileId' in v:entry['profileId']=v['profileId']
 write(D/'visual/record-media.json',media)
 records=read(D/'visual/records.json')
 for r in records:
  v=verified.get(r['table']+':'+str(r['id']))
  if v:r.update(displayName=v['name'],aliasSource=v['evidence'],**({'profileId':v['profileId']} if 'profileId' in v else {}))
 write(D/'visual/records.json',records)
 # Safe name tokens only when every profile sharing a class agrees on one confirmed name.
 classes=collections.defaultdict(list)
 for p in profiles:classes[p['internal']].append(p)
 tokens={}
 for k,ps in classes.items():
  ns={p['name'] for p in ps}
  if len(ns)==1 and '' not in ns and all(p['status']=='Confirmed' for p in ps):tokens[k]=next(iter(ns))
 for k,v in labels.items():
  if k.startswith('boss:') and v['internal'] not in tokens:tokens[v['internal']]=v['name']
 compiled=[(re.compile(r'(?<![a-z0-9])'+re.escape(k)+r'(?![a-z0-9])',re.I),v) for k,v in tokens.items()]
 assetnames=collections.defaultdict(set)
 for k,v in verified.items():
  for aid in media[k].get('assetIds',[]):assetnames[aid].add(v['name'])
 assets=read(D/'visual/assets.json');affected=0
 for a in assets:
  previous=a.get('reviewedAliases',[])
  a['aliases']=[v for v in a.get('aliases',[]) if v not in previous]
  ns=set(assetnames.get(a['id'],[]))
  for r in a.get('records',[]):
   v=verified.get(r['table']+':'+str(r['id']))
   if v:r['displayName']=v['name'];ns.add(v['name'])
  text=a.get('name','')+' '+a.get('bundle','')
  for pattern,n in compiled:
   if pattern.search(text):ns.add(n)
  a['reviewedAliases']=sorted(ns)
  a['aliases']=sorted(set(a['aliases'])|ns)
  if ns:affected+=1
 write(D/'visual/assets.json',assets)
 write(D/'reviewed-names.json',dict(snapshot='3.55.0',reviewDate='2026-10-07',entries=labels,skipped=skipped))
 print(dict(accepted=dict(count),skipped=skipped,records=len(verified),artwork=affected))
if __name__=='__main__':main()

