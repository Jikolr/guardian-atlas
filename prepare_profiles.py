from pathlib import Path
import json,gzip,re,collections,os
BASE=Path(__file__).resolve().parent;DATA=BASE/'dist/data';SRC=Path(os.environ.get('ATLAS_STATIC_SOURCE',str(BASE.parent/'guardian-analysis/decoded-static')))
def read(p):return json.loads(p.read_text(encoding='utf-8')) if p.exists() else json.loads(gzip.decompress(Path(str(p)+'.gz').read_bytes()))
def write(p,d):p.write_text(json.dumps(d,separators=(',',':'),ensure_ascii=False),encoding='utf-8')
heroes=read(DATA/'heroes.json');text=read(DATA/'text.json');media=read(DATA/'visual/record-media.json')
profiles={r['OriginId']:r for r in read(SRC/'heroprofile.json')};items=read(SRC/'items.json');styles=read(SRC/'battlestyles.json')['BattleStyles'];actions=read(DATA/'actions.json')
action_names={r['fields'].get('Name'):r for r in actions};groups=collections.defaultdict(list)
for r in heroes:groups[r['fields'].get('OriginId',r['id'])].append(r)
short_text={r['fields'].get('Text','').casefold():r['fields']['Text'] for r in text if len(r['fields'].get('Text',''))<70}
manual={'wyverns_purple':('Astoria','User-confirmed identity: wyverns_purple = Astoria'), 'demon_slayer':('Andras','User-confirmed identity; English biography'), 'bridge_messenger':('Seira','English biography and official release notes: https://gdtsglobal.zendesk.com/hc/en-us/articles/60233488458649-2026-07-21-PATCH-NOTE')}
curated={r['internal']:r for r in read(BASE/'name-evidence.json')}
text_by_id={str(r['id']):r for r in text}
result=[];aliases={}
for origin,variants in groups.items():
 variants.sort(key=lambda r:(r['fields'].get('Rank',0),r['id']));base=next((r for r in variants if r['id']==origin),variants[0]);f=base['fields'];key=f.get('Class') or f.get('Name') or str(origin);display,evidence=manual.get(key,('',''))
 candidate=key.replace('_',' ');matches=[]
 if not display and candidate.casefold() in short_text:
  candidate=short_text[candidate.casefold()]
  matches=[r for r in text if r['fields'].get('Text','').startswith(candidate+' is ') and len(r['fields']['Text'])>300]
  if matches:display=candidate;evidence='Exact English name spelling and matching biography opening; not a decoded localization-key join'
 if display and not matches:matches=[r for r in text if r['fields'].get('Text','').startswith(display+' is ') and len(r['fields']['Text'])>300]
 bios=list({r['fields']['Text']:r for r in matches}.values());bio=bios[0] if len(bios)==1 else None
 status='Confirmed' if key in manual else 'English spelling match' if display else 'Unmapped'
 if key in curated:
  c=curated[key];b=text_by_id[str(c['biographyId'])];body=b['fields']['Text']
  assert c['name'] in body and c['quote'].casefold() in body.casefold(),c
  display=c['name'];bio=b;status=c['status'];evidence=f"Inferred from internal name {key} and English biography #{c['biographyId']}: ‘{c['quote']}’. No decoded localization-key link; this identity is not independently confirmed."

 classes={r['fields'].get('Class') for r in variants};battle_styles=[s for s in styles if s.get('Class') in classes];names=set()
 for s in battle_styles:
  for k in ['BattleActions','ClassBattleActions','ManualBattleActions']:
   for n in s.get(k) or []:names.add(n)
 skills=[{'name':n,'record':action_names[n]['id']} for n in sorted(names) if n in action_names]
 linked=[dict(id=i['Id'],name=i['Name'],exclusive=i.get('ExclusiveCharacterId')==origin,image=media.get('static-items:'+str(i['Id']),{}).get('image')) for i in items if i.get('ExclusiveCharacterId')==origin or i['Id'] in {r['fields'].get('DefaultWeapon1') for r in variants}]
 info=dict(id=origin,name=display,internal=key,evidence=evidence,status=status,variants=variants,image=media.get('heroes:'+str(base['id']),{}).get('image'),profile=profiles.get(origin),biography=bio['fields']['Text'] if bio else None,biographyId=bio['id'] if bio else None,biographyNote='Matched from the English biography text; story-key mapping is not decoded.',skills=skills,battleStyles=battle_styles,weapons=linked)
 result.append(info)
 for r in variants:
  aliases[str(r['id'])]=dict(name=display,profileId=origin,evidence=evidence)
  if 'heroes:'+str(r['id']) in media:media['heroes:'+str(r['id'])].update(name=display,profileId=origin,aliasSource=evidence)
out=DATA/'characters.json.gz';out.write_bytes(gzip.compress(json.dumps(result,separators=(',',':'),ensure_ascii=False).encode(),mtime=0));write(DATA/'character-aliases.json',aliases);write(DATA/'visual/record-media.json',media)
records=read(DATA/'visual/records.json')
for r in records:
 if r['table']=='heroes' and str(r['id']) in aliases:r['displayName']=aliases[str(r['id'])]['name'];r['profileId']=aliases[str(r['id'])]['profileId']
write(DATA/'visual/records.json',records)
assets=read(DATA/'visual/assets.json')
for asset in assets:
 normalized=(asset.get('name','')+' '+asset.get('bundle','')).lower().replace('_','')
 for internal,display in [('wyvernspurple','Astoria'),('bridgemessenger','Seira')]:
  if internal in normalized:asset['aliases']=list(dict.fromkeys(asset.get('aliases',[])+[display]))
 for record in asset.get('records',[]):
  if record.get('table')=='heroes' and str(record['id']) in aliases:record['displayName']=aliases[str(record['id'])]['name']
write(DATA/'visual/assets.json',assets)
print('Profiles',len(result),'mapped',sum(bool(r['name']) for r in result),'biographies',sum(bool(r['biography']) for r in result),'bytes',out.stat().st_size)
print([(r['internal'],r['name']) for r in result if r['name']])


# Preserve the reviewed identities when rebuilding profiles.
if (BASE/"name-review-decisions.json").exists():
 from apply_reviewed_names import main as apply_reviewed_names
 apply_reviewed_names()
