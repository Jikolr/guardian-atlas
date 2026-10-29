"""Verify the website against independently decoded sources and historical link IDs."""
from pathlib import Path
import argparse,collections,gzip,hashlib,json,struct,subprocess

B=Path(__file__).resolve().parent;D=B/'dist/data'
def read(p):
    p=Path(p)
    if not p.exists():p=Path(str(p)+'.gz')
    raw=p.read_bytes()
    return json.loads(gzip.decompress(raw) if p.suffix=='.gz' else raw)
def canon(x):return json.dumps(x,sort_keys=True,ensure_ascii=False,separators=(',',':'))
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify(work,version):
    source=work/'phone/decoded/files/static_data';tables=work/'phone/tables/files/static_data'
    manifest=read(D/'manifest.json');checked=collections.Counter()
    for key,m in manifest.items():
        rows=read(B/'dist'/m.get('url','data/'+key+'.json'))
        assert len(rows)==m['count'],key
        assert len({str(r['id']) for r in rows})==len(rows),key
        assert m['version']==version,key
        if key.startswith('static-'):
            name=key.removeprefix('static-');obj=read(source/name)
            if isinstance(obj,list):
                assert collections.Counter(canon(r['fields']) for r in rows)==collections.Counter(canon(v if isinstance(v,dict) else {'Value':v}) for v in obj),key
            else:
                expected=[]
                for section,value in obj.items():
                    for i,item in enumerate(value if isinstance(value,list) else [value]):
                        # Some game records own a Position field. Preserve it;
                        # it legitimately overrides the synthetic list position.
                        expected.append({'Section':section,'Position':i,**(item if isinstance(item,dict) else {'Value':item})})
                assert collections.Counter(canon(r['fields']) for r in rows)==collections.Counter(canon(v) for v in expected),key
        else:
            name={'heroes':'heroes-bin','actions':'battleactions-bin','monsters':'monsters-bin','npcs':'npc-bin','text':'strings-bin-enUS'}[key]
            obj=read(tables/(name+'.json'));container=(source/name).read_bytes()
            assert container[:4]==b'k1ng'
            count=struct.unpack_from('<I',container,8)[0];assert count==len(rows)==len(obj)
            ids=[struct.unpack_from('<I',container,16+i*16)[0] for i in range(count)]
            assert {str(r['id']):r['fields'] for r in rows}=={str(i):v for i,v in zip(ids,obj)},key
        checked['tables']+=1;checked['table_records']+=len(rows)
    scripts=read(D/'research/scripts.json');byname={r['path'].replace('\\','/').casefold():r for r in scripts};chunks={}
    for p in (work/'phone/decoded/files').rglob('*.lua'):
        rel=p.relative_to(work/'phone/decoded/files').as_posix()
        name=rel.removeprefix('GameScript/') if rel.startswith('GameScript/') else '_immediates/'+p.name if rel.startswith('media/immediates/') else None
        if name is None:continue
        row=byname[name.casefold()];chunk=row['chunk']
        if chunk not in chunks:chunks[chunk]=read(D/'research/scripts'/f'{chunk}.json')
        assert chunks[chunk][row['id']].encode('utf8')==p.read_bytes(),name
        checked['scripts']+=1
    prior=read(work/'website-import/baseline/research/scripts.json')
    for row in prior:assert byname[row['path'].replace('\\','/').casefold()]['id']==row['id'],row['path']
    checked['preserved_script_links']=len(prior)
    for table,field in [('static-battleactions','Name'),('static-projectiles','Name'),
                        ('static-battleais','Name'),('static-charactertreeconfig','OriginId'),
                        ('static-heroprofile','OriginId')]:
        old=json.loads(subprocess.check_output(['git','show','HEAD:dist/data/'+table+'.json'],cwd=B))
        current=read(D/(table+'.json'))
        old_names=collections.Counter(r['fields'].get(field) for r in old)
        new_names=collections.Counter(r['fields'].get(field) for r in current)
        ids={r['fields'].get(field):r['id'] for r in current}
        for r in old:
            name=r['fields'].get(field)
            if name is not None and old_names[name]==new_names[name]==1:
                assert ids[name]==r['id'],(table,name,'Public record ID changed')
                checked['preserved_named_record_links']+=1
    for name in ['assets','icons','records','record-media']:
        entries=read(D/'visual'/(name+'.json'))
        for r in entries.values() if isinstance(entries,dict) else entries:
            for field in ['image','thumbnail']:
                if r.get(field):assert (D/'visual'/r[field]).is_file(),(name,r[field]);checked['image_references']+=1
    for r in read(D/'visual/maps.json'):
        if r['status']!='ready':continue
        payload=read(D/'visual/maps'/(r['name']+'.json'))
        p=work/'phone/decoded/files/Tilemaps'/(r['name']+'.bytes')
        if not p.exists():p=work/'apk/decoded/com.kakaogames.gdtskr/assets/Tilemaps'/(r['name']+'.bytes')
        assert p.exists(),r['name']
        assert digest(p)==payload['sha256'],r['name']
        assert payload['parsedBytes']==p.stat().st_size,r['name']
        checked['maps']+=1
    text={str(r['id']):r['fields']['Text'] for r in read(D/'text.json')}
    profiles=read(D/'characters.json.gz')
    for p in profiles:
        if p.get('biographyId') is not None:assert p['biography']==text[str(p['biographyId'])],p['internal']
    new=next(p for p in profiles if p['internal']=='indaver_journalist')
    assert {r['id'] for r in new['variants']}=={707,708,709,20707}
    assert new.get('image') and new.get('weapons') and all(w.get('image') for w in new['weapons']),new['internal']
    checked['profiles']=len(profiles)
    orbital=read(D/'orbital-lift.json')
    for table,names in orbital['sourceLinks'].items():
        indexed={str(r['id']):r['fields'] for r in read(D/(table+'.json'))}
        field='Class' if table=='static-battlestyles' else 'Name'
        for name,ident in names.items():assert indexed[str(ident)].get(field)==name,(table,name,ident)
        checked['orbital_source_links']+=len(names)
    for current in [D/'file-catalog.json',work/'packs/file-catalog.pending.json']:
        catalog=read(current);seen=set()
        for r in catalog['files']:
            key=r['section'],r['path'];assert key not in seen,(current,key);seen.add(key)
            if r.get('url') and not r['url'].startswith('http'):
                p=B/'dist'/r['url'];assert p.is_file(),(current,r['url'])
                assert p.stat().st_size==r['bytes'],(current,r['url'],r['bytes'],p.stat().st_size)
            if r.get('archive'):assert any(a['name']==r['archive'] for a in catalog['archives']),r['archive']
        checked['catalog_entries']+=len(seen)
    result=dict(version=version,status='passed',checks=dict(checked))
    (work/'website-verification.json').write_text(json.dumps(result,indent=2),encoding='utf8')
    print(json.dumps(result,indent=2))

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--work',type=Path,required=True);p.add_argument('--version',required=True);a=p.parse_args();verify(a.work,a.version)
