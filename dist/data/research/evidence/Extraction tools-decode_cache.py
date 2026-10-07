"""Decode observed k1ng v1 cache containers; does not decrypt GameScript files."""
from pathlib import Path
import struct, json, hashlib

ROOT=Path(r'com.kakaogames.gdtskr')
OUT=Path(__file__).parent/'decoded'
OUT.mkdir(exist_ok=True)

def lz4(block, history=b''):
    pos=0; out=bytearray(history[-65536:]); start=len(out)
    def byte():
        nonlocal pos
        if pos>=len(block): raise ValueError(f'Truncated LZ4 block, output length {len(out)-start}, tail {bytes(out[-100:])!r}')
        v=block[pos]; pos+=1; return v
    def length(v):
        if v==15:
            while True:
                x=byte(); v+=x
                if x!=255: break
        return v
    while pos<len(block):
        token=byte(); n=length(token>>4)
        if pos+n>len(block): raise ValueError('Truncated literals')
        out.extend(block[pos:pos+n]); pos+=n
        if len(out)>4*1024*1024: raise ValueError('Block too large')
        if pos==len(block): break
        offset=byte() | byte()<<8
        if not 0<offset<=len(out): raise ValueError(f'Invalid offset {offset}, input pos {pos}, output {len(out)}, head {block[:16].hex()}')
        n=length(token&15)+4
        if len(out)+n>4*1024*1024: raise ValueError('Block too large')
        for _ in range(n): out.append(out[-offset])
    return bytes(out[start:])

summaries=[]
for p in sorted((ROOT/'cache').glob('*-bin*'),key=lambda p: (p.name!='heroes-bin',p.name)):
    b=p.read_bytes()
    if b[:4]!=b'k1ng': continue
    version,n,k=struct.unpack_from('<III',b,4)
    assert version==1 and 16+n*16+k*2<=len(b)
    entries=[struct.unpack_from('<IQHH',b,16+i*16) for i in range(n)]
    offset=16+n*16
    sizes=struct.unpack_from('<'+'H'*k,b,offset); offset+=k*2
    aligned=(offset+3)&~3
    assert not any(b[offset:aligned])
    offset=aligned
    print('Reading',p.name,'n',n,'k',k,'payload',offset,'first sizes',sizes[:5],flush=True)
    assert offset+sum(sizes)==len(b)
    chunks=[]
    for idx,size in enumerate(sizes):
        try:
            expected=struct.unpack_from('<I',b,offset+size-4)[0]
            chunk=lz4(b[offset:offset+size-4])
            assert len(chunk)==expected, (len(chunk),expected)
            chunks.append(chunk)
        except ValueError as e: raise ValueError(f'{p.name} chunk {idx}, offset {offset}, size {size}: {e}') from e
        offset+=size
    raw=b''.join(chunks)
    (OUT/(p.name+'.decompressed')).write_bytes(raw)
    print(p.name, 'records',n,'blocks',k,'decoded bytes',len(raw),'length fields',sum(e[3] for e in entries),'preview',repr(raw[:160]),flush=True)
    records=[]; cursor=0
    for ident,unknown,flags,length in entries:
        data=raw[cursor:cursor+length]; cursor+=length
        obj={'Id':ident,'Text':data.decode('utf-8')} if p.name.startswith('strings-bin') else json.loads(data)
        if isinstance(obj,dict) and 'Id' in obj: assert obj['Id']==ident, (ident,obj['Id'])
        records.append(obj)
    assert cursor==len(raw) and len(records)==n
    (OUT/(p.name+'.json')).write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
    (OUT/(p.name+'.index.json')).write_text(json.dumps([{'record_position':i,'record_id':e[0],'unknown_u64':str(e[1]),'block_or_flags':e[2],'byte_length':e[3]} for i,e in enumerate(entries)],indent=2),encoding='utf-8')
    summaries.append(dict(source=str(p),sha256=hashlib.sha256(b).hexdigest(),records=n,blocks=k,decoded_bytes=len(raw),block_output_sizes=[len(c) for c in chunks],record_flags=sorted(set(e[2] for e in entries)),example_keys=list(records[0]) if isinstance(records[0],dict) else [],status='All blocks and records consumed; block lengths verified; JSON parsed and Id fields matched where present; localization decoded as UTF-8'))
(OUT/'validation.json').write_text(json.dumps(summaries,indent=2),encoding='utf-8')
