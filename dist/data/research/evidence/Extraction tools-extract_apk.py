from pathlib import Path
import zipfile,io,json
OUT=Path(__file__).parent/'apk'
OUT.mkdir(exist_ok=True)
z=zipfile.ZipFile(r'Guardian+Tales_3.54.0_APKPure.xapk')
manifest=json.loads(z.read('manifest.json'))
(OUT/'xapk-manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
inventory=[]
for name in z.namelist():
    if not name.endswith('.apk'): continue
    inner=zipfile.ZipFile(io.BytesIO(z.read(name)))
    for info in inner.infolist():
        path=info.filename
        inventory.append(dict(apk=name,path=path,size=info.file_size))
        select=(path.startswith('assets/GameScript/') or 'metadata' in path.lower() or path.endswith(('libil2cpp.so','libxlua.so','liblz4.so')))
        if select and not info.is_dir():
            target=OUT/name.removesuffix('.apk')/path
            assert target.resolve().is_relative_to(OUT.resolve())
            target.parent.mkdir(parents=True,exist_ok=True)
            target.write_bytes(inner.read(info))
    print(name,'files',len(inner.infolist()),flush=True)
(OUT/'file-list.json').write_text(json.dumps(inventory,indent=2),encoding='utf-8')
for p in OUT.rglob('*.lua'):
    print(str(p.relative_to(OUT)),repr(p.read_bytes()[:100]))
print('metadata candidates', [x for x in inventory if 'metadata' in x['path'].lower()])
