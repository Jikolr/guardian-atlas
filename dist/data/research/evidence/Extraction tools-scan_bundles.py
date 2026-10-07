from pathlib import Path
from collections import Counter
import sys,json,csv,hashlib,gc
sys.path.insert(0,str(Path(__file__).parent/'tool-libs'))
import UnityPy
BASE=Path(__file__).parent; OUT=BASE/'audit'; ROOT=Path(r'com.kakaogames.gdtskr')
rows=list(csv.DictReader((OUT/'all-files.csv').open(encoding='utf-8')))
bundles=[r for r in rows if r['type']=='UnityFS bundle']
types=Counter();errors=[];exports=[];mbkeys=Counter();versions=Counter()
assets=OUT/'bundle-text'; assets.mkdir(exist_ok=True)
with (OUT/'bundle-objects.csv').open('w',newline='',encoding='utf-8') as f:
    w=csv.writer(f);w.writerow(['bundle','path_id','type','name','bytes'])
    for i,row in enumerate(bundles):
        try:
            env=UnityPy.load(str(ROOT/row['path']))
            for obj in env.objects:
                typ=obj.type.name; types[typ]+=1;name=''
                if typ in ('TextAsset','MonoScript','MonoBehaviour'):
                    try:
                        tree=obj.read_typetree();name=tree.get('m_Name','')
                        if typ=='MonoBehaviour':
                            mbkeys.update(tree.keys())
                        if typ in ('TextAsset','MonoScript'):
                            key=hashlib.sha256((row['path']+str(obj.path_id)).encode()).hexdigest()[:16]
                            out=assets/(key+'.json');out.write_text(json.dumps(tree,ensure_ascii=True,indent=2,default=str),encoding='utf-8')
                            exports.append(dict(bundle=row['path'],path_id=obj.path_id,type=typ,name=name,output=str(out.relative_to(BASE))))
                    except Exception as e:errors.append(dict(bundle=row['path'],path_id=obj.path_id,type=typ,error=str(e)[:250]))
                w.writerow([row['path'],obj.path_id,typ,name,obj.byte_size])
            del env
        except Exception as e:errors.append(dict(bundle=row['path'],error=str(e)[:250]))
        if (i+1)%100==0:print('Bundles reviewed',i+1,'/',len(bundles),'text/script exports',len(exports),'errors',len(errors),flush=True);gc.collect()
(OUT/'bundle-summary.json').write_text(json.dumps(dict(bundles=len(bundles),types=dict(types),exports=exports,monobehaviour_keys=dict(mbkeys),errors=errors),indent=2),encoding='utf-8')
print('DONE',dict(types), 'exports',len(exports),'errors',len(errors),flush=True)
