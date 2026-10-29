/* On-demand artwork for placements whose original component data is resolved. */
'use strict';
window.loadMapEntities=async function({mapName,mapSha256,markers,objects=markers,onProgress=()=>{}}){
 const root='data/visual/map-entities/';
 async function json(path){
  const response=await fetch(root+path);
  if(!response.ok)throw Error('Placement artwork data is unavailable.');
  return path.endsWith('.gz')?new Response(response.body.pipeThrough(new DecompressionStream('gzip'))).json():response.json();
 }
 const index=await json('index.json.gz'),entry=index.maps?.[mapName];
 if(!entry?.path)return {entities:new Map(),unresolved:new Map(markers.map(m=>[m.id,'No supported artwork mapping for this map.'])),summary:{},source:null};
 const source=await json(entry.path),placements=new Map(objects.map(m=>[m.id,m]));
 if(mapSha256&&source.sourceMapSha256!==mapSha256)throw Error('Artwork data belongs to a different map revision.');
 const unresolved=new Map((source.unresolved||[]).map(x=>[x.id,x.reason||'No supported artwork mapping.']));
 const pending=[];
 for(const item of source.placements||[]){
  const marker=placements.get(item.id),graphic=index.graphics?.[item.graphic];
  if(!marker)continue;
  if(!graphic?.image){unresolved.set(item.id,'The matched asset has no exported image.');continue;}
  const scale=typeof item.scale==='number'?item.scale:1;
  if(!(graphic.worldWidth>0&&graphic.worldHeight>0&&scale>0)){
   unresolved.set(item.id,'Artwork scale could not be established.');continue;
  }
  pending.push({...item,marker,graphicData:graphic,imageURL:root+graphic.image,position:marker.position,layer:marker.layer,
   worldWidth:graphic.worldWidth*scale,worldHeight:graphic.worldHeight*scale,anchor:graphic.anchor||[.5,1]});
 }
 const images=new Map(),urls=[...new Set(pending.map(x=>x.imageURL))];let loaded=0;
 // Bounded parallel loads keep large maps responsive and avoid hundreds of
 // simultaneous image requests. None of these files load in markers-only mode.
 let cursor=0;
 await Promise.all(Array.from({length:Math.min(8,urls.length)},async()=>{
  while(cursor<urls.length){const url=urls[cursor++];try{const image=new Image();image.src=url;await image.decode();images.set(url,image);}catch{/* Keep its placement as an inspectable marker. */}
   loaded++;onProgress(loaded,urls.length);
  }
 }));
 const entities=new Map();
 for(const item of pending){
  const image=images.get(item.imageURL);
  if(image){entities.set(item.id,{...item,image});unresolved.delete(item.id);}
  else unresolved.set(item.id,'The artwork image could not be loaded.');
 }
 // Markers without a visual component (camera, region, script target, etc.)
 // are deliberately absent from the fallback set. They are not missing art.
 const nonvisual=new Set(markers.filter(marker=>!entities.has(marker.id)&&!unresolved.has(marker.id)).map(marker=>marker.id));
 const summary={...(source.summary||entry.summary||{})};
 summary.unresolved=(summary.unresolved||0)+(source.placements||[]).length-entities.size;
 summary.rendered=entities.size;
 return {entities,unresolved,nonvisual,summary,source};
};
