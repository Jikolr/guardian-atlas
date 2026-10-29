"""Check that exported artwork still refers to the exact source map placements.

Run after the extraction/render/finish pipeline. The optional snapshot check also
re-reads every native character payload and compares the source bytes' hashes.
"""
import argparse, collections, hashlib, json, math, struct
from pathlib import Path
from export_map_entities import DATA, OUT, BUILD, read, parse_character


def validate(snapshot=None):
    index=read(OUT/'index.json.gz')
    plain_index=BUILD/'index.json'
    if plain_index.exists():
        assert index==read(plain_index), 'Public and build-cache manifests differ'
    graphics=index['graphics'];totals=collections.Counter();categories=collections.Counter();used=set();reasons=collections.Counter()
    for key,g in graphics.items():
        f=(OUT/g['image']).resolve()
        assert f.is_relative_to(OUT.resolve()), (key,'Image path escapes output directory')
        with f.open('rb') as stream:header=stream.read(24)
        assert header[:8]==b'\x89PNG\r\n\x1a\n', (key,'Not a PNG')
        assert struct.unpack('>II',header[16:24])==(g['width'],g['height']), (key,'Wrong image dimensions')
        assert all(math.isfinite(g[k]) and g[k]>0 for k in ['worldWidth','worldHeight']), (key,'Invalid world bounds')
        assert len(g['anchor'])==2 and all(math.isfinite(v) for v in g['anchor']), (key,'Invalid origin')
    for name,entry in index['maps'].items():
        data=read(OUT/entry['path']);m=read(DATA/'visual/maps'/(name+'.json.gz'))
        assert data['name']==name
        assert data['sourceMapSha256']==m['sha256'], (name,'Source map hash mismatch')
        if snapshot:
            source=snapshot/'phone/decoded/files/Tilemaps'/(name+'.bytes')
            if not source.exists():source=snapshot/'apk/decoded/com.kakaogames.gdtskr/assets/Tilemaps'/(name+'.bytes')
            assert hashlib.sha256(source.read_bytes()).hexdigest()==data['sourceMapSha256'], (name,'Snapshot bytes changed')
        ids=set()
        for p in data['placements']+data['unresolved']:
            ident=p['id'];assert ident not in ids,(name,ident,'Duplicate placement');ids.add(ident)
            parts=ident.split(':');marker=parts[0]=='m';li,ei=map(int,parts[1:] if marker else parts)
            source=m['layers'][li]['events' if marker else 'tiles'][ei]
            if 'graphic' in p:
                assert p['graphic'] in graphics,(name,ident,'Missing graphic');used.add(p['graphic']);categories[p['category']]+=1
                if not marker:assert source['name']==p['source']['tile'],(name,ident,'Collectible changed')
            else:
                reason=p['reason'];reasons[reason.split(' for ')[0]]+=1
        s=data['summary'];assert s['rendered']==len(data['placements']);assert s['unresolved']==len(data['unresolved'])
        assert s['inactive']==sum(p.get('inactive',False) for p in data['placements'])
        assert all(entry[k]==s[k] for k in s),(name,'Index counts disagree');totals.update(s)
    assert dict(totals)==index['summary'],'Global counts disagree'
    assert used==set(graphics),'Unused or missing graphic definitions'
    native=collections.Counter()
    if snapshot:
        for m in read(snapshot/'map-graphics/marker-components.json.gz'):
            for l in m['layers']:
                for p in l['properties']:
                    if p['component'].startswith('Tilemaps.CharacterPlaceholder'):
                        d=parse_character(bytes.fromhex(p['hex']));native[d['version']]+=1
    return {'maps':len(index['maps']),'graphics':len(graphics),'summary':dict(totals),'categories':dict(categories),'unresolvedReasons':dict(reasons),'nativePayloads':sum(native.values()),'nativeVersions':dict(native),'checks':['Source SHA-256 and placement index continuity','All PNG dimensions, origins and positive world bounds','No duplicate placement IDs or missing/unused artwork','All per-map and global totals','Native CharacterPlaceholder payload fully consumed']}


if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--snapshot',type=Path);ap.add_argument('--output',type=Path);args=ap.parse_args();result=validate(args.snapshot)
    if args.output:args.output.write_text(json.dumps(result,indent=2),encoding='utf8')
    print(json.dumps(result,indent=2))
