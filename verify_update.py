"""Cross-check published data against captured 3.55.0 evidence, not importer output."""
import gzip,json,hashlib,struct,subprocess
from pathlib import Path
B=Path(__file__).resolve().parent;W=B/'dist';D=W/'data'
R=B.parent/'guardian-update-review/outputs/20261002-144030-522b69'
def read(p):return json.loads(p.read_text(encoding='utf8')) if p.exists() else json.loads(gzip.decompress(Path(str(p)+'.gz').read_bytes()))
inv={r['path']:r for r in read(R/'new-inventory.json')}
for table,cache in {'heroes':'heroes-bin','actions':'battleactions-bin','monsters':'monsters-bin','npcs':'npc-bin','text':'strings-bin-enUS'}.items():
    raw=read(R/inv['install/cache/'+cache]['decoded']);actual=read(D/(table+'.json'))
    assert [r['fields'] for r in actual]==raw,table
    assert len({r['id'] for r in actual})==len(actual),table
manifest=read(D/'manifest.json')
for name,row in manifest.items():
    records=read(D/(name+'.json'));assert row['count']==len(records),name
    assert len({str(r['id']) for r in records})==len(records),name
    if name.startswith('static-'):
        source=inv.get('install/files/static_data/'+name.removeprefix('static-'))
        if source and source.get('decoded'):
            original=read(R/source['decoded'])
            if isinstance(original,list):assert [r['fields'] for r in records]==original,name
text={r['id']:r['fields']['Text'] for r in read(D/'text.json')}
profiles=json.loads(gzip.decompress((D/'characters.json.gz').read_bytes()))
for profile in profiles:
    if profile.get('biographyId') is not None:assert profile['biography']==text[profile['biographyId']],profile['internal']
new=next(p for p in profiles if p['internal']=='wyverns_purple')
assert {r['id'] for r in new['variants']}=={701,702,703,20701}
assert new['image'] and new['weapons'] and all(w.get('image') for w in new['weapons'])
for name in ['assets','records','record-media']:
    entries=read(D/'visual'/(name+'.json'))
    for row in entries.values() if isinstance(entries,dict) else entries:
        for k in ['image','thumbnail']:
            if row.get(k):assert (D/'visual'/row[k]).is_file(),(name,row[k])
scripts=read(D/'research/scripts.json');chunks={}
for row in scripts:
    chunk=row['chunk']
    if chunk not in chunks:chunks[chunk]=read(D/'research/scripts'/f'{chunk}.json')
    assert row['id'] in chunks[chunk]
baseline=json.loads(subprocess.check_output(['git','show','HEAD:dist/data/research/scripts.json'],cwd=B).decode('utf8'))
byid={r['id']:r for r in scripts}
for row in baseline:assert byid[row['id']]['path']==row['path'],'Historical script link changed'
catalog=read(D/'file-catalog.json');seen=set()
for row in catalog['files']:
    key=(row['section'],row['path']);assert key not in seen,key;seen.add(key)
    if row.get('url') and not row['url'].startswith('http'):
        p=W/row['url'];assert p.is_file(),str(p)
        assert p.stat().st_size==row['bytes'],str(p)
        if row.get('sha256'):assert hashlib.sha256(p.read_bytes()).hexdigest()==row['sha256'],str(p)
    if row.get('archive'):assert row.get('version')=='3.54.0'
assert not read(D/'update-3.55.0.json')['visuals']['errors']
maps=W/'data/visual/maps.json'
assert maps.read_bytes()==subprocess.check_output(['git','show','HEAD:dist/data/visual/maps.json'],cwd=B),'Unchanged map index modified'
print('PASS: snapshot records, unique IDs, biographies, hero variants/equipment, image links, stable Lua links, download sizes/hashes and unchanged maps.')
