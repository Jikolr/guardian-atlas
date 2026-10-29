"""Export native map collectible artwork and exact tile-to-sprite references."""
import argparse, collections, json, sys
from pathlib import Path
from export_map_entities import read, write, DATA, OUT, BUILD, cache_path

def export(snapshot, library):
    sys.path.insert(0,str(library));import UnityPy
    import numpy as np
    from UnityPy.helpers.MeshHelper import MeshHandler
    phone=snapshot/'phone/decoded/files/AssetBundles/Android'
    apk=snapshot/'apk/decoded/com.kakaogames.gdtskr/assets/AssetBundles/Android'
    def path(name):return phone/name if (phone/name).exists() else apk/name
    # Crop the actual runtime item atlas, not website previews or entire sheets.
    src=path('spritesheets/items');env=UnityPy.load(str(src));objs={o.path_id:o for o in env.objects};graphics={}
    for obj in env.objects:
        if obj.type.name!='MonoBehaviour':continue
        t=obj.read_typetree()
        sprites=t.get('mSprites',[])
        if not any(s['name'].startswith('purple_coin_') for s in sprites) or not t.get('material',{}).get('m_PathID'):continue
        mat=objs[t['material']['m_PathID']].read_typetree();ptr=dict(mat['m_SavedProperties']['m_TexEnvs'])['_MainTex']['m_Texture'];assert ptr['m_FileID']==0
        texture=objs[ptr['m_PathID']].read().image
        for sprite in sprites:
            name=sprite['name']
            if not name.startswith('purple_coin_'):continue
            x,y,w,h=[sprite[k] for k in ['x','y','width','height']]
            f=OUT/'images'/(name+'.png');f.parent.mkdir(exist_ok=True,parents=True);texture.crop((x,y,x+w,y+h)).save(f)
            graphics[name]={'image':'images/'+f.name,'width':w,'height':h,'worldWidth':round(w*.03,5),'worldHeight':round(h*.03,5),'anchor':[.5,.5],'sourceBundle':'spritesheets/items','sprite':name,'renderKind':'native atlas sprite','pixelToWorld':.03}

    # Star piece is a runtime mesh prefab, unlike the inventory star_piece icon.
    env=UnityPy.Environment()
    for n in ['effects/commons','effects/stage/base']:env.load_file(str(apk/n))
    objs={(o.assets_file.name,o.path_id):o for o in env.objects}
    def objref(p,owner):
        file=owner.assets_file
        name=file.name if p['m_FileID']==0 else file.externals[p['m_FileID']-1].path.rsplit('/',1)[-1]
        return objs[(name,p['m_PathID'])]
    def ref(p,owner):return objref(p,owner).read_typetree()
    def matrix(t):
        x,y,z,w=[t['m_LocalRotation'][k] for k in 'xyzw']
        r=np.array([[1-2*y*y-2*z*z,2*x*y-2*z*w,2*x*z+2*y*w],[2*x*y+2*z*w,1-2*x*x-2*z*z,2*y*z-2*x*w],[2*x*z-2*y*w,2*y*z+2*x*w,1-2*x*x-2*y*y]])
        m=np.eye(4);m[:3,:3]=r@np.diag([t['m_LocalScale'][k] for k in 'xyz']);m[:3,3]=[t['m_LocalPosition'][k] for k in 'xyz'];return m
    parts=[];materials={}
    def material(p,owner):
        ob=objref(p,owner);key=str(ob.path_id)
        if key in materials:return key
        mt=ob.read_typetree();pr=mt['m_SavedProperties'];te=dict(pr['m_TexEnvs']).get('_MainTex');color=dict(pr['m_Colors']).get('_Color',dict(r=1,g=1,b=1,a=1))
        if not te or not te['m_Texture']['m_PathID']:raise ValueError('Star mesh material lacks original texture')
        texture=objref(te['m_Texture'],ob).read();fn='star-'+str(te['m_Texture']['m_PathID'])+'.png';dest=BUILD/'props'/fn;dest.parent.mkdir(exist_ok=True,parents=True);texture.image.save(dest)
        cap=dict(pr['m_TexEnvs']).get('_MatCap');assert cap and cap['m_Texture']['m_PathID']
        capfn='star-matcap-'+str(cap['m_Texture']['m_PathID'])+'.png';objref(cap['m_Texture'],ob).read().image.save(BUILD/'props'/capfn)
        materials[key]={'texture':'props/'+fn,'matcap':'props/'+capfn,'color':[color[k] for k in 'rgba'],'scale':list(te['m_Scale'].values()),'offset':list(te['m_Offset'].values()),'shader':'MatCap/Detail'};return key
    def walk(go,mat):
        tree=go.read_typetree();components={}
        for c in tree['m_Component']:
            ob=objref(c['component'],go);components[ob.type.name]=ob
        tr=components['Transform'];t=tr.read_typetree();mat=mat@matrix(t)
        if tree['m_Name'] in ['inner','outer']:
            mf=components['MeshFilter'];mr=components['MeshRenderer'];rend=mr.read_typetree();mesh=objref(mf.read_typetree()['m_Mesh'],mf).read();h=MeshHandler(mesh);h.process()
            vs=(mat@np.column_stack([np.array(h.m_Vertices),np.ones(len(h.m_Vertices))]).T).T[:,:3]
            for i,tri in enumerate(h.get_triangles()):
                # Native MatCap/Detail transforms normals with objectToWorld,
                # then normalizes in view space; preserve that exact behavior.
                if tri:parts.append({'vertices':np.round(vs,6).tolist(),'normals':np.round((mat[:3,:3]@np.array(h.m_Normals).T).T,6).tolist(),'uv':h.m_UV0,'triangles':tri,'material':material(rend['m_Materials'][min(i,len(rend['m_Materials'])-1)],mr)})
        for child in t['m_Children']:
            ob=objref(child,tr);walk(objref(ob.read_typetree()['m_GameObject'],ob),mat)
    candidates=[o for o in env.objects if o.type.name=='GameObject' and o.read_typetree()['m_Name']=='star_piece'];assert len(candidates)==1
    walk(candidates[0],np.eye(4));assert parts
    write(BUILD/'props/star-piece-scene.json',{'parts':parts,'materials':materials,'source':'effects/stage/base:star_piece','limitations':'Static native inner/outer mesh prefab pose; rotating animation and particle sparkle omitted.'})
    write(BUILD/'collectible-frames.json',{'graphics':graphics})
    print('Exported',len(graphics),'coin sprites and',len(parts),'native star-piece mesh parts')

