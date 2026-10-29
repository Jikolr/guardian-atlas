"""Resolve stored map characters to original artwork without executing game code.

Preparation reads the native CharacterPlaceholder payloads omitted from the small
website maps, resolves exact table names and writes sprite-render jobs. Finish
joins those jobs to export_map_sprite_frames.py outputs. Source bundles stay local.

Pipeline: prepare -> export_map_sprite_frames.py -> render_map_sprite_frames.cjs
-> export_map_collectibles.py -> render_map_collectibles.cjs -> finish ->
validate_map_entities.py. Sprite jobs and parser caches are kept in the supplied
snapshot's map-graphics directory. Only final original artwork and placement
references are required by the browser; game code is never executed.
"""
from __future__ import annotations
import argparse, collections, gzip, hashlib, json, re, shutil, struct
from pathlib import Path
from snapshot_formats import parse_map

BASE = Path(__file__).resolve().parent
DATA = BASE / 'dist/data'
OUT = DATA / 'visual/map-entities'
BUILD = BASE / '.build-cache/map-entities'

def cache_path(name):
    """Read older public build intermediates once, then keep them outside dist."""
    path = (BUILD / name).resolve()
    if not path.is_relative_to(BUILD.resolve()):
        raise ValueError('Build cache path escapes its directory')
    legacy = OUT / name
    if not path.exists() and legacy.is_file():
        path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(legacy, path)
    return path

def read(path):
    path=Path(path); b=path.read_bytes()
    return json.loads(gzip.decompress(b) if path.suffix=='.gz' else b)

def write(path, value):
    path=Path(path);path.parent.mkdir(parents=True,exist_ok=True)
    raw=json.dumps(value,ensure_ascii=False,separators=(',',':')).encode()
    if path.suffix=='.gz':raw=gzip.compress(raw,mtime=0)
    if not path.exists() or path.read_bytes()!=raw:path.write_bytes(raw)

class Reader:
    def __init__(self,b):self.b=b;self.p=0
    def take(self,n):
        if self.p+n>len(self.b):raise ValueError('truncated component')
        v=self.b[self.p:self.p+n];self.p+=n;return v
    def u8(self):return self.take(1)[0]
    def boolean(self):
        v=self.u8()
        if v not in [0,1]:raise ValueError('invalid boolean')
        return bool(v)
    def i32(self):return struct.unpack('<i',self.take(4))[0]
    def f32(self):return struct.unpack('<f',self.take(4))[0]
    def string(self):
        n=0
        for shift in range(0,35,7):
            v=self.u8();n|=(v&127)<<shift
            if v<128:return self.take(n).decode('utf8')
        raise ValueError('invalid string length')
    def count(self):
        n=self.i32()
        if not 0<=n<=100000:raise ValueError('invalid count')
        return n

def parse_character(raw):
    """CharacterPlaceholder.Deserialize schema, versions 1..11.

    Evidence: captured Scripts.dll method 11180 @ 0x7c7d704, plus exact end-of-
    component validation for every decoded payload. Enum constants also checked
    against the 3.57 metadata defaults: NPC1, Convertible2, Monster3, Event4;
    Up1, Right2, Down4, Left8. Old native addresses are provenance, not execution.
    """
    r=Reader(raw);v=r.i32()
    if not 1<=v<=11:raise ValueError('unsupported CharacterPlaceholder version')
    d={'version':v,'config':r.string(),'type':r.u8(),'level':r.i32(),'dropItems':r.string()}
    if d['type'] not in range(5):raise ValueError('invalid character type')
    if v>=8:d['collectibleItem']=r.i32()
    if v>=9:d['specialCollectibleItem']=r.i32()
    if v>=6:d['spriteOverrides']=[{'condition':r.u8(),'name':r.string()} for _ in range(r.count())]
    d['direction']=r.i32()
    d['deactivateOnStart']=r.boolean() if v>=4 else False
    npc=d['type'] in [1,2]
    if npc:
        d['equipment']=[r.string() for _ in range(3)]
        d['animation']=r.string();d['emotion']=r.string();d['loop']=r.boolean();d['lockDirection']=r.boolean()
        if v>=4:
            d['questId']=r.i32();d['hideWhenCleared']=r.boolean();d['lastUsedQuestProgress']=r.i32();d['onlySpine']=r.boolean()
            if v>=5:
                c=r.i32();d['activateCondition']=c
                if c==1:d['activateConditionIntParam']=r.i32()
                if c in [1,2]:d['activateConditionStrParam']=r.string()
            if v>=7 and r.boolean():d['addColor']={'name':r.string(),'rgba':list(r.take(4)),'magnitude':r.f32()}
    if (not npc and v==2) or d['type']!=1:
        d['eventGroup']=r.string();d['noticeLink']=r.string()
    if d['type']!=1:
        d['wave']=r.i32()
        if v>=10:d['waveDelayTime']=r.f32()
        d['monsterType']=r.u8()
        if v>=11:d['noAssassination']=r.boolean()
        d['eliteOptions']=[{'id':r.i32(),'level':r.i32(),'index':r.i32(),'value':r.f32()} for _ in range(r.count())]
    d['componentSpec']=r.string()
    if r.p!=len(raw):raise ValueError(f'unconsumed bytes {len(raw)-r.p}')
    return d

