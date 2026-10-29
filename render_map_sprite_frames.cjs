/* Render extracted original Spine poses to RGBA PNGs and world-sized anchors. */
const fs=require('fs'),path=require('path');
const options={};for(let i=2;i<process.argv.length;i+=2)options[process.argv[i].replace(/^--/,'')]=process.argv[i+1];
const {chromium}=require(options.playwright||process.env.PLAYWRIGHT_MODULE||'playwright');
async function main(){
 const input=JSON.parse(fs.readFileSync(options.jobs,'utf8')),out=path.resolve(options.out);
 fs.mkdirSync(path.join(out,'images'),{recursive:true});
 const cache=require('./map_build_cache.cjs')(out,options.cache);
 const manifestFile=cache.readPath('sprite-frames.json');
 const manifest=fs.existsSync(manifestFile)?JSON.parse(fs.readFileSync(manifestFile,'utf8')):{schemaVersion:1,graphics:{},errors:[]};
 const browser=await chromium.launch({headless:true,...(options.chrome?{executablePath:options.chrome}:{channel:'msedge'}),args:['--enable-unsafe-swiftshader','--use-angle=swiftshader']});
 try{
  const page=await browser.newPage();await page.goto('about:blank');await page.addScriptTag({path:path.resolve(options.runtime)});
  await page.evaluate(()=>{
   const canvas=document.createElement('canvas');document.body.append(canvas);
   const gl=canvas.getContext('webgl',{alpha:true,premultipliedAlpha:true,preserveDrawingBuffer:true,antialias:false});
   if(!gl)throw Error('WebGL unavailable');
   const renderer=new spine.webgl.SceneRenderer(canvas,gl);
   let currentPayload='',atlases={},textures=[];
   const decode=b64=>Uint8Array.from(atob(b64),c=>c.charCodeAt(0));
   window.exportPose=async function(payload,job){
    const contentHash=payload.contentSha256||payload.sourceSha256;
    if(currentPayload!==contentHash){
     for(const texture of textures)texture.dispose();textures=[];atlases={};
     for(const [key,value] of Object.entries(payload.atlases)){
      const pages={};
      for(const [name,b64] of Object.entries(value.pages)){
       const image=await new Promise((resolve,reject)=>{const im=new Image();im.onload=()=>resolve(im);im.onerror=reject;im.src='data:image/png;base64,'+b64;});
       pages[name]=new spine.webgl.GLTexture(gl,image);textures.push(pages[name]);
      }
      atlases[key]=new spine.TextureAtlas(value.text,name=>{if(!pages[name])throw Error('Missing atlas page '+name);return pages[name]});
     }
     currentPayload=contentHash;
    }
    const direction=job.direction||'front',prefab=job.prefab||job.bundle.split('/').pop();
    const candidates=payload.skeletons.filter(x=>x.prefab?.toLowerCase()===prefab.toLowerCase());
    if(!candidates.length)throw Error('Missing exact prefab '+prefab);
    const matches=candidates.filter(x=>x.direction===direction);
    const source=matches.length===1?matches[0]:!matches.length&&candidates.length===1?candidates[0]:null;
    if(!source)throw Error(matches.length?'Ambiguous '+direction+' skeleton':'Missing '+direction+' skeleton');
    const actualDirection=source.direction||'single';
    const poseNote=actualDirection!==direction?'Native single-view sprite; the stored facing has no separate artwork':null;
    const data=new spine.SkeletonBinary(new spine.AtlasAttachmentLoader(atlases[source.atlas])).readSkeletonData(decode(source.binary));
    if(!String(data.version).startsWith('3.8.'))throw Error('Unsupported Spine version '+data.version);
    const explicitSkin=job.skinSpecified??(job.assetRef?job.assetRef.includes('#'):Boolean(job.skin));
    const skeleton=new spine.Skeleton(data),skin=(explicitSkin?job.skin:source.defaultSkin)||'default';
    if(!data.findSkin(skin))throw Error('Missing skin '+skin);
    skeleton.setSkinByName(skin);skeleton.setToSetupPose();
    const requested=job.animation||'idle',names=[requested+'_'+actualDirection,requested];
    const animation=names.map(n=>data.animations.find(a=>a.name.toLowerCase()===n.toLowerCase())).find(Boolean);
    // A setup pose is explicit evidence, never a substituted animation.
    if(animation)animation.apply(skeleton,0,0,false,[],1,spine.MixBlend.setup,spine.MixDirection.mixIn);
    skeleton.updateWorldTransform();
    const offset=new spine.Vector2(),size=new spine.Vector2();skeleton.getBounds(offset,size,[]);
    if(!Number.isFinite(size.x+size.y)||size.x<=0||size.y<=0||Math.max(size.x,size.y)>8192)throw Error('Invalid or excessive rig bounds');
    const padding=2,x=Math.floor(offset.x)-padding,y=Math.floor(offset.y)-padding;
    const width=Math.ceil(offset.x+size.x)+padding-x,height=Math.ceil(offset.y+size.y)+padding-y;
    canvas.width=width;canvas.height=height;
    renderer.camera.position.set(x+width/2,y+height/2,0);renderer.camera.setViewport(width,height);
    gl.viewport(0,0,width,height);gl.clearColor(0,0,0,0);gl.clear(gl.COLOR_BUFFER_BIT);
    renderer.begin();renderer.drawSkeleton(skeleton,true);renderer.end();
    const unit=source.scale;
    if(!Number.isFinite(unit)||unit<=0)throw Error('Missing source unit scale');
    const ts=source.transformScale||[1,1];
    return {png:canvas.toDataURL('image/png'),exportVersion:2,width,height,worldWidth:width*unit*Math.abs(ts[0]),worldHeight:height*unit*Math.abs(ts[1]),anchor:[-x/width,(y+height)/height],sourceBundle:payload.sourceBundle,sourceSha256:payload.sourceSha256,contentSha256:contentHash,dependencySha256:payload.dependencySha256||{},prefab,skin,skinSource:explicitSkin?'asset reference':'prefab',animation:animation?animation.name:'setup pose',requestedAnimation:requested,requestedDirection:direction,direction:actualDirection,poseNote,skeleton:source.name,unitScale:unit,transformScale:ts};
   };
  });
  const payloads=new Map();let completed=0;
  const requestedIds=new Set([...input.jobs,...input.errors].map(j=>j.id));
  manifest.errors=(manifest.errors||[]).filter(e=>!requestedIds.has(e.id));
  manifest.errors.push(...input.errors);
  for(const error of input.errors)delete manifest.graphics[error.id];
  for(const job of input.jobs){
   if(!/^[a-zA-Z0-9_-]+$/.test(job.id))throw Error('Unsafe graphic ID');
   try{
    if(!payloads.has(job.payload))payloads.set(job.payload,JSON.parse(fs.readFileSync(job.payload,'utf8')));
    const payload=payloads.get(job.payload),prior=manifest.graphics[job.id];
    const explicitSkin=job.skinSpecified??(job.assetRef?job.assetRef.includes('#'):Boolean(job.skin));
    if(prior?.exportVersion===2&&(prior.contentSha256||prior.sourceSha256)===(payload.contentSha256||payload.sourceSha256)&&prior.prefab===(job.prefab||job.bundle.split('/').pop())&&(!explicitSkin||prior.skin===(job.skin||'default'))&&(prior.requestedDirection||prior.direction)===(job.direction||'front')&&fs.existsSync(path.join(out,prior.image))){completed++;continue;}
    const {png,...graphic}=await page.evaluate(({payload,job})=>exportPose(payload,job),{payload,job});
    graphic.image='images/'+job.id+'.png';
    fs.writeFileSync(path.join(out,graphic.image),Buffer.from(png.split(',')[1],'base64'));
    manifest.graphics[job.id]=graphic;completed++;
   }catch(e){delete manifest.graphics[job.id];manifest.errors.push({id:job.id,bundle:job.bundle,error:String(e.message).split('\n')[0].replace(/^page.evaluate: Error: /,'')});}
   if((completed+manifest.errors.length)%50===0){fs.writeFileSync(manifestFile,JSON.stringify(manifest));console.log('Rendered',completed,'frames; failures',manifest.errors.length);}
  }
  fs.writeFileSync(manifestFile,JSON.stringify(manifest));
  console.log(JSON.stringify({output:manifestFile,completed,graphics:Object.keys(manifest.graphics).length,errors:manifest.errors.length}));
 }finally{await browser.close();}
}
main().catch(e=>{console.error(e);process.exitCode=1});
