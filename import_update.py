"""Import a reviewed comparison into Atlas. Preserve research IDs and old APK evidence.

Usage: python import_update.py data|visuals|finish
Inputs are pinned to the reviewed 3.55.0 snapshot; every payload is hash-checked.
"""
from pathlib import Path
import collections, hashlib, json, re, sys, shutil, gzip,struct,subprocess

B=Path(__file__).resolve().parent
W=B/'dist'; D=W/'data'; A=B.parent/'guardian-analysis'
RUN=B.parent/'guardian-update-review/outputs/20261002-144030-522b69'
SNAP=B.parent/'guardian-update-review/new-version'
VERSION='3.55.0'
STATE=A/'updates/3.55.0'; STATE.mkdir(parents=True,exist_ok=True)
def read(p):return json.loads(p.read_text(encoding='utf8')) if p.exists() else json.loads(gzip.decompress(Path(str(p)+'.gz').read_bytes()))
def write(p,v):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(v,ensure_ascii=False,separators=(',',':')),encoding='utf8')
def digest(b):return hashlib.sha256(b).hexdigest()
inventory={r['path']:r for r in read(RUN/'new-inventory.json')}
changes=[json.loads(l) for l in (RUN/'changes.jsonl').read_text(encoding='utf8').splitlines()]
changed={r['path']:r for r in changes}
def decoded(r):
    assert r['status']=='decoded',r['path']
    b=(RUN/r['decoded']).read_bytes();assert digest(b)==r['content_sha256']
    return b
def original(r):
    # Use captured changed payloads, never silently consume a subsequently modified export.
    c=changed.get(r['path'],{});p=RUN/c['payload'] if c.get('payload') else SNAP/r['source']
    data=p.read_bytes();assert digest(data)==r['sha256'],r['path']
    return data
def rows(obj):
    if isinstance(obj,list):result=[{'id':v.get('Id',i) if isinstance(v,dict) else i,'fields':v if isinstance(v,dict) else {'Value':v}} for i,v in enumerate(obj)]
    else:
        result=[]
        for section,value in obj.items():
            for i,v in enumerate(value if isinstance(value,list) else [value]):
                result.append({'id':len(result),'fields':{'Section':section,'Position':i,**(v if isinstance(v,dict) else {'Value':v})}})
    if len({str(r['id']) for r in result})!=len(result):
        for i,r in enumerate(result):r['id']=i
    return result