def map_components(snapshot, cache):
    cp=cache/'marker-components.json.gz'
    if cp.exists():return read(cp)
    maps=[]
    for m in read(DATA/'visual/maps.json'):
        if m['status']!='ready':continue
        p=snapshot/'phone/decoded/files/Tilemaps'/(m['name']+'.bytes')
        if not p.exists():p=snapshot/'apk/decoded/com.kakaogames.gdtskr/assets/Tilemaps'/(m['name']+'.bytes')
        if not p.exists():raise FileNotFoundError(m['name'])
        d=parse_map(p)
        maps.append({'name':d['name'],'sha256':d['sha256'],'layers':[{'index':i,'name':l['name'],'events':l['events'],'properties':l.get('properties',[])} for i,l in enumerate(d['layers']) if l['events']]})
    write(cp,maps);return maps

def prepare(snapshot, cache):
    tables={name:{r['fields'].get('Name'):r for r in read(DATA/(name+'.json'))} for name in ['npcs','monsters','heroes']}
    # Placeholder type controls behavior. NPCs can use a monster or hero's
    # CharacterSpec (civilian_male and princess, for example). Names are unique
    # across the three exported CharacterSpec tables; never use fuzzy matches.
    records=collections.defaultdict(list)
    for table,rows in tables.items():
        for name,row in rows.items():records[name].append((table,row))
    jobs={};mapped=[];failures=collections.Counter();examples={};types=collections.Counter();dir_counts=collections.Counter()
    for m in map_components(snapshot,cache):
        placements=[];unresolved=[];nonvisual=0
        for l in m['layers']:
            props=collections.defaultdict(list)
            for p in l['properties']:props[p['index']].append(p)
            for ei,event in enumerate(l['events']):
                mid=f'm:{l["index"]}:{ei}'
                char=[p for p in props[ei] if p['component'].startswith('Tilemaps.CharacterPlaceholder')]
                if not char:
                    if l['name'] in ['npcs','monsters']:
                        unresolved.append({'id':mid,'reason':'Unsupported legacy character component'})
                    else:nonvisual+=1
                    continue
                if len(char)!=1:
                    unresolved.append({'id':mid,'reason':'Multiple character components'});continue
                prop=char[0]
                try:d=parse_character(bytes.fromhex(prop['hex']))
                except Exception as e:
                    key=str(e);failures[key]+=1;examples.setdefault(key,{'map':m['name'],'id':mid,'property':prop});unresolved.append({'id':mid,'reason':'Character component could not be fully decoded'});continue
                types[d['type']]+=1;dir_counts[d['direction']]+=1
                matches=records.get(d['config'],[])
                if len(matches)!=1:
                    unresolved.append({'id':mid,'reason':('No exact character record for ' if not matches else 'Ambiguous character record for ')+d['config']});continue
                table,row=matches[0]
                f=row['fields'];ref=f.get('SpineAssetName');ref=ref.get('default',ref.get('Default')) if isinstance(ref,dict) else ref
                if not isinstance(ref,str) or not ref:
                    unresolved.append({'id':mid,'reason':'Record has no resolved Spine asset reference','record':{'table':table,'id':row['id'],'name':d['config']}});continue
                bundle,sep,skin=ref.partition('#');skin=skin or 'default'
                bundle,_,prefab=bundle.partition(':')
                if not bundle.startswith('/'):bundle='characters/'+bundle
                else:bundle=bundle.lstrip('/')
                direction={1:'back',2:'side',4:'front',8:'side'}.get(d['direction'],'front')
                # The known directional enum is bitwise. Multi-axis/none values
                # retain their source value and use a labeled front preview.
                animation=d.get('animation') or 'idle'
                key=hashlib.sha256((ref+'|'+direction+'|'+animation).encode()).hexdigest()[:20]
                record={'table':table,'id':row['id'],'name':d['config']}
                jobs.setdefault(key,{'id':key,'bundle':bundle,'prefab':prefab or None,'skin':skin,'direction':direction,'animation':animation,'record':record,'assetRef':ref,'count':0})['count']+=1
                source={'component':prop['component'],'version':d['version'],'config':d['config'],'direction':d['direction'],'animation':animation}
                entry={'id':mid,'graphic':key,'category':'npcs' if d['type'] in [1,2] else 'monsters','record':record,'source':source,'flipX':d['direction']==8}
                notes=[]
                if d['direction'] not in [1,2,4,8]:notes.append('Front preview; stored direction is not a single facing')
                if d.get('deactivateOnStart'):entry['inactive']=True;notes.append('Deactivated on stage start')
                if d.get('spriteOverrides'):notes.append('Conditional sprite variants are not applied')
                if d.get('addColor'):notes.append('Conditional color override is not applied')
                if any(d.get('equipment',[])) or any(f.get(k) for k in ['DefaultWeapon1','DefaultWeapon2','DefaultAccessory1']):notes.append('Separately attached equipment is not reconstructed')
                if notes:entry['notes']=notes
                placements.append(entry)
        mapped.append({'name':m['name'],'sourceMapSha256':m['sha256'],'placements':placements,'unresolved':unresolved,'nonvisual':nonvisual})
    jobs=sorted(jobs.values(),key=lambda j:(not j['record']['name'].startswith('shortstory_invader2'),-j['count'],j['id']))
    write(cache/'sprite-jobs.json',jobs);write(cache/'resolved-placements.json.gz',mapped)
    write(cache/'resolution-diagnostics.json',{'failures':dict(failures),'examples':examples,'types':dict(types),'directions':dict(dir_counts),'jobs':len(jobs)})
    print(json.dumps({'maps':len(mapped),'placements':sum(len(m['placements']) for m in mapped),'jobs':len(jobs),'failures':dict(failures),'directions':dict(dir_counts)}),flush=True)

