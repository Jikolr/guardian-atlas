"""Build public, static research views from the offline analysis. No original binaries or user settings."""
from pathlib import Path
import json,csv,gzip,shutil,collections,os
BASE=Path(__file__).resolve().parent; SRC=BASE.parent/'guardian-analysis'; OUT=BASE/'dist'; DATA=OUT/'data'; R=DATA/'research';R.mkdir(parents=True,exist_ok=True)
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,obj):
    p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(obj,ensure_ascii=True,separators=(',',':')),encoding='utf-8')
def csvrows(name):return list(csv.DictReader((SRC/'audit'/name).open(encoding='utf-8-sig')))
manifest=read(DATA/'manifest.json')
for p in sorted((SRC/'decoded-static').glob('*.json')):
    obj=read(p); key='static-'+p.stem
    if isinstance(obj,list): records=[{'id':v.get('Id',i) if isinstance(v,dict) else i,'fields':v if isinstance(v,dict) else {'Value':v}} for i,v in enumerate(obj)]
    else:
        records=[]
        for section,value in obj.items():
            values=value if isinstance(value,list) else [value]
            for i,v in enumerate(values):records.append({'id':len(records),'fields':{'Section':section,'Position':i,**(v if isinstance(v,dict) else {'Value':v})}})
    # Keep row IDs unique even for tables with repeated source IDs.
    if len({str(v['id']) for v in records})!=len(records):
        for i,v in enumerate(records):v['id']=i
    fields=sorted({k for r in records for k in r['fields']})
    manifest[key]={'count':len(records),'fields':fields,'source':'static_data/'+p.stem,'title':p.stem,'group':'Decoded tables'}
    write(DATA/(key+'.json'),records)
write(DATA/'manifest.json',manifest)
scripts=csvrows('lua-catalog.csv');functions=collections.defaultdict(list)
for row in csvrows('lua-functions.csv'):functions[row['file']].append({'name':row['name'],'line':int(row['line'])})
script_index=[];chunks=collections.defaultdict(dict)
for i,row in enumerate(scripts):
    key=str(i);chunk=i//100;source=(SRC/'decoded-scripts'/row['file']).read_text(encoding='utf-8')
    chunks[chunk][key]=source
    script_index.append({'id':key,'path':row['file'].replace('\\','/'),'category':row['category'],'lines':int(row['lines']),'chunk':chunk,'functions':functions[row['file']]})
write(R/'scripts.json',script_index)
for chunk,records in chunks.items():write(R/'scripts'/f'{chunk}.json',records)
types=csvrows('managed-types.csv');methods=csvrows('managed-methods.csv');fields=csvrows('managed-fields.csv');addresses={r['index']:r['va'] for r in csvrows('game-method-addresses.csv')}
# Method/field ranges bind nested types precisely even when short type names repeat.
method_by_id={int(x['index']):x for x in methods};field_by_id={int(x['index']):x for x in fields};chunks=collections.defaultdict(dict)
for t in types:
    i=int(t['index']);ms=[method_by_id[j] for j in range(int(t['method_start']),int(t['method_start'])+int(t['method_count']))];fs=[field_by_id[j] for j in range(int(t['field_start']),int(t['field_start'])+int(t['field_count']))]
    for m in ms:m['address']=addresses.get(m['index'],'unmapped')
    chunks[i//300][str(i)]={'methods':ms,'fields':fs}
write(R/'types.json',types)
for chunk,records in chunks.items():
    folder=R/'code';folder.mkdir(parents=True,exist_ok=True);(folder/f'{chunk}.json.gz').write_bytes(gzip.compress(json.dumps(records,ensure_ascii=True,separators=(',',':')).encode(),mtime=0))
maps=read(SRC/'audit/map-decode-summary.json');mapindex=[]
for i,m in enumerate(maps['files']):
    mapindex.append({'id':i,'path':m['source'].replace('\\','/'),'bytes':m['bytes'],'version':m['version'],'references':len(m['references']),'status':'Decoded; object schema partial'})
    write(R/'maps'/f'{i}.json',m['references'])
for m in maps['errors']:mapindex.append({'id':None,'path':m['source'].replace('\\','/'),'status':'Unresolved: '+m['error'],'references':0})
write(R/'maps.json',mapindex)
bundles=collections.defaultdict(collections.Counter)
with (SRC/'audit/bundle-objects.csv').open(encoding='utf-8') as f:
    for row in csv.DictReader(f):bundles[row['bundle']][row['type']]+=1
write(R/'bundles.json',[{'path':k,'objects':sum(v.values()),'types':dict(v)} for k,v in bundles.items()])
write(R/'audit.json',csvrows('file-review-status.csv'))
events=[]
original=Path(os.environ.get('ATLAS_INSTALL_SOURCE',str(BASE.parent/'game-install')))
for i,row in enumerate(csvrows('event-catalog.csv')):
    source=original/row['file'];normalized=SRC/'decoded-events'/source.name
    obj=read(normalized if normalized.exists() else source);write(R/'events'/f'{i}.json',obj)
    events.append({'id':i,'name':source.stem,'normalized':normalized.exists(),'count':row['count']})
write(R/'events.json',events)
for name in ['exps2','weaponenhance','guardianlevel']:write(R/(name+'.json'),read(SRC/'decoded-static'/(name+'.json')))
for name in ['catalog-summary.json','metadata-summary.json']:
    write(R/name,read(SRC/'audit'/name))
bs=read(SRC/'audit/bundle-summary.json');write(R/'bundle-summary.json',{'bundles':bs['bundles'],'types':bs['types'],'errors':bs['errors']})
downloads=OUT/'downloads';downloads.mkdir(exist_ok=True)
for name in ['file-review-status.csv','all-files.csv','table-catalog.csv','lua-catalog.csv','lua-functions.csv','managed-types.csv','managed-methods.csv','managed-fields.csv','game-method-addresses.csv','gameplay-methods.csv','bundle-objects.csv']:
    with (SRC/'audit'/name).open('rb') as a,gzip.open(downloads/(name+'.gz'),'wb') as b:shutil.copyfileobj(a,b)
for p in (SRC/'audit/disassembly').glob('*.asm'):shutil.copyfile(p,downloads/p.name)
for p in (SRC/'decoded-static').glob('LevelExps*.csv'):shutil.copyfile(p,downloads/p.name)
shutil.copyfile(SRC/'RAPPORT-HORS-LIGNE.md',downloads/'offline-report-fr.md')
print('Prepared',len(manifest),'datasets;',len(scripts),'scripts;',len(types),'types;',len(mapindex),'maps;',len(events),'events.')

from sanitize_public_exports import sanitize
sanitize()
