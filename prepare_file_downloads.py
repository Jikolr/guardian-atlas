"""Build public catalogs and separate release ZIPs, never copy archives into dist."""
from pathlib import Path
import csv, hashlib, json, zipfile, struct

BASE=Path(__file__).resolve().parent
ANALYSIS=BASE.parent/'guardian-analysis'
ORIGINAL=BASE.parent.parent/'com.kakaogames.gdtskr'
OUT=BASE.parent/'guardian-release-archives'
WEB=BASE/'dist'
TAG='game-files-3.54.0-snapshot'
LIMIT=250*1024*1024

def build():
    OUT.mkdir(exist_ok=True)
    sources=[]
    allowed={'AssetBundles','Assets','events','GameScript','media','minimap','static_data','Tilemaps','Title'}
    manifests={'files/.index-firstpass','files/Android.checksum','files/Android.index','files/Android.index.etag','files/assetbundle-version','files/assetbundle-version.etag','files/patch-index','files/patch-index.etag'}
    caches={'battleactions-bin','heroes-bin','monsters-bin','npc-bin','strings-bin-enUS'}
    statuses={r['path']:r['status'] for r in csv.DictReader((ANALYSIS/'audit/file-review-status.csv').open(encoding='utf-8-sig'))}
    for r in csv.DictReader((ANALYSIS/'audit/all-files.csv').open(encoding='utf-8-sig')):
        path=r['path'];parts=path.split('/')
        if not (path in manifests or path.startswith('cache/UnityShaderCache/') or (parts[0]=='files' and len(parts)>2 and parts[1] in allowed) or (parts[0]=='cache' and parts[-1] in caches)):continue
        if 'Local settings/state' in statuses.get(path,''):continue
        encrypted='Decrypted and decompressed manifest' in statuses.get(path,'') or parts[1] in {'GameScript','static_data','Tilemaps'} and not path.endswith('.etag')
        group='encrypted' if encrypted else 'unencrypted' if r['type'] in {'UnityFS bundle','PNG','JPEG','MP4 media','JSON','ETag','k1ng cache'} else 'unknown'
        sources.append((group,path,ORIGINAL/path,r['type']))
    for folder in ['decoded','decoded-static','decoded-maps','decoded-scripts','decoded-events']:
        for p in sorted((ANALYSIS/folder).rglob('*')):
            if p.is_file():sources.append(('decrypted',folder+'/'+p.relative_to(ANALYSIS/folder).as_posix(),p,'Recovered / decoded output'))
    for filename in ['.index-firstpass.decoded','Android.checksum.decoded','Android.index.decoded','patch-index.decoded','global-metadata.dat']:
        p=ANALYSIS/'audit'/filename
        if p.exists():sources.append(('decrypted','manifests-and-metadata/'+filename,p,'Recovered manifest / metadata'))
    previous_path=WEB/'data/file-catalog.json'
    previous=json.loads(previous_path.read_text(encoding='utf-8')) if previous_path.exists() else {'files':[],'archives':[]}
    groups={}
    for group,path,p,kind in sources:
        bucket='manifests' if path in manifests else 'UnityShaderCache' if path.startswith('cache/UnityShaderCache/') else path.split('/')[0] if group=='decrypted' else path.split('/')[1] if path.startswith('files/') else 'cache'
        groups.setdefault((group,bucket),[]).append((path,p,kind))
    entries=[];archives=[]
    for (group,bucket),files in sorted(groups.items()):
        chunks=[];chunk=[];size=0
        for row in sorted(files):
            length=row[1].stat().st_size
            if chunk and size+length>LIMIT:chunks.append(chunk);chunk=[];size=0
            chunk.append(row);size+=length
        if chunk:chunks.append(chunk)
        for i,chunk in enumerate(chunks,1):
            name=f'{group}-{bucket}-{i:02d}.zip';target=OUT/name;pending=[]
            old=[r for r in previous['files'] if r.get('archive')==name]
            old_archive=next((a for a in previous['archives'] if a['name']==name),None)
            if target.exists() and old_archive and target.stat().st_size==old_archive['bytes'] and sorted((r['path'],r['bytes']) for r in old)==sorted((path,p.stat().st_size) for path,p,_ in chunk):
                entries+=old;archives.append(old_archive);continue
            with zipfile.ZipFile(target,'w',compression=zipfile.ZIP_STORED,allowZip64=True) as z:
                for path,p,kind in chunk:
                    member=group+'/'+path;z.write(p,member);info=z.getinfo(member)
                    pending.append(dict(section=group,path=path,bytes=info.file_size,kind=kind,archive=name,member=member,headerOffset=info.header_offset,sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
            with target.open('rb') as f:
                for r in pending:
                    f.seek(r.pop('headerOffset'));header=f.read(30);assert header[:4]==b'PK\x03\x04'
                    n,e=struct.unpack_from('<HH',header,26);r['offset']=f.tell()+n+e
            with zipfile.ZipFile(target) as z:assert z.testzip() is None
            entries+=pending;archives.append(dict(name=name,section=group,folder=bucket,bytes=target.stat().st_size,files=len(pending),sha256=hashlib.sha256(target.read_bytes()).hexdigest()))
            print(name,len(pending),flush=True)
    # Already hosted exports can be downloaded individually without an archive.
    for p in sorted(WEB.rglob('*')):
        if not p.is_file() or p.name=='file-catalog.json':continue
        rel=p.relative_to(WEB).as_posix()
        if rel.startswith(('data/','downloads/')):
            entries.append(dict(section='exports',path=rel,bytes=p.stat().st_size,url=rel,kind='Website export / preview'))
    catalog=dict(version=1,releasePublished=previous.get('releasePublished',False),releaseTag=TAG,releaseURL=f'https://github.com/Jikolr/guardian-atlas/releases/tag/{TAG}',releaseBase=f'https://github.com/Jikolr/guardian-atlas/releases/download/{TAG}/',archives=archives,files=entries,notes='Original game content only; local account settings, notification state and analytics are excluded. Unencrypted does not mean public domain. Unknown binaries are classified separately. Decrypted includes decoded cache exports.')
    (WEB/'data/file-catalog.json').write_text(json.dumps(catalog,separators=(',',':')),encoding='utf-8')
    (OUT/'release-manifest.json').write_text(json.dumps({k:v for k,v in catalog.items() if k!='files'},indent=2),encoding='utf-8')
    print('Catalog:',len(entries),'files;',len(archives),'archives',flush=True)

if __name__=='__main__':build()
