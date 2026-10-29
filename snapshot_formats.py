"""Public-format parsers and render helpers, reused from the existing research exports.

The map and mesh readers preserve the documented legacy interpretation. They do
not decrypt files, execute game code or reconstruct runtime animations.
"""
from pathlib import Path
import struct,json,hashlib,gzip,re,collections,gc

def write_json(path,value):
    from import_snapshot import write
    write(path,value)

def strip_trailing_commas(text):
    """Remove only JSON commas outside string literals before a closing bracket."""
    out=[];inside=False;escaped=False
    for i,char in enumerate(text):
        if inside:
            out.append(char)
            if escaped:escaped=False
            elif char=='\\':escaped=True
            elif char=='"':inside=False
        elif char=='"':inside=True;out.append(char)
        elif char==',':
            j=i+1
            while j<len(text) and text[j].isspace():j+=1
            if j>=len(text) or text[j] not in '}]':out.append(char)
        else:out.append(char)
    return ''.join(out)

def refresh_tilesets(data,source,comparison,version):
    from PIL import Image,ImageDraw
    visual=data/'visual'
    read=lambda p:json.loads(gzip.decompress(p.read_bytes()) if p.suffix=='.gz' else p.read_bytes())
    maps=read(visual/'maps.json');catalog=read(visual/'tilesets.json')
    needed=collections.defaultdict(set)
    for row in maps:
        if row['status']!='ready':continue
        obj=read(visual/'maps'/(row['name']+'.json.gz'))
        for layer in obj['layers']:
            for tile in layer['tiles']:
                if tile['tileset']!='Built-in':needed[tile['tileset']].add(tile['name'])
    bundles=read(data/'research/bundles.json')
    changed={r['path'] for r in comparison['files'] if r['change']!='unchanged'}
    refreshed=[]
    for name,names in sorted(needed.items()):
        candidates=[b['path'] for b in bundles if (':' in name and b['path']=='files/AssetBundles/Android/'+name.split(':')[0]) or b['path'].endswith('/tilesets/'+name) or b['path'].endswith('/'+name+'/tilesets')]
        # Prefer downloaded bundles when the same tileset exists in the APK.
        phone_candidates=[p for p in candidates if not p.startswith('apk/')]
        if phone_candidates:candidates=phone_candidates
        key=hashlib.sha256(name.encode()).hexdigest()[:16];out=visual/'tilesets'/key
        existing=read(out/'scene.json.gz') if (out/'scene.json.gz').exists() else None
        if len(candidates)!=1:
            catalog.setdefault(name,{'error':'Tileset bundle not uniquely resolved'})
            continue
        path=candidates[0]
        if existing and (path not in changed or catalog.get(name,{}).get('snapshotVersion')==version) and names<=existing['meshes'].keys():continue
        try:
            actual=source/path
            if path.startswith('apk/'):
                actual=Path(comparison['apkRoot'])/path.removeprefix('apk/')
            export(actual,names,out)
            scene=read(out/'scene.json.gz')
            # Avoid leaking the local source folder into a hosted mesh document.
            scene['source']=path
            (out/'scene.json.gz').write_bytes(gzip.compress(json.dumps(scene,separators=(',',':')).encode(),mtime=0))
            catalog[name]=dict(path='tilesets/'+key+'/scene.json.gz',matched=len(scene['meshes']),requested=len(names),skipped=len(scene['skipped']),snapshotVersion=version)
            refreshed.append(name)
        except Exception as error:
            if existing:catalog[name]['refreshError']=str(error)
            else:catalog[name]={'error':str(error)}
        if len(refreshed)%10==0:print('Tilesets refreshed',len(refreshed),flush=True);gc.collect()
    write_json(visual/'tilesets.json',catalog)
    meshes={name:{k for k,v in read(visual/row['path'])['meshes'].items() if v} for name,row in catalog.items() if row.get('path')}
    (visual/'map-thumbnails').mkdir(exist_ok=True)
    for row in maps:
        if row['status']!='ready':continue
        obj=read(visual/'maps'/(row['name']+'.json.gz'));tiles=[t for layer in obj['layers'] for t in layer['tiles']]
        row['artworkTiles']=sum(t['name'] in meshes.get(t['tileset'],set()) for t in tiles)
        if row.get('image') and (visual/row['image']).exists() and row.get('snapshotVersion')!=version:continue
        focus=[t for layer in obj['layers'] if layer['name']=='floor' for t in layer['tiles']] or tiles
        image=Image.new('RGB',(320,200),'#101e2c');draw=ImageDraw.Draw(image)
        if focus:
            xs=[t['position'][0] for t in focus];zs=[t['position'][2] for t in focus]
            lo,hi=min(xs),max(xs);bottom,top=min(zs),max(zs);scale=min(290/max(hi-lo+3,1),170/max(top-bottom+3,1));radius=max(.65,scale*.45)
            for layer in reversed(obj['layers']):
                color='#426e86' if 'floor' in layer['name'] else '#a695cf' if 'wall' in layer['name'] else '#e5ba63'
                for tile in layer['tiles']:
                    x=160+(tile['position'][0]-(lo+hi)/2)*scale;y=100-(tile['position'][2]-(bottom+top)/2)*scale
                    draw.rectangle((x-radius,y-radius,x+radius,y+radius),fill=color)
        row['image']='map-thumbnails/'+row['name']+'.webp';image.save(visual/row['image'],'WEBP',quality=75)
    write_json(visual/'maps.json',maps)
    print('Tilesets',len(catalog),'refreshed',len(refreshed),'maps with artwork',sum(r.get('artworkTiles',0)>0 for r in maps),flush=True)

