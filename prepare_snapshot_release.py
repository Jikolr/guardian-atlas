
"""Prepare a new, verified release without switching live download links.
Usage: python prepare_snapshot_release.py
Outputs stay outside the website repository. No credentials or keys are exported.
"""
from pathlib import Path
import json,hashlib,zipfile,struct,collections,os,ast
B=Path(__file__).resolve().parent
RUN=B.parent/'guardian-update-review/outputs/20261002-144030-522b69'
SNAP=B.parent/'guardian-update-review/new-version'
OUT=B.parent/'guardian-release-archives/3.55.0'
TAG='game-files-3.55.0-snapshot'
LIMIT=250*1024*1024
def read(p):return json.loads(p.read_text(encoding='utf8'))
def digest_file(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for chunk in iter(lambda:f.read(4*1024*1024),b''):h.update(chunk)
 return h.hexdigest()
def main():
 OUT.mkdir(parents=True,exist_ok=True)
 inventory=read(RUN/'new-inventory.json')
 changes={r['path']:r for r in map(json.loads,(RUN/'changes.jsonl').read_text(encoding='utf8').splitlines())}
 allowed={'AssetBundles','Assets','events','GameScript','media','minimap','static_data','Tilemaps','Title'}
 manifests={'files/.index-firstpass','files/Android.checksum','files/Android.index','files/Android.index.etag','files/assetbundle-version','files/assetbundle-version.etag','files/patch-index','files/patch-index.etag'}
 caches={'battleactions-bin','heroes-bin','monsters-bin','npc-bin','strings-bin-enUS'}
 sources=[];excluded=[];gaps=[];originals=0;captured=[];original_paths=set();decoded_count=collections.Counter()
 # Private values are read locally for comparison only and never saved in release metadata.
 needles=[s.encode().lower() for s in Path.home().name.split('.') if len(s)>3]
 organization=Path(os.environ.get('OneDriveCommercial','')).name.removeprefix('OneDrive - ').strip()
 if len(organization)>3:needles.append(organization.encode().lower())
 decoder=B.parent/'guardian-analysis/decode_scripts.py'
 if decoder.exists():
  tree=ast.parse(decoder.read_text(encoding='utf8'))
  for n in ast.walk(tree):
   if isinstance(n,ast.Call) and isinstance(n.func,ast.Attribute) and n.func.attr=='AES' and n.args and isinstance(n.args[0],ast.Constant) and isinstance(n.args[0].value,bytes):needles.append(n.args[0].value.lower())
 for r in inventory:
  if not r['path'].startswith('install/'):continue
  rel=r['path'][8:];parts=rel.split('/')
  include=rel in manifests or (parts[0]=='files' and len(parts)>2 and parts[1] in allowed) or (parts[0]=='cache' and len(parts)==2 and parts[1] in caches)
  if not include:excluded.append(rel);continue
  p=SNAP/r['source']
  if not p.exists():
   payload=changes.get(r['path'],{}).get('payload')
   if payload:p=RUN/payload;captured.append(rel)
  if not p.is_file():raise RuntimeError('Missing captured source: '+rel)
  originals+=1;original_paths.add(rel)
  encrypted=(parts[0]=='files' and len(parts)>1 and parts[1] in {'GameScript','Tilemaps'}) or r.get('decoder')=='static-aes-deflate' or rel in manifests and not rel.endswith('.etag') and 'assetbundle-version' not in rel
  section='encrypted' if encrypted else 'unencrypted'
  bucket='manifests' if rel in manifests else parts[1] if parts[0]=='files' else 'cache'
  sources.append((section,bucket,rel,p,r['sha256'],'Original game content'))
  # Only decoded game scripts/tables/maps/events/cache; never decoder diagnostics, keys or native binaries.
  d=r.get('decoder','');folder=None
  if parts[0]=='cache':folder='decoded'
  elif parts[1]=='GameScript':folder='decoded-scripts'
  elif parts[1]=='static_data':folder='decoded-static'
  elif parts[1]=='Tilemaps':folder='decoded-maps'
  elif parts[1]=='events':folder='decoded-events'
  if folder:
   if r.get('status')=='decoded' and r.get('decoded'):
    dp=RUN/r['decoded'];tail='/'.join(parts[2:]) if parts[0]=='files' else parts[-1];tail=str(Path(tail).with_suffix('.'+r.get('format','bin'))).replace('\\','/')
    path=folder+'/'+tail
    sources.append(('decrypted',folder,path,dp,r['content_sha256'],'Decoded game content'));decoded_count[folder]+=1
   else:gaps.append(dict(path=rel,status=r['status'],note='Original included; no decoded output available.'))
 seen=set()
 for section,bucket,rel,p,sha,kind in sources:
  if (section,rel) in seen:raise RuntimeError('Duplicate archive entry: '+rel)
  seen.add((section,rel))
 # Compare actual installation paths with the recorded inventory before claiming capture coverage.
 roots={str(SNAP/r['source'].split('/files/')[0]) for r in inventory if r['path'].startswith('install/files/') and '/files/' in r['source']}
 if len(roots)!=1:raise RuntimeError('Ambiguous installation root')
 actual_root=Path(next(iter(roots)))
 expected={r['path'][8:] for r in inventory if r['path'].startswith('install/')}
 actual={p.relative_to(actual_root).as_posix() for p in actual_root.rglob('*') if p.is_file()}
 extras=sorted(actual-expected);missing=sorted(expected-actual)
 if extras:raise RuntimeError('Installation changed after comparison: '+str(len(extras))+' unexpected files')
 if any(p in original_paths and p not in captured for p in missing):raise RuntimeError('Included original source missing')
 groups=collections.defaultdict(list)
 for row in sources:groups[(row[0],row[1])].append(row)
 entries=[];archives=[]
 print('Coverage:',originals,'originals,',sum(decoded_count.values()),'decoded;',len(excluded),'excluded;',len(gaps),'decode gaps',flush=True)
 for (section,bucket),rows in sorted(groups.items()):
  chunks=[];chunk=[];size=0
  for row in sorted(rows,key=lambda r:r[2]):
   length=row[3].stat().st_size
   if chunk and size+length>LIMIT:chunks.append(chunk);chunk=[];size=0
   chunk.append(row);size+=length
  if chunk:chunks.append(chunk)
  for i,chunk in enumerate(chunks,1):
   name=f'{section}-{bucket}-{i:02d}.zip';target=OUT/name;temp=OUT/(name+'.pending');pending=[]
   with zipfile.ZipFile(temp,'w',compression=zipfile.ZIP_STORED,allowZip64=True) as z:
    for _,_,rel,p,expected_hash,kind in chunk:
     member=section+'/'+rel
     assert not member.startswith('/') and '..' not in Path(member).parts
     h=hashlib.sha256();last=b'';length=0
     with p.open('rb') as src,z.open(member,'w') as dest:
      for data in iter(lambda:src.read(4*1024*1024),b''):
       probe=(last+data).lower()
       if any(n in probe for n in needles):raise RuntimeError('Private content detected in '+rel)
       last=data[-256:];h.update(data);dest.write(data);length+=len(data)
     if h.hexdigest()!=expected_hash:raise RuntimeError('Snapshot hash mismatch: '+rel)
     info=z.getinfo(member)
     pending.append(dict(section=section,path=rel,bytes=length,kind=kind,archive=name,member=member,sha256=expected_hash,headerOffset=info.header_offset,version='3.55.0'))
   with temp.open('rb') as f:
    for r in pending:
     f.seek(r.pop('headerOffset'));header=f.read(30);assert header[:4]==b'PK\x03\x04'
     n,e=struct.unpack_from('<HH',header,26);r['offset']=f.tell()+n+e
   with zipfile.ZipFile(temp) as z:
    if z.testzip() is not None:raise RuntimeError('ZIP CRC failure')
   temp.replace(target)
   archives.append(dict(name=name,section=section,folder=bucket,bytes=target.stat().st_size,files=len(pending),sha256=digest_file(target)))
   entries+=pending;print('Verified',name,len(pending),'files',flush=True)
 current=read(B/'dist/data/file-catalog.json')
 exports=[r for r in current['files'] if r['section']=='exports']
 candidate=dict(version=1,currentVersion='3.55.0',releasePublished=False,releaseTag=TAG,releaseURL='https://github.com/Jikolr/guardian-atlas/releases/tag/'+TAG,releaseBase='https://github.com/Jikolr/guardian-atlas/releases/download/'+TAG+'/',archives=archives,files=entries+exports,notes='Captured game content 3.55.0. Private state, executable binaries and decryption tools are excluded. See coverage for undecoded originals. Prepared release: not yet published.')
 (OUT/'file-catalog.pending.json').write_text(json.dumps(candidate,separators=(',',':')),encoding='utf8')
 coverage=dict(snapshot='3.55.0',originalFiles=originals,decodedFiles=sum(decoded_count.values()),decodedCategories=dict(decoded_count),excluded=excluded,decodeGaps=gaps,capturedPayloadFallbacks=captured,unexpectedFiles=extras,missingCapturedFiles=missing,archives=len(archives),totalArchiveBytes=sum(a['bytes'] for a in archives),scope='Complete allowlisted game content from the reviewed export, not the entire app or a guarantee of all server-delivered content. APK, native/runtime files, shader cache, account state, notifications, analytics and extraction tools excluded.',validation='Every archived source SHA-256 matched the captured inventory; every ZIP passed CRC verification; known personal strings and Lua AES key scanned without matches.')
 (OUT/'coverage.json').write_text(json.dumps(coverage,indent=2),encoding='utf8')
 (OUT/'release-manifest.json').write_text(json.dumps({k:v for k,v in candidate.items() if k!='files'},indent=2),encoding='utf8')
 (OUT/'SHA256SUMS.txt').write_text('\n'.join(a['sha256']+'  '+a['name'] for a in archives)+'\n',encoding='utf8')
 (OUT/'RELEASE.md').write_text('# Guardian Tales game files — 3.55.0\n\n'+str(originals)+' original files and '+str(sum(decoded_count.values()))+' decoded outputs in '+str(len(archives))+' archives.\n\n'+coverage['scope']+'\n\n'+coverage['validation']+'\n\nThis is a separate snapshot; do not merge it with 3.54.0 folders. Extract all ZIP parts for a category into the same empty folder. ZIPs use separate volumes, not split-ZIP compression. See coverage.json for exclusions and undecoded files, and SHA256SUMS.txt for archive checksums.\n\nThe archive manifests contain relative game paths only. No extraction keys or private account configuration are shipped.\n',encoding='utf8')
 print('READY',json.dumps({k:coverage[k] for k in ['originalFiles','decodedFiles','archives','totalArchiveBytes']}),flush=True)
if __name__=='__main__':main()

