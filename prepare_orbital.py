"""Join tower floors to enemy specs and existing artwork without inferring combat stats."""
import json
from import_snapshot import write
from pathlib import Path
P=Path(__file__).resolve().parent/'dist/data'
def read(name):return json.loads((P/name).read_text(encoding='utf-8'))
def table(name,key='Id'):return {r['fields'][key]:r['fields'] for r in read(name)}
floors=[r['fields'] for r in read('static-infinitytowerfloors.json')]
specs=table('monsters.json'); tower=table('static-infinitytowermonsters.json','MonsterId')
media=read('visual/record-media.json'); items=table('static-items.json'); options=table('static-options.json')
enemies={}
for mid,t in tower.items():
 s=specs.get(t['SpecId'],{});m=media.get('monsters:'+str(t['SpecId']),{})
 name=s.get('Name','Unknown enemy');clean=name.removeprefix('it_').removeprefix('boss_').removeprefix('mirror_')
 for suffix in ['_mirror_rift','_myth_rift','_rift']:clean=clean.removesuffix(suffix)
 enemies[mid]={'tower':t,'spec':s,'name':m.get('name') or clean.replace('_',' ').title(),'image':m.get('thumbnail') or m.get('image')}
usedItems={r['ItemId'] for f in floors for r in f.get('Rewards',[])}
usedOptions={o['OptionId'] for f in floors for m in f['Monsters'] for o in m.get('Options',[])}
out={'floors':floors,'enemies':enemies,'items':{i:{'record':items.get(i,{}),'media':media.get('static-items:'+str(i),{})} for i in usedItems},'options':{i:options.get(i,{}) for i in usedOptions}}
assert all(m['MonsterId'] in enemies for f in floors for m in f['Monsters'])
assert len({f['Floor'] for f in floors})==len(floors)
out['sourceLinks']={}
for source,key in [('static-battleactions','Name'),('static-battleais','Name'),('static-battlestyles','Class')]:
 rows=read(source+'.json');by_name={};ambiguous=set()
 for row in rows:
  name=row['fields'].get(key)
  if not name:continue
  if name in by_name:ambiguous.add(name)
  by_name[name]=row['id']
 out['sourceLinks'][source]={name:ident for name,ident in by_name.items() if name not in ambiguous}
write(P/'orbital-lift.json',out)
print(f'{len(floors)} floors; {len(enemies)} enemy definitions; all floor references joined.')

# Orbital-only equipment snapshot; calculated stats stay in the client.
weapon_ids={e['spec'].get(k) for e in enemies.values() for k in ('DefaultWeapon1','DefaultWeapon2')}
weapons={'items':{i:items[i] for i in weapon_ids if i in items},
 'media':{i:media['static-items:'+str(i)] for i in weapon_ids if 'static-items:'+str(i) in media},
 'scales':{r['id']:r['fields']['Value'] for r in read('static-itemlevelscalefactor.json')}}
write(P/'orbital-weapons.json',weapons)
import runpy
runpy.run_path(str(Path(__file__).with_name('prepare_orbital_debuffs.py')))