def parse_map(SOURCE):
    b = SOURCE.read_bytes()
    p = 0
    def read(fmt):
        nonlocal p
        fmt = '<' + fmt
        size = struct.calcsize(fmt)
        assert p + size <= len(b), (p, size)
        v = struct.unpack_from(fmt, b, p); p += size
        return v[0] if len(v) == 1 else list(v)
    def count():
        v = read('i'); assert 0 <= v <= 100000, (p, v)
        return v
    def string():
        nonlocal p
        n = 0
        for shift in range(0, 35, 7):
            v = read('B'); n |= (v & 127) << shift
            if v < 128: break
        else: raise ValueError('Invalid string length')
        assert p+n <= len(b)
        s = b[p:p+n].decode('utf-8'); p += n
        return s
    def props():
        nonlocal p
        result = []
        for _ in range(count()):
            idx, name, size = read('h'), string(), count()
            assert p+size <= len(b)
            raw = b[p:p+size]; p += size
            result.append(dict(index=idx, component=name, bytes=size, hex=raw.hex()))
        return result
    
    assert b[:4] == b'KONG'; p = 4
    version, partition = read('i'), read('i')
    assert 11 <= version <= 16, f'Unsupported legacy map format {version}'
    unit = read('fff')
    tilesets = [dict(name=string(), tiles=[string() for _ in range(count())]) for _ in range(count())]
    difficulty = bool(read('B')) if version>=12 else False
    water = bool(read('B')) if version>=15 else False
    addons = string() if version>=16 else ''
    handles = []
    for _ in range(count()):
        kind = read('B'); handles.append(dict(kind=kind, names=[string() for _ in range(count())]))
    layers = []
    for _ in range(count()):
        layer = dict(name=string(), type=read('i'), options=read('i'), tiles=[], events=[], partitions=[])
        n = count()
        if layer['type']:
            layer['events'] = [dict(name=string(), position=read('fff')) for _ in range(n)]
            layer['properties'] = props()
        else:
            for _ in range(n):
                px, pz = read('hh'); records = []
                for _ in range(count()):
                    offset = p
                    ts, ti, x, y, z, rot = read('hhBbBB')
                    assert ts == 0 or ti < 0 or (0 < ts <= len(tilesets) and 0 <= ti < len(tilesets[ts-1]['tiles'])), (offset,ts,ti)
                    name = tilesets[ts-1]['tiles'][ti] if ts>0 and ti>=0 else f'Built-in tile {ti}'
                    tile = dict(name=name, tileset=tilesets[ts-1]['name'] if ts>0 and ti>=0 else 'Built-in',
                        position=[round(px*partition+x*unit[0],4), round(y*unit[1],4),round(pz*partition+z*unit[2],4)],
                        rotation=rot, raw=[ts,ti,x,y,z,rot], offset=offset, partition=[px,pz])
                    records.append(tile); layer['tiles'].append(tile)
                layer['partitions'].append(dict(position=[px,pz], tileCount=len(records), properties=props()))
        layers.append(layer)
    # Explicit-layout physics structs: x/z overlap xz, and y/types/dir overlap value.
    physics = {}
    formats=[('floors','hhHBB')]
    if version>=13:formats.append(('upperFloors','hhHBB'))
    formats += [('walls','hhHBBhh'),('nonUnitWalls','ffHBBff')]
    if version>=14:formats += [('upperWalls','hhHBBhh'),('nonUnitUpperWalls','ffHBBff')]
    for key, fmt in formats:
        n = count(); physics[key] = [read(fmt) for _ in range(n)]
    assert p == len(b), (p, len(b), 'Unconsumed map bytes')
    result = dict(name=SOURCE.stem, source=SOURCE.name, version=version, bytes=len(b),
        sha256=hashlib.sha256(b).hexdigest(), parsedBytes=p, partitionSize=partition, unitSize=unit,
        hasDifficultyLevels=difficulty, tilesets=tilesets, handles=handles, layers=layers, physics=physics,
        evidence={'reader':'Tilemaps.TilemapBinary.ReadFromStream @ 0x7c8a530',
        'placement':'<CreateTileLayer>d__57.MoveNext @ 0x7d50800',
        'coordinates':'x = signed low16(partition) * partitionSize + tile.x * unitSize.x; z = signed high16(partition) * partitionSize + tile.z * unitSize.z; y = signed tile.y * unitSize.y',
        'limitations':'Structural top-down preview; marker symbols are schematic. Artwork, prefab dimensions and live scripted changes are not reconstructed.'})
    return result