def finish(cache):
    frames=read(cache_path('sprite-frames.json'));graphics=frames.get('graphics',frames)
    errors={e['id']:(e.get('error') or 'Unknown extraction failure').splitlines()[0].removeprefix('page.evaluate: Error: ') for e in frames.get('errors',[])}
    collectible_path=cache_path('collectible-placements.json.gz')
    collectibles=read(collectible_path) if collectible_path.exists() else {}
    collectible_frames=cache_path('collectible-frames.json')
    if collectible_frames.exists():graphics.update(read(collectible_frames)['graphics'])
    mapped=read(cache/'resolved-placements.json.gz');index={};totals=collections.Counter();used=set()
    for m in mapped:
        extra=collectibles.get(m['name'],{})
        placements=[];unresolved=list(m['unresolved'])+extra.get('unresolved',[])
        for p in m['placements']+extra.get('placements',[]):
            if p['graphic'] in graphics:
                g=graphics[p['graphic']]
                if 'record' in p:
                    native_flip=(g.get('transformScale') or [1,1])[0]<0
                    p={**p,'flipX':bool(p.get('flipX') and g.get('direction')=='side')!=native_flip}
                if g.get('poseNote'):p={**p,'notes':p.get('notes',[])+[g['poseNote']]}
                if g.get('animation')=='setup pose':p={**p,'notes':p.get('notes',[])+['Requested animation is absent from this rig; native setup pose shown']}
                placements.append(p);used.add(p['graphic'])
            else:
                error=errors.get(p['graphic'],'')
                if re.search(r'[A-Za-z]:[/\\]|file:|https?://',error):error=''
                unresolved.append({k:p[k] for k in ['id','record','source'] if k in p}|{'reason':'Original sprite frame unavailable'+(': '+error[:180] if error else '')})
        summary={'rendered':len(placements),'unresolved':len(unresolved),'nonvisual':m['nonvisual'],'inactive':sum(p.get('inactive',False) for p in placements)}
        payload={**m,'placements':placements,'unresolved':unresolved,'summary':summary};payload.pop('nonvisual',None)
        rel='maps/'+m['name']+'.json.gz';write(OUT/rel,payload);index[m['name']]={'path':rel,**summary}
        totals.update(summary)
    export={'version':1,'snapshotVersion':'3.57.0','graphics':{k:graphics[k] for k in sorted(used)},'maps':index,'summary':dict(totals),'limitations':['Static original-asset frames at stored placements; scripts, movement, combat and visibility conditions are not simulated.','Nonvisual camera, region and script-target markers have no character artwork.','Separately attached equipment and unresolved legacy components are reported, not guessed.']}
    write(BUILD/'index.json',export);write(OUT/'index.json.gz',export);print(json.dumps({'graphics':len(used),'maps':len(index),**totals}),flush=True)

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--snapshot',type=Path,required=True);ap.add_argument('--phase',choices=['prepare','finish'],default='prepare');args=ap.parse_args()
    cache=args.snapshot/'map-graphics';cache.mkdir(exist_ok=True)
    prepare(args.snapshot,cache) if args.phase=='prepare' else finish(cache)