def data_phase():
    manifest=read(D/'manifest.json');tables=[]
    # Keep the baseline analysis untouched; materialize current decoded tables separately.
    current=STATE/'decoded-static';current.mkdir(exist_ok=True)
    for p in (A/'decoded-static').glob('*.json'):
        if not (current/p.name).exists():shutil.copyfile(p,current/p.name)
    for path,r in inventory.items():
        if not path.startswith('install/files/static_data/') or r['status']!='decoded' or r.get('format')!='json':continue
        name=path.rsplit('/',1)[-1]
        if '-bin' in name:continue
        obj=json.loads(decoded(r));write(current/(name+'.json'),obj)
        key='static-'+name;records=rows(obj)
        if path in changed or key not in manifest or read(D/(key+'.json'))!=records:
            write(D/(key+'.json'),records);tables.append(key)
        manifest[key]={'count':len(records),'fields':sorted({k for v in records for k in v['fields']}),'source':'static_data/'+name,'title':name,'group':'Decoded tables','version':VERSION}
    oldtext={r['Id']:r['Text'] for r in read(A/'decoded/strings-bin-enUS.json')}
    newtext=json.loads(decoded(inventory['install/cache/strings-bin-enUS']))
    bybody=collections.defaultdict(list)
    for r in newtext:bybody[r['Text']].append(r['Id'])
    evidence=json.loads(subprocess.check_output(['git','show','HEAD:name-evidence.json'],cwd=B).decode('utf8'))
    for e in evidence:
        body=oldtext[e['biographyId']];ids=bybody.get(body,[])
        assert ids,('Biography changed; needs review',e['name'])
        e['biographyId']=ids[0]
    write(B/'name-evidence.json',evidence)
    for key,name in {'heroes':'heroes-bin','actions':'battleactions-bin','monsters':'monsters-bin','npcs':'npc-bin','text':'strings-bin-enUS'}.items():
        r=inventory['install/cache/'+name];obj=json.loads(decoded(r));container=original(r)
        assert container[:4]==b'k1ng' and struct.unpack_from('<I',container,8)[0]==len(obj)
        ids=[struct.unpack_from('<I',container,16+i*16)[0] for i in range(len(obj))]
        records=[{'id':ident,'fields':v} for ident,v in zip(ids,obj)]
        assert len({v['id'] for v in records})==len(records)
        if r['path'] in changed or read(D/(key+'.json'))!=records:write(D/(key+'.json'),records);tables.append(key)
        manifest[key]={'count':len(records),'fields':sorted({k for v in obj for k in v}),'source':name,'version':VERSION}
    write(D/'manifest.json',manifest)
    for name in ['exps2','weaponenhance','guardianlevel']:write(D/'research'/(name+'.json'),read(current/(name+'.json')))
    index=read(D/'research/scripts.json');byname={r['path'].replace('\\','/').casefold():r for r in index};chunks={};updated=[];added=[]
    nextid=max(int(r['id']) for r in index)+1
    for path,r in inventory.items():
        if not path.startswith('install/files/GameScript/') or not path.endswith('.encrypted'):continue
        name=path.removeprefix('install/files/GameScript/').removesuffix('.encrypted')+'.lua'
        source=decoded(r).decode('utf8');row=byname.get(name.casefold())
        if row is None:
            row={'id':str(nextid),'path':name,'chunk':nextid//100};nextid+=1;index.append(row);byname[name.casefold()]=row;added.append(name)
        chunk=row['chunk'];cp=D/'research/scripts'/f'{chunk}.json'
        if chunk not in chunks:chunks[chunk]=read(cp) if cp.exists() or Path(str(cp)+'.gz').exists() else {}
        if chunks[chunk].get(row['id'])!=source:updated.append(name)
        chunks[chunk][row['id']]=source
        row.update(category=name.split('/')[0] if '/' in name else 'root controllers',lines=len(source.splitlines()),version=VERSION,functions=[{'name':m.group(1),'line':i} for i,line in enumerate(source.splitlines(),1) if (m:=re.search(r'^\s*(?:local\s+)?function\s+([\w.:]+)',line))])
    write(D/'research/scripts.json',index)
    for chunk,obj in chunks.items():
        cp=D/'research/scripts'/f'{chunk}.json'
        if not cp.exists() or read(cp)!=obj:write(cp,obj)
    cat=read(D/'research/catalog-summary.json');cat.update(lua_files=len(index),lua_lines=sum(r['lines'] for r in index),lua_function_definitions=sum(len(r['functions']) for r in index),lua_categories=dict(collections.Counter(r['category'] for r in index)),dataVersion=VERSION,nativeEvidenceVersion='3.54.0');write(D/'research/catalog-summary.json',cat)
    write(STATE/'data-result.json',{'tables':tables,'updatedScripts':updated,'addedScripts':added,'totalScripts':len(index)})
    print('Tables',len(tables),'updated scripts',len(updated),'new script paths',len(added),flush=True)

def visual_phase():
    sys.path.insert(0,str(A/'tool-libs'));import UnityPy
    from PIL import Image
    out=D/'visual';assets=read(out/'assets.json');icons=read(out/'icons.json');bundles=read(D/'research/bundles.json');bybundle={r['path']:r for r in bundles};errors=[];processed=[];images=0
    for path,c in changed.items():
        if not path.startswith('install/files/AssetBundles/') or path.endswith('.etag') or path not in inventory:continue
        r=inventory[path];raw=original(r)
        if not raw.startswith(b'UnityFS'):continue
        name=path.removeprefix('install/');env=UnityPy.load(raw);counts=collections.Counter(o.type.name for o in env.objects)
        bybundle[name]={'path':name,'objects':sum(counts.values()),'types':dict(counts),'version':VERSION}
        newassets=[];newicons=[];objects={o.path_id:o for o in env.objects};textures={}
        for o in env.objects:
            if o.type.name in ('Texture2D','Sprite'):
                aid=digest((name+':'+str(o.path_id)).encode())[:20];entry={'id':aid,'bundle':name,'type':o.type.name,'pathId':str(o.path_id),'name':'','status':'unavailable','version':VERSION}
                try:
                    d=o.read();entry['name']=d.m_Name;im=d.image;entry.update(width=im.width,height=im.height)
                    im.thumbnail((768,768));im.save(out/'images'/f'{aid}.webp',format='WEBP',quality=82,method=3);entry.update(image=f'images/{aid}.webp',status='ready',previewWidth=im.width,previewHeight=im.height);images+=1
                except Exception as e:entry['error']=str(e)[:180];errors.append({'bundle':name,'object':str(o.path_id),'error':str(e)})
                newassets.append(entry)
            if '/spritesheets/' not in name or o.type.name!='MonoBehaviour':continue
            t=o.read_typetree()
            if not t.get('mSprites') or not t.get('material',{}).get('m_PathID'):continue
            mp=t['material'];assert mp['m_FileID']==0
            mt=objects[mp['m_PathID']].read_typetree();ptr=dict(mt['m_SavedProperties']['m_TexEnvs'])['_MainTex']['m_Texture'];assert ptr['m_FileID']==0
            tid=ptr['m_PathID']
            if tid not in textures:textures[tid]=objects[tid].read().image
            im=textures[tid]
            for sp in t['mSprites']:
                x,y,w,h=[sp[k] for k in ['x','y','width','height']]
                assert w>0 and h>0 and 0<=x<x+w<=im.width and 0<=y<y+h<=im.height
                key=digest((name+str(o.path_id)+sp['name']).encode())[:20];crop=im.crop((x,y,x+w,y+h));crop.thumbnail((768,768));crop.save(out/'images'/f'{key}.webp',quality=90)
                newicons.append({'id':key,'name':sp['name'],'bundle':name,'type':'Atlas sprite','status':'ready','image':f'images/{key}.webp','width':w,'height':h,'atlas':t['m_Name'],'rect':[x,y,w,h],'version':VERSION});images+=1
        assets=[r for r in assets if r['bundle']!=name]+newassets;icons=[r for r in icons if r['bundle']!=name]+newicons;processed.append(name)
        print('Visual bundle',name,len(newassets),len(newicons),flush=True)
    for path,c in changed.items():
        if not path.startswith('install/files/media/') or not path.lower().endswith(('.png','.jpg','.jpeg')):continue
        import io
        name=path.removeprefix('install/');raw=original(inventory[path]);im=Image.open(io.BytesIO(raw));w,h=im.size;im.thumbnail((768,768));aid=digest(name.encode())[:20];im.save(out/'images'/f'{aid}.webp',quality=85)
        assets=[r for r in assets if r['id']!=aid]+[dict(id=aid,bundle=name,name=Path(name).name,type='Image',status='ready',image=f'images/{aid}.webp',width=w,height=h,previewWidth=im.width,previewHeight=im.height,version=VERSION)];images+=1
    write(out/'assets.json',assets);write(out/'icons.json',icons);write(D/'research/bundles.json',list(bybundle.values()))
    write(STATE/'visual-result.json',{'bundles':processed,'imagesWritten':images,'errors':errors})
    print('Images written',images,'errors',len(errors),flush=True)

def finish_phase():
    result=read(STATE/'data-result.json');visual=read(STATE/'visual-result.json');catalog=read(D/'file-catalog.json')
    # Historical release links retain their old content identity. New public game payloads
    # are direct downloads; account files, shader caches and executable binaries stay local.
    additions=[]
    for path,c in changed.items():
        if path not in inventory or not path.startswith('install/files/'):continue
        rel=path.removeprefix('install/');family=rel.split('/')[1]
        if family not in {'AssetBundles','GameScript','static_data','media','Tilemaps','events','Title','minimap'} or rel.endswith('.etag'):continue
        raw=original(inventory[path]);dest=W/'downloads/3.55.0'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(raw)
        section='encrypted' if family in {'GameScript','static_data','Tilemaps'} else 'unencrypted'
        entry=dict(section=section,path=rel,bytes=len(raw),url=dest.relative_to(W).as_posix(),kind='3.55.0 original game content',version=VERSION,sha256=digest(raw))
        catalog['files']=[r for r in catalog['files'] if not (r['section']==section and r['path']==rel)];catalog['files'].append(entry);additions.append(rel)
    for r in catalog['files']:
        if r.get('archive'):r.setdefault('version','3.54.0');r['kind']=r['kind'].removesuffix(' · 3.54.0 archive')+' · 3.54.0 archive'
    evidence=read(D/'research/evidence.json')
    for e in evidence:e.setdefault('version','3.54.0')
    summary={'version':VERSION,'package':'com.kakaogames.gdtskr','previous':'3.54.0','comparisonRun':RUN.name,'tables':result['tables'],'scriptsUpdated':len(result['updatedScripts']),'scriptPathsAdded':len(result['addedScripts']),'visuals':visual,'originalDownloads':len(additions),'limitations':['Added files describe differences between captures, not necessarily newly released content.','Maps are unchanged in this comparison.','Native code, assembly and historical behavior reports remain 3.54.0 evidence; the damage simulator remains hidden.','Unchanged original downloads use the historical 3.54.0 release; changed supported game files are direct 3.55.0 downloads.']}
    write(D/'update-3.55.0.json',summary)
    report='# Guardian Atlas — 3.55.0 data update\n\nPackage: `com.kakaogames.gdtskr`. Imported from the reviewed APK + downloaded-data comparison.\n\n'
    report+=f"Updated {len(result['tables'])} website tables, {len(result['updatedScripts'])} Lua sources ({len(result['addedScripts'])} new paths), and {len(visual['bundles'])} Unity bundles. Exported {visual['imagesWritten']} image previews/crops.\n\n"
    report+='## What to explore\n\n- `wyverns_purple` hero stages, Myth stage, illustrations and linked items.\n- Updated hero trees, equipment, buffs, projectiles, raid schedules, events and XP data.\n- Additional Memorial Carp Girl assets and event artwork.\n- Lua sources retain their existing website entry IDs.\n- Biographies were rejoined by exact text after localization IDs changed.\n\n## Updated tables\n\n'+'\n'.join('- '+t for t in result['tables'])+'\n\n## Scope and limits\n\n'+'\n'.join('- '+x for x in summary['limitations'])
    ep=D/'research/evidence/Reports-update-3.55.0.md';ep.write_text(report,encoding='utf8');evidence=[r for r in evidence if r['path']!=ep.name];evidence.insert(0,dict(path=ep.name,name='3.55.0 — website update and coverage',category='Reports',url=ep.relative_to(W).as_posix(),bytes=ep.stat().st_size,note='Reviewed snapshot import; older native research is explicitly retained as historical.',version=VERSION));write(D/'research/evidence.json',evidence)
    # Serve current recovered Lua individually as well as inside research chunks.
    for path in result['updatedScripts']:
        source=inventory.get('install/files/GameScript/'+path.removesuffix('.lua')+'.encrypted')
        if source is None:source=next(r for k,r in inventory.items() if k.casefold()==('install/files/GameScript/'+path.removesuffix('.lua')+'.encrypted').casefold())
        dest=W/'downloads/3.55.0/decoded-scripts'/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(decoded(source))
        rel='decoded-scripts/'+path;catalog['files']=[r for r in catalog['files'] if not (r['section']=='decrypted' and r['path'].casefold()==rel.casefold())];catalog['files'].append(dict(section='decrypted',path=rel,bytes=dest.stat().st_size,url=dest.relative_to(W).as_posix(),kind='3.55.0 recovered Lua',version=VERSION))
    # Current decoded tables use the existing website exports, without duplicating large JSONs.
    for key in result['tables']:
        rel=('decoded-static/'+key.removeprefix('static-')+'.json') if key.startswith('static-') else 'decoded/'+{'heroes':'heroes-bin','actions':'battleactions-bin','text':'strings-bin-enUS','monsters':'monsters-bin','npcs':'npc-bin'}[key]+'.json'
        catalog['files']=[r for r in catalog['files'] if not (r['section']=='decrypted' and r['path']==rel)]
        catalog['files'].append(dict(section='decrypted',path=rel,bytes=(D/(key+'.json')).stat().st_size,url='data/'+key+'.json',kind='3.55.0 decoded table (website record wrappers)',version=VERSION))
    exports={r['path']:r for r in catalog['files'] if r['section']=='exports'}
    for p in D.rglob('*'):
        if p.is_file() and p.name!='file-catalog.json':
            rel=p.relative_to(W).as_posix();exports[rel]=dict(section='exports',path=rel,bytes=p.stat().st_size,url=rel,kind='Website export / preview')
    catalog['files']=[r for r in catalog['files'] if r['section']!='exports']+list(exports.values());catalog['currentVersion']=VERSION
    catalog['notes']='Current website data: 3.55.0. Changed supported files are direct downloads; archived files remain the labeled 3.54.0 snapshot. Account settings and telemetry are excluded.'
    write(D/'file-catalog.json',catalog)
    compress_text()
    print(json.dumps(summary,ensure_ascii=True),flush=True)

def compress_text():
    # Avoid crossing the Pages size budget by storing the large text table losslessly.
    p=D/'text.json';packed=D/'text.json.gz'
    if p.exists():
        raw=p.read_bytes();packed.write_bytes(gzip.compress(raw,mtime=0));assert gzip.decompress(packed.read_bytes())==raw
        assert p.resolve().parent==D.resolve();p.unlink()
    manifest=read(D/'manifest.json');manifest['text'].update(url='data/text.json.gz',encoding='gzip');write(D/'manifest.json',manifest)
    catalog=read(D/'file-catalog.json')
    scriptroot=(D/'research/scripts').resolve()
    for source in scriptroot.glob('*.json'):
        assert source.resolve().parent==scriptroot
        raw=source.read_bytes();target=source.with_suffix('.json.gz');target.write_bytes(gzip.compress(raw,mtime=0));assert gzip.decompress(target.read_bytes())==raw;source.unlink()
    for r in catalog['files']:
        if r.get('url')=='data/text.json':
            r.update(url='data/text.json.gz',path=r['path']+'.gz',bytes=packed.stat().st_size,kind='3.55.0 decoded English text (gzip JSON)')
        if r.get('url')=='data/manifest.json':r['bytes']=(D/'manifest.json').stat().st_size
        if r.get('url','').startswith('data/research/scripts/') and r['url'].endswith('.json'):
            r.update(url=r['url']+'.gz',path=r['path']+'.gz',bytes=(W/(r['url']+'.gz')).stat().st_size,kind='Recovered Lua source chunk (gzip JSON)')
    write(D/'file-catalog.json',catalog)

if __name__=='__main__':
    {'data':data_phase,'visuals':visual_phase,'finish':finish_phase,'compress':compress_text}[sys.argv[1]]()