def export(src,names,OUT):
    import numpy as np
    import UnityPy
    from UnityPy.helpers.MeshHelper import MeshHandler
    OUT.mkdir(parents=True,exist_ok=True)
    env=UnityPy.load(str(src)); objects={o.path_id:o for o in env.objects}
    trees={o.path_id:o.read_typetree() for o in env.objects if o.type.name in ['GameObject','Transform','MeshFilter','MeshRenderer','Material']}
    def deref(p):
        assert p['m_FileID']==0,p
        return trees[p['m_PathID']]
    def xyz(v):return [v[k] for k in 'xyz']
    def matrix(t,root=False):
        x,y,z,w=[t['m_LocalRotation'][k] for k in 'xyzw']
        r=np.array([[1-2*y*y-2*z*z,2*x*y-2*z*w,2*x*z+2*y*w],[2*x*y+2*z*w,1-2*x*x-2*z*z,2*y*z-2*x*w],[2*x*z-2*y*w,2*y*z+2*x*w,1-2*x*x-2*y*y]])
        m=np.eye(4);m[:3,:3]=(np.eye(3) if root else r)@np.diag(xyz(t['m_LocalScale']))
        if not root:m[:3,3]=xyz(t['m_LocalPosition'])
        return m
    materials={};meshes={};textures={};skipped=[]
    def material(pid):
        if str(pid) in materials:return str(pid)
        t=trees[pid];props=t['m_SavedProperties'];tex=dict(props['m_TexEnvs']).get('_MainTex');col=dict(props['m_Colors']).get('_Color',dict(r=1,g=1,b=1,a=1))
        if not tex or not tex['m_Texture']['m_PathID']:raise ValueError(('No main texture',t['m_Name']))
        ptr=tex['m_Texture']
        if ptr['m_FileID']:
            skipped.append(dict(material=t['m_Name'],reason='External texture',reference=ptr));return None
        tid=ptr['m_PathID'];o=objects[tid].read()
        if str(tid) not in textures:
            filename=f'{o.m_Name}.png';o.image.save(OUT/filename);textures[str(tid)]=filename
        materials[str(pid)]=dict(name=t['m_Name'],texture=textures[str(tid)],color=[col[k] for k in 'rgba'],scale=list(tex['m_Scale'].values()),offset=list(tex['m_Offset'].values()))
        return str(pid)
    def parts(go,mat,root=False):
        comps={objects[c['component']['m_PathID']].type.name: c['component']['m_PathID'] for c in go['m_Component']}
        t=trees[comps['Transform']];mat=mat@matrix(t,root);result=[]
        if 'MeshFilter' in comps and 'MeshRenderer' in comps:
            renderer=trees[comps['MeshRenderer']]
            if renderer['m_Enabled']:
                ptr=trees[comps['MeshFilter']]['m_Mesh']
                if ptr['m_FileID'] or not ptr['m_PathID']:
                    skipped.append(dict(object=go['m_Name'],reason='External or runtime-generated mesh',reference=ptr));return result
                mesh=objects[ptr['m_PathID']].read();h=MeshHandler(mesh);h.process()
                vs=(mat@np.column_stack([np.array(h.m_Vertices),np.ones(len(h.m_Vertices))]).T).T[:,:3]
                for i,triangles in enumerate(h.get_triangles()):
                    if not triangles:continue
                    mp=renderer['m_Materials'][min(i,len(renderer['m_Materials'])-1)];assert mp['m_FileID']==0
                    mid=material(mp['m_PathID'])
                    if mid:result.append(dict(vertices=np.round(vs,6).tolist(),uv=h.m_UV0,triangles=triangles,material=mid))
        for child in t['m_Children']:
            tr=deref(child);childgo=deref(tr['m_GameObject'])
            if childgo['m_IsActive']:result+=parts(childgo,mat)
        return result
    gos={}
    for pid,t in trees.items():
        if objects[pid].type.name=='GameObject':gos.setdefault(t['m_Name'],[]).append(t)
    for name in names:
        candidates=gos.get(name,[])
        if len(candidates)>1:candidates=[g for g in gos.get(name,[]) if any(objects[c['component']['m_PathID']].type.name=='MonoBehaviour' and objects[c['component']['m_PathID']].read_typetree().get('tilesetId') for c in g['m_Component'])]
        try:
            assert len(candidates)==1,(name,len(candidates))
            meshes[name]=parts(candidates[0],np.eye(4),True)
        except Exception as ex:skipped.append(dict(tile=name,reason=str(ex)))
    result=dict(meshes=meshes,materials=materials,skipped=skipped,source=str(src).replace(chr(92),"/").split("/com.kakaogames.gdtskr/")[-1],rotationDegreesPerCode=90,
        limitations='Static MeshRenderer geometry and main textures. Unlit materials; particles, animations and runtime script changes are omitted. Camera is an approximation.')
    (OUT/'scene.json.gz').write_bytes(gzip.compress(json.dumps(result,separators=(',',':')).encode(),mtime=0))