def resolve():
    map_stages=collections.defaultdict(list)
    for r in read(DATA/'static-stages.json'):
        f=r['fields'];tilemap=f.get('Tilemap');vals=tilemap.values() if isinstance(tilemap,dict) else [tilemap]
        for m in vals:
            if isinstance(m,str):map_stages[m].append(f)
    # Native PurpleCoinSprites.GetSpriteName: world-specific on story stages;
    # the shared event sprite for event, short-story and memorial chapter types.
    def coin_name(f):
        code=int(f['Id'])//10000;kind=code//1000
        if kind==10:return 'purple_coin_'+str(code%100)
        if kind in [60,61,70,71,72]:return 'purple_coin_event'
        return None
    frames=read(cache_path('collectible-frames.json'))['graphics'];result={};counts=collections.Counter()
    for m in read(DATA/'visual/maps.json'):
        if m['status']!='ready':continue
        data=read(DATA/'visual/maps'/(m['name']+'.json.gz'));placements=[];unresolved=[]
        variants={coin_name(s) for s in map_stages[m['name']]};variants.discard(None)
        coin=next(iter(variants)) if len(variants)==1 else None
        for li,layer in enumerate(data['layers']):
            for ti,tile in enumerate(layer['tiles']):
                if tile['tileset']!='gimmick':continue
                if tile['name']=='[GIMMICK]purple_coin':
                    name=coin
                    if not name or name not in frames:
                        unresolved.append({'id':f'{li}:{ti}','reason':'Coin appearance needs an unambiguous stage/chapter mapping'});continue
                elif tile['name']=='[GIMMICK]star_piece':name='star_piece_field'
                else:continue
                placements.append({'id':f'{li}:{ti}','graphic':name,'category':'collectibles','source':{'component':'Oak.PurpleCoinBehaviour' if name.startswith('purple_coin') else 'Oak.StarPieceBehaviour','tile':tile['name'],'stageIds':sorted({s['Id'] for s in map_stages[m['name']]})},'notes':['Stored collectible placement; acquired/hidden state and floating animation are not simulated.']})
        result[m['name']]={'placements':placements,'unresolved':unresolved};counts.update(rendered=len(placements),unresolved=len(unresolved))
    write(BUILD/'collectible-placements.json.gz',result);print(json.dumps(counts))

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--snapshot',type=Path,required=True);ap.add_argument('--library',type=Path,required=True);args=ap.parse_args();export(args.snapshot,args.library);resolve()
