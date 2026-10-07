"""Read-only inventory of every supplied game file and APK entry."""
from pathlib import Path
from collections import Counter
import csv,hashlib,json,zipfile,io,struct
ROOT=Path(r'com.kakaogames.gdtskr')
OUT=Path(__file__).parent/'audit'
OUT.mkdir(exist_ok=True)
def classify(b,name):
    for sig,kind in [(b'UnityFS\0','UnityFS bundle'),(b'\x7fELF','ELF executable'),(b'dex\n','Android DEX'),(b'\xaf\x1b\xb1\xfa','IL2CPP metadata'),(b'k1ng','k1ng cache'),(b'\x89PNG','PNG'),(b'\xff\xd8\xff','JPEG'),(b'\x1f\x8b','gzip'),(b'PK\x03\x04','ZIP'),(b'\x1bLua','Lua bytecode'),(b'\x1bLJ','LuaJIT bytecode')]:
        if b.startswith(sig): return kind
    if b[4:8]==b'ftyp': return 'MP4 media'
    if name.endswith('.encrypted'): return 'Encrypted script (extension)'
    if name.endswith('.etag'): return 'ETag'
    if name.endswith('.json') and b.lstrip().startswith((b'{',b'[')):return 'JSON'
    if name.endswith('.lua'): return 'Lua source candidate'
    return 'Other / binary'

def scan_downloads():
    paths=sorted(p for p in ROOT.rglob('*') if p.is_file())
    types=Counter();total=0;errors=[]
    with (OUT/'all-files.csv').open('w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=['path','bytes','type','sha256','header_hex']);w.writeheader()
        for i,p in enumerate(paths):
            name=p.relative_to(ROOT).as_posix()
            try:
                h=hashlib.sha256()
                with p.open('rb') as inp:
                    head=inp.read(256);h.update(head)
                    while chunk:=inp.read(2**20):h.update(chunk)
                size=p.stat().st_size;kind=classify(head,name);types[kind]+=1;total+=size
                w.writerow(dict(path=name,bytes=size,type=kind,sha256=h.hexdigest(),header_hex=head[:32].hex()))
            except Exception as e:errors.append(dict(path=name,error=str(e)))
            if (i+1)%500==0:print('Data files scanned',i+1,'/',len(paths),flush=True)
    result=dict(files=len(paths),bytes=total,types=dict(types),errors=errors)
    (OUT/'download-summary.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result),flush=True)

def scan_apk():
    z=zipfile.ZipFile(r'Guardian+Tales_3.54.0_APKPure.xapk')
    rows=[];hits=[]
    for name in z.namelist():
        if not name.endswith('.apk'):continue
        a=zipfile.ZipFile(io.BytesIO(z.read(name)))
        for item in a.infolist():
            if item.is_dir():continue
            b=a.read(item)
            kind=classify(b[:256],item.filename)
            row=dict(apk=name,path=item.filename,bytes=len(b),type=kind,sha256=hashlib.sha256(b).hexdigest(),header_hex=b[:32].hex())
            rows.append(row)
            pos=b.find(b'\xaf\x1b\xb1\xfa')
            if pos>=0:
                version=struct.unpack_from('<I',b,pos+4)[0] if pos+8<=len(b) else None
                hits.append(dict(path=item.filename,offset=pos,version=version))
            if item.filename.startswith('assets/bin/Data/') and ('Resources/' in item.filename or item.filename.endswith(('globalgamemanagers','boot.config'))):
                target=OUT/'apk-extra'/item.filename
                target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(b)
        print('APK scanned',name,len(a.infolist()),flush=True)
    (OUT/'apk-inventory.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
    (OUT/'metadata-signatures.json').write_text(json.dumps(hits,indent=2),encoding='utf-8')
    print('Metadata signatures:',json.dumps(hits),flush=True)

if __name__=='__main__':
    import sys
    scan_apk() if '--apk' in sys.argv else scan_downloads()