def link_visual_records(DATA):
    OUT=DATA/'visual'
    def read(p):return json.loads(p.read_text(encoding='utf8'))
    def write(p,v):write_json(p,v)
    assets=list({a['id']:a for a in read(OUT/'assets.json')+read(OUT/'icons.json')}.values())
    for a in assets:a.pop('records',None)
    def norm(s):return re.sub(r'\.(rgba4444|png|tga|tif|psd|jpg|webp)$','',str(s).lower())
    lookup=collections.defaultdict(list)
    for a in assets:
        a['aliases']=['Andras'] if re.search(r'(^|[/_])demon_slayer($|[/_.])',a['name']+' '+a['bundle']) else []
        path=a['bundle'].lower();name=a['name'].lower()
        a['category']='Items' if '/spritesheets/items' in path else 'Bosses' if 'boss' in path or name.startswith('boss_') else 'Heroes & characters' if '/illusts/' in path or '/characters/' in path or '/spritesheets/heroes' in path else 'Tilesets' if 'tileset' in path else 'Other graphics'
        a['presentation']='Icon / sprite' if a['type']!='Texture2D' else 'Texture / atlas'
        if a['status']=='ready':
            for key in {norm(a['name']),norm(Path(a['bundle']).name),norm(a['name']).removeprefix('illust_')}:lookup[key].append(a)
    def values(x):
        if isinstance(x,str):return [x]
        if isinstance(x,dict):return [v for z in x.values() for v in values(z)]
        return []
    links={};records=[]
    for table in ['heroes','monsters','npcs','static-items','static-heroes','static-heroes2','static-monsters','static-npc']:
        p=DATA/(table+'.json')
        if not p.exists():continue
        for row in read(p):
            f=row['fields'];candidates={}
            for field,base in [('PortraitAssetName',120),('IllustAssetName',120),('SpriteName',110),('Name',90),('Class',80),('AssetName',80),('SpineAssetName',60)]:
                for value in values(f.get(field)):
                    for key in [norm(value)]+[norm(t) for t in value.split('#')]:
                        for a in lookup.get(key,[]):
                            # Background textures are not a character portrait.
                            if a['name'].startswith('bg_'):continue
                            score=base+(100 if a['presentation']=='Icon / sprite' else 0)
                            if table=='static-items' and a['category']=='Items':score+=50
                            if norm(a['name'])==key:score+=10
                            if score>candidates.get(a['id'],(-1,None,None))[0]:candidates[a['id']]=(score,a,field+' = '+value)
            ranked=sorted(candidates.values(),key=lambda x:-x[0]);alias='Andras' if f.get('Class')=='demon_slayer' or f.get('PortraitAssetName')=='demon_slayer' else ''
            if not ranked and not alias:continue
            chosen=ranked[:12];primary=chosen[0][1] if chosen else None
            icons=[a for _,a,_ in ranked if a['presentation']=='Icon / sprite'];thumb=icons[0] if icons else primary
            info=dict(name=alias,aliasSource='User-confirmed identity' if alias else '',image=primary['image'] if primary else None,thumbnail=thumb['image'] if thumb else None,assetIds=[a['id'] for _,a,_ in chosen],match=chosen[0][2] if chosen else '',presentation=primary['presentation'] if primary else '')
            links[table+':'+str(row['id'])]=info
            if table in ['heroes','monsters','npcs','static-items']:
                records.append(dict(table=table,id=row['id'],name=f.get('Name',str(row['id'])),displayName=alias,**{k:info[k] for k in ['image','thumbnail','assetIds','presentation']}))
                for _,a,_ in chosen:
                    a.setdefault('records',[])
                    if len(a['records'])<30:a['records'].append(dict(table=table,id=row['id'],name=f.get('Name',''),displayName=alias))
    write(OUT/'assets.json',assets);write(OUT/'record-media.json',links);write(OUT/'records.json',records)
    print('Assets',len(assets),'linked records',len(links),'hero links',sum(k.startswith('heroes:') for k in links))
