from pathlib import Path
import json,shutil,gzip
B=Path(__file__).resolve().parent;S=B.parent/'guardian-analysis';D=B/'dist';O=D/'data/research/evidence';O.mkdir(parents=True,exist_ok=True);entries=[]
def add(src,category,title=None,note='Recovered evidence; interpretation may be incomplete.'):
 name=src.name;dest=O/(category+'-'+name);shutil.copyfile(src,dest);entries.append(dict(path=dest.name,name=title or name,category=category,url='data/research/evidence/'+dest.name,bytes=dest.stat().st_size,note=note))
add(S/'audit/damage-formula.md','Reports','Damage calculation explained','Analyzed built-in client path; runtime patches and mode-specific behavior remain unverified.')
for p in [S/'RAPPORT-HORS-LIGNE.md',S/'README.md']:add(p,'Reports')
for p in sorted((S/'audit/disassembly').glob('*.asm')):add(p,'Assembly','Native evidence · '+p.stem,'Recovered ARM64 instructions; not original C# source. Some files cover several methods.')
for p in sorted((S/'audit').glob('*.asm')):add(p,'Assembly')
for p in sorted(S.glob('*.py')):
 if p.name not in {'decode_scripts.py','decode_static.py','decode_maps.py'}:add(p,'Extraction tools',note='Offline extraction/research tool source, displayed as text only.')
for name in ['catalog-summary.json','metadata-summary.json','static-decode-summary.json','script-decode-summary.json','dev-comment-candidates.json']:
 add(S/'audit'/name,'Audit summaries')
for p in sorted((D/'downloads').glob('*')):
 if p.suffix in ['.gz','.csv','.md','.asm'] and not any(e['name']==p.name or e['name']=='Native evidence · '+p.stem for e in entries):entries.append(dict(path=p.name,name=p.name,category='Download inventories',url='downloads/'+p.name,bytes=p.stat().st_size,note='Inventory or existing research export. Large inventories are download-only.'))
(D/'data/research/evidence.json').write_text(json.dumps(entries,separators=(',',':')),encoding='utf8');print(len(entries),'evidence files')

# Reversibly compress existing code-index JSON exports to keep the hosted site small.
code_root=(D/'data/research/code').resolve()
for original in code_root.glob('*.json'):
 assert original.resolve().parent==code_root
 packed=original.with_suffix('.json.gz');packed.write_bytes(gzip.compress(original.read_bytes(),mtime=0))
 assert gzip.decompress(packed.read_bytes())==original.read_bytes()
 original.unlink()

# Make newly published evidence and native chunks discoverable in the file browser.
catalog_path=D/'data/file-catalog.json'
if catalog_path.exists():
 catalog=json.loads(catalog_path.read_text(encoding='utf8'));by_path={r['path']:r for r in catalog['files'] if r['section']=='exports'}
 for rel in list(by_path):
  if rel.startswith('data/research/code/') and rel.endswith('.json') and (D/(rel+'.gz')).exists():
   r=by_path.pop(rel);r.update(path=rel+'.gz',url=rel+'.gz',bytes=(D/(rel+'.gz')).stat().st_size,kind='Compressed website code index');by_path[rel+'.gz']=r
 additions=list(O.glob('*'))+list((D/'data/research/native').glob('*'))+[D/'data/research/evidence.json']
 for p in additions:
  if p.is_file():
   rel=p.relative_to(D).as_posix();by_path[rel]=dict(section='exports',path=rel,bytes=p.stat().st_size,url=rel,kind='Website code / evidence export')
 catalog['files']=[r for r in catalog['files'] if r['section']!='exports']+list(by_path.values());catalog_path.write_text(json.dumps(catalog,separators=(',',':')),encoding='utf8')

from sanitize_public_exports import sanitize
sanitize()
