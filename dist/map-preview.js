'use strict';
(async()=>{
 const $=s=>document.querySelector(s), canvas=$('#map'),ctx=canvas.getContext('2d');
 const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 try{
 const initial=new URLSearchParams(location.search);const mapName=initial.get('map')||'ancientdungeon_red_1_1';
 const response=await fetch('data/visual/maps/'+encodeURIComponent(mapName)+'.json.gz');if(!response.ok)throw Error('Map data could not be loaded.');const data=await new Response(response.body.pipeThrough(new DecompressionStream('gzip'))).json();$('h1').textContent=data.name;document.title=data.name+' · Map viewer';$('.intro').textContent='Explore stored tile positions, original static artwork and map layers. Unresolved meshes remain available in structural mode.';
 const colors={gimmick:'#efc665',breakale:'#f29978',obj_wall:'#a998d9',wall2:'#9b8fd2',wall:'#718bad',obj1:'#79c6b6',floor2:'#466a80',floor:'#345570'};
 const tiles=data.layers.flatMap((l,layer)=>l.tiles.map((t,i)=>({...t,layer,index:i,id:`${layer}:${i}`})));
 const markers=data.layers.flatMap((l,layer)=>(l.events||[]).map((t,i)=>({...t,layer,index:i,id:`m:${layer}:${i}`,marker:true})));const objects=[...tiles,...markers],objectsById=new Map(objects.map(t=>[t.id,t]));
 $('.intro').textContent='Explore the original map artwork. Enable Game graphics to reveal supported characters, collectibles and objects at their stored positions.';
 let graphics=null,graphicsLoading=false,graphicsError='',graphicsPromise=null;
 const graphicLabels={npcs:'Characters / NPCs',monsters:'Enemies',collectibles:'Coins / collectibles',objects:'Objects'};
 const graphicTypes=new Set(initial.has('graphicTypes')?initial.get('graphicTypes').split(',').filter(k=>k in graphicLabels):Object.keys(graphicLabels));
 $('#show-graphics').checked=initial.get('graphics')==='1';$('#fallback-markers').checked=initial.get('fallback')!=='0';$('#show-inactive').checked=initial.get('inactive')==='1';
 $('#graphics-types').innerHTML=Object.entries(graphicLabels).map(([key,label])=>`<label><input type="checkbox" data-graphic-type="${key}" ${graphicTypes.has(key)?'checked':''}> ${label}<small data-graphic-count="${key}"></small></label>`).join('');
 const markerType=t=>{const n=data.layers[t.layer].name;return n==='npcs'?'npcs':n==='monsters'?'monsters':n==='events'?'events':n.includes('camera')?'camera':'other'};
 const typeLabels={npcs:'NPCs',monsters:'Enemies',events:'Events',camera:'Camera markers',other:'Other markers'};
 const markerTypes=new Set(initial.has('types')?initial.get('types').split(',').filter(k=>k in typeLabels):Object.keys(typeLabels));let markerLimit=40;
 $('#marker-search').value=initial.get('mq')||'';
 $('#marker-types').innerHTML=Object.entries(typeLabels).map(([key,label])=>`<label><input type="checkbox" data-marker-type="${key}" ${markerTypes.has(key)?'checked':''}> ${label} <small>(${markers.filter(t=>markerType(t)===key).length})</small></label>`).join('');
 const markerVisible=t=>visible.has(t.layer)&&markerTypes.has(markerType(t));
 const graphicCategory=t=>t.category in graphicLabels?t.category:'objects';
 const activeEntities=()=>$('#show-graphics').checked&&graphics?[...graphics.entities.values()].filter(t=>visible.has(t.layer)&&(!t.marker.marker||markerVisible(t.marker))&&graphicTypes.has(graphicCategory(t))&&(!t.inactive||$('#show-inactive').checked)):[];
 const markerObjects=()=>[...markers,...(graphics?[...graphics.unresolved.keys()].filter(id=>!id.startsWith('m:')).map(id=>objectsById.get(id)).filter(Boolean):[])];
 const drawMarker=t=>markerVisible(t)&&($('#show-markers').checked||($('#show-graphics').checked&&$('#fallback-markers').checked&&graphics?.unresolved.has(t.id)));
 function graphicsStatus(){
  $('#graphics-options').hidden=!$('#show-graphics').checked;$('#graphics-status').dataset.state=graphicsLoading?'loading':graphicsError?'error':graphics?'ready':'idle';
  if(graphicsLoading)return;
  if(graphicsError){$('#graphics-status').textContent=graphicsError+' Placements remain available as markers.';return;}
  if(!graphics){$('#graphics-status').textContent='Enable Game graphics to load character, collectible and object artwork.';return;}
  const total=graphics.entities.size,unsupported=graphics.summary.unresolved??0,nonvisual=graphics.summary.nonvisual??0;
  $('#graphics-status').textContent=`${total.toLocaleString()} artwork placements${$('#show-graphics').checked?' · '+activeEntities().length.toLocaleString()+' enabled':''}. ${unsupported.toLocaleString()} unsupported · ${nonvisual.toLocaleString()} event / camera markers.`;
  for(const key of Object.keys(graphicLabels))$(`[data-graphic-count="${key}"]`).textContent=' ('+[...graphics.entities.values()].filter(t=>graphicCategory(t)===key).length+')';
 }
 async function ensureGraphics(){
  if(graphics)return;if(graphicsPromise)return graphicsPromise;graphicsLoading=true;graphicsError='';graphicsStatus();$('#graphics-status').textContent='Loading placement artwork…';
  graphicsPromise=window.loadMapEntities({mapName,mapSha256:data.sha256,markers,objects,onProgress:(n,total)=>{$('#graphics-status').textContent=`Loading artwork: ${n} / ${total} images…`;}})
   .then(result=>{graphics=result;}).catch(e=>{graphicsError=e.message;}).finally(()=>{graphicsLoading=false;graphicsPromise=null;graphicsStatus();markerList();if(selected)select(selected);else draw();});
  return graphicsPromise;
 }
 function markerList(){const q=$('#marker-search').value.trim().toLowerCase();const found=[...markerObjects(),...(graphics?[...graphics.entities.values()].filter(e=>!e.marker.marker).map(e=>e.marker):[])].filter(t=>visible.has(t.layer)&&(!t.marker||markerVisible(t))&&(!q||(t.name+' '+data.layers[t.layer].name+' '+(graphics?.entities.get(t.id)?.record?.name||'')).toLowerCase().includes(q)));$('#marker-count').textContent=`${found.length} matching placements · ${Math.min(found.length,markerLimit)} shown`;$('#marker-results').innerHTML=found.slice(0,markerLimit).map(t=>{const entity=graphics?.entities.get(t.id);return `<button data-marker="${t.id}" aria-label="Locate ${esc(t.name)}">${entity?`<img src="${esc(entity.imageURL)}" alt="" loading="lazy">`:''}<span><strong>${esc(t.name)}</strong><small>${esc(typeLabels[markerType(t)])} · X ${t.position[0]}, Z ${t.position[2]}${entity?' · Artwork available':''}</small></span></button>`}).join('')||'<p>No matching placements. Try another name, enable a marker type or restore its layer.</p>';$('#marker-more').hidden=found.length<=markerLimit}

 const art=await window.createMapArt(tiles).catch(e=>{$('.badge').textContent='Layout only · artwork unresolved';$('#render-mode').value='layout';$('#render-mode').options[0].disabled=true;$('#render-mode').options[1].disabled=true;return null});
 if(art&&art.matched<tiles.length*.5)$('#render-mode').value='layout';
 if(art)$('.badge').textContent=`Tile artwork: ${art.matched.toLocaleString()} / ${tiles.length.toLocaleString()}`;
 if(['art','top','layout'].includes(initial.get('mode'))&&art)$('#render-mode').value=initial.get('mode');$('#show-markers').checked=initial.get('markers')!=='0';
 const artwork=()=>art&&$('#render-mode').value!=='layout', tilted=()=>artwork()&&$('#render-mode').value==='art';
 const visible=new Set(initial.has('layers')?initial.get('layers').split(',').filter(x=>/^\d+$/.test(x)).map(Number):data.layers.map((_,i)=>i));let selected=null,width=0,height=0,scale=20,fitScale=20,ox=0,oy=0,drag=null;
 const floorTiles=tiles.filter(t=>/^floor(?:_|\d|$)/.test(data.layers[t.layer].name));
 const ordered=[...tiles].sort((a,b)=>b.layer-a.layer),bounds=(floorTiles.length?floorTiles:tiles).reduce((b,t)=>({minX:Math.min(b.minX,t.position[0]-1.5),maxX:Math.max(b.maxX,t.position[0]+1.5),minZ:Math.min(b.minZ,t.position[2]-1.5),maxZ:Math.max(b.maxZ,t.position[2]+1.5)}),{minX:Infinity,maxX:-Infinity,minZ:Infinity,maxZ:-Infinity});
 if(!tiles.length)Object.assign(bounds,{minX:0,maxX:1,minZ:0,maxZ:1});
 $('#stats').innerHTML=`<span><strong>${tiles.length}</strong> placed tiles</span><span><strong>${data.layers.length}</strong> layers</span><span><strong>${data.layers.reduce((n,l)=>n+l.events.length,0)}</strong> stored markers</span><span><strong>${data.parsedBytes.toLocaleString()} / ${data.bytes.toLocaleString()}</strong> bytes parsed</span>`;
 $('#layers').innerHTML=data.layers.map((l,i)=>`<label><input type="checkbox" data-layer="${i}" ${visible.has(i)?'checked':''} ${l.tiles.length||l.events.length?'':'disabled'}><span class="swatch" style="background:${colors[l.name]||'#aaa'}"></span>${esc(l.name)}<small>${l.tiles.length+l.events.length}${l.events.length?' markers':''}</small></label>`).join('');
 $('#objects').innerHTML+=[...objects].sort((a,b)=>a.layer-b.layer).map(t=>`<option value="${t.id}">${t.marker?'Marker · ':''}${esc(data.layers[t.layer].name)} / ${esc(t.name)} (${t.position[0]}, ${t.position[2]})</option>`).join('');
 $('.evidence a').href='data/visual/maps/'+encodeURIComponent(mapName)+'.json.gz';$('#evidence').textContent=`KONG version ${data.version}; SHA-256 ${data.sha256}. Reader: ${data.evidence.reader}. Placement: ${data.evidence.placement}.`;
 function point(t){return [ox+t.position[0]*scale,oy-(t.position[2]*(tilted()?.8:1)+t.position[1]*(tilted()?.6:0))*scale]}
 function entityRect(t){const [x,y]=point(t),ax=t.flipX?1-t.anchor[0]:t.anchor[0],w=t.worldWidth*scale,h=t.worldHeight*scale;return {x:x-ax*w,y:y-t.anchor[1]*h,width:w,height:h}}
 function draw(){
  ctx.clearRect(0,0,width,height);
  if($('#grid').checked&&scale>=9){ctx.strokeStyle='#193044';ctx.lineWidth=.5;ctx.beginPath();for(let x=Math.floor(-ox/scale);x<(width-ox)/scale;x++){ctx.moveTo(ox+x*scale,0);ctx.lineTo(ox+x*scale,height)}const zs=scale*(tilted()?.8:1);for(let z=Math.floor((oy-height)/zs);z<oy/zs;z++){ctx.moveTo(0,oy-z*zs);ctx.lineTo(width,oy-z*zs)}ctx.stroke()}
  const entities=activeEntities();
  if(artwork()){ctx.drawImage(art.render({width,height,scale,ox,oy,visible,tilted:tilted(),entities}),0,0,width,height)}
  else for(const t of ordered){if(!visible.has(t.layer))continue;const [x,y]=point(t);if(x< -scale||x>width+scale||y< -scale||y>height+scale)continue;
   const name=data.layers[t.layer].name,s=scale*.91;ctx.fillStyle=colors[name]||'#bbb';ctx.strokeStyle='#0a1420';ctx.lineWidth=Math.max(.6,scale*.025);
   if(name.startsWith('floor')||name.includes('wall')){ctx.fillRect(x-s/2,y-s/2,s,s);ctx.strokeRect(x-s/2,y-s/2,s,s)}
   else{ctx.beginPath();if(name==='gimmick'){ctx.moveTo(x,y-s*.45);ctx.lineTo(x+s*.4,y);ctx.lineTo(x,y+s*.45);ctx.lineTo(x-s*.4,y);ctx.closePath()}else ctx.arc(x,y,s*.3,0,Math.PI*2);ctx.fill();ctx.stroke()}
   if(scale>28&&name==='gimmick'){ctx.fillStyle='#322609';ctx.font=`bold ${Math.min(13,scale*.35)}px system-ui`;ctx.textAlign='center';ctx.textBaseline='middle';ctx.fillText('K',x,y)}
  }
  if(!artwork()){
   ctx.imageSmoothingEnabled=false;
   for(const t of [...entities].sort((a,b)=>b.position[2]-a.position[2])){const r=entityRect(t);if(r.x+r.width<0||r.x>width||r.y+r.height<0||r.y>height)continue;ctx.save();if(t.flipX){ctx.translate(r.x+r.width,r.y);ctx.scale(-1,1);ctx.drawImage(t.image,0,0,r.width,r.height)}else ctx.drawImage(t.image,r.x,r.y,r.width,r.height);ctx.restore()}
  }
  for(const t of markerObjects()){if(!drawMarker(t))continue;const [x,y]=point(t);if(x<0||x>width||y<0||y>height)continue;const l=data.layers[t.layer].name;ctx.fillStyle=l==='npcs'?'#65dccf':l==='monsters'?'#ff8799':l==='events'?'#ffd470':'#b59bff';ctx.strokeStyle='#07111e';ctx.lineWidth=1.5;ctx.beginPath();ctx.arc(x,y,5,0,Math.PI*2);ctx.fill();ctx.stroke();}
  if(selected&&visible.has(selected.layer)){const entity=entities.find(t=>t.id===selected.id);ctx.strokeStyle='#ffe5a0';ctx.lineWidth=2;if(entity){const r=entityRect(entity);ctx.strokeRect(r.x-3,r.y-3,r.width+6,r.height+6)}else if(!selected.marker||drawMarker(selected)){const [x,y]=point(selected);ctx.strokeRect(x-scale*.55,y-scale*.55,scale*1.1,scale*1.1)}}
  $('#zoom').textContent=Math.round(scale/fitScale*100)+'%';graphicsStatus();
 }
 function fit(){scale=Math.min((width-50)/(bounds.maxX-bounds.minX),(height-70)/((bounds.maxZ-bounds.minZ)*(tilted()?.8:1)+2));fitScale=scale;ox=width/2-(bounds.minX+bounds.maxX)/2*scale;oy=height/2+(bounds.minZ+bounds.maxZ)/2*scale*(tilted()?.8:1);draw()}
 function resize(){const rect=canvas.getBoundingClientRect(),oldWidth=width,oldHeight=height;width=rect.width;height=rect.height;const dpr=window.devicePixelRatio||1;canvas.width=Math.round(width*dpr);canvas.height=Math.round(height*dpr);ctx.setTransform(dpr,0,0,dpr,0,0);if(!oldWidth)fit();else{ox+=(width-oldWidth)/2;oy+=(height-oldHeight)/2;draw()}}
 function zoom(f,x=width/2,y=height/2){const next=Math.min(240,Math.max(fitScale*.2,scale*f));const k=next/scale;ox=x-(x-ox)*k;oy=y-(y-oy)*k;scale=next;draw()}
 function artworkDetails(t){
  const entity=graphics?.entities.get(t.id);
  if(!t.marker&&!entity&&!graphics?.unresolved.has(t.id))return '';
  if(!entity)return `<p class="graphic-unresolved">${esc(graphics?graphics.unresolved.get(t.id)||(graphics.nonvisual?.has(t.id)?'Logic / camera placement: no character or object image is expected.':'No supported artwork mapping.'):'Enable Game graphics to inspect artwork availability.')}</p>`;
  const record=entity.record,source=entity.source||{},graphic=entity.graphicData;
  return `<div class="inspector-art"><img src="${esc(entity.imageURL)}" alt="${esc(record?.name||t.name)}"></div><p class="graphic-match">Original artwork · ${esc(graphicLabels[graphicCategory(entity)])}${entity.inactive?' · Inactive at start':''}</p><dl>${record?`<dt>Matched record</dt><dd><a href="index.html?table=${encodeURIComponent(record.table)}&record=${encodeURIComponent(record.id)}#${encodeURIComponent(record.table)}">${esc(record.name||record.id)}</a></dd>`:''}<dt>Asset</dt><dd>${esc(graphic.sourceBundle||entity.graphic)}</dd><dt>Pose</dt><dd>${esc(graphic.animation||'Static / setup pose')}${graphic.skin?' · '+esc(graphic.skin):''}</dd>${source.animation&&source.animation!==graphic.animation?`<dt>Requested pose</dt><dd>${esc(source.animation)}</dd>`:''}<dt>Direction</dt><dd>${esc(graphic.direction||'Stored default')}${source.direction!==undefined?' · code '+esc(source.direction):''}</dd><dt>Mapping</dt><dd>${esc(source.component||'Original placement data')}</dd></dl>${entity.notes?.length?`<p class="muted">${esc(Array.isArray(entity.notes)?entity.notes.join(' '):entity.notes)}</p>`:''}`;
 }
 function select(t){selected=t;$('#objects').value=t?t.id:'';if(t){const l=data.layers[t.layer];$('#inspector').innerHTML=`<h3>${esc(t.name)}</h3>${artworkDetails(t)}<dl><dt>Layer</dt><dd>${esc(l.name)}</dd><dt>Tileset</dt><dd>${esc(t.marker?'Stored '+l.name+' placement':t.tileset)}</dd><dt>X / Y / Z</dt><dd>${t.position.join(' / ')}</dd><dt>Rotation code</dt><dd>${t.rotation??'Not applicable'}</dd><dt>Partition</dt><dd>${t.partition?.join(', ')||'Not applicable'}</dd><dt>Byte offset</dt><dd>${t.offset===undefined?'Marker position from decoded layer':t.offset+' (0x'+t.offset.toString(16)+')'}</dd></dl>`}else{$('#inspector').innerHTML='<p class="empty">Select a tile, character or marker to inspect its source.</p>'}draw();saveView()}
 $('#download-map').onclick=()=>{const u=URL.createObjectURL(new Blob([JSON.stringify(data,null,2)],{type:'application/json'}));const a=document.createElement('a');a.href=u;a.download=mapName+'.json';a.click();setTimeout(()=>URL.revokeObjectURL(u),30000)};
 $('#layers').addEventListener('change',e=>{const n=Number(e.target.dataset.layer);e.target.checked?visible.add(n):visible.delete(n);markerList();draw();saveView()});
 function focusObject(t,restore=false){
  if(!t)return;
  if(!restore){
   visible.add(t.layer);$(`[data-layer="${t.layer}"]`).checked=true;
   const graphic=graphics?.entities.get(t.id);
   if(t.marker){
    markerTypes.add(markerType(t));$(`[data-marker-type="${markerType(t)}"]`).checked=true;
    if(!graphic||!$('#show-graphics').checked){
     if($('#show-graphics').checked&&graphics?.unresolved.has(t.id))$('#fallback-markers').checked=true;
     else $('#show-markers').checked=true;
    }
   }
   if(graphic&&$('#show-graphics').checked){graphicTypes.add(graphicCategory(graphic));$(`[data-graphic-type="${graphicCategory(graphic)}"]`).checked=true;if(graphic.inactive)$('#show-inactive').checked=true}
  }
  scale=Math.max(scale,48);ox=width/2-t.position[0]*scale;oy=height/2+(t.position[2]*(tilted()?.8:1)+t.position[1]*(tilted()?.6:0))*scale;
  markerList();select(t);canvas.scrollIntoView({block:'center',behavior:'smooth'});
 }
 $('#objects').addEventListener('change',e=>e.target.value?focusObject(objectsById.get(e.target.value)):select(null));
 $('#marker-types').onchange=e=>{const key=e.target.dataset.markerType;if(!key)return;e.target.checked?markerTypes.add(key):markerTypes.delete(key);markerLimit=40;markerList();draw();saveView()};
 $('#graphics-types').onchange=e=>{const key=e.target.dataset.graphicType;if(!key)return;e.target.checked?graphicTypes.add(key):graphicTypes.delete(key);draw();saveView()};
 $('#show-graphics').onchange=()=>{graphicsStatus();draw();saveView();if($('#show-graphics').checked)ensureGraphics()};
 $('#fallback-markers').onchange=$('#show-inactive').onchange=()=>{draw();saveView()};
 $('#marker-search').oninput=()=>{markerLimit=40;markerList();saveView()};
 $('#marker-more').onclick=()=>{markerLimit+=40;markerList()};
 $('#marker-results').onclick=e=>{const b=e.target.closest('[data-marker]');if(b)focusObject(objects.find(t=>t.id===b.dataset.marker))};
 $('#render-mode').onchange=()=>{fit();saveView()};$('#show-markers').onchange=()=>{draw();saveView()};$('#grid').onchange=draw;$('#fit').onclick=fit;$('#zoom-in').onclick=()=>zoom(1.3);$('#zoom-out').onclick=()=>zoom(1/1.3);
 const pos=e=>{const r=canvas.getBoundingClientRect();return [e.clientX-r.left,e.clientY-r.top]};
 canvas.addEventListener('wheel',e=>{e.preventDefault();zoom(Math.exp(-e.deltaY*.0015),...pos(e))},{passive:false});
 canvas.addEventListener('pointerdown',e=>{const [x,y]=pos(e);drag={x,y,sx:x,sy:y,moved:false};canvas.setPointerCapture(e.pointerId)});
 canvas.addEventListener('pointermove',e=>{const [x,y]=pos(e);$('#coords').textContent=`X ${((x-ox)/scale).toFixed(1)} · Z ${((oy-y)/scale/(tilted()?.8:1)).toFixed(1)}`;if(drag){ox+=x-drag.x;oy+=y-drag.y;drag.moved||=Math.hypot(x-drag.sx,y-drag.sy)>4;drag.x=x;drag.y=y;draw()}});
 const imageMasks=new WeakMap();
 function hitEntity(t,x,y){
  const r=entityRect(t),u=(x-r.x)/r.width,v=(y-r.y)/r.height;if(u<0||u>=1||v<0||v>=1)return false;
  if(!imageMasks.has(t.image)){const c=document.createElement('canvas');c.width=t.image.width;c.height=t.image.height;const c2=c.getContext('2d',{willReadFrequently:true});c2.drawImage(t.image,0,0);imageMasks.set(t.image,c2.getImageData(0,0,c.width,c.height).data)}
  const px=Math.min(t.image.width-1,Math.floor((t.flipX?1-u:u)*t.image.width)),py=Math.floor(v*t.image.height);return imageMasks.get(t.image)[(py*t.image.width+px)*4+3]>10;
 }
 canvas.addEventListener('pointerup',e=>{if(drag&&!drag.moved){const [x,y]=pos(e);const hits=ordered.filter(t=>{const [a,b]=point(t);return visible.has(t.layer)&&Math.abs(x-a)<scale*.5&&Math.abs(y-b)<scale*.5});const markerHits=markerObjects().filter(t=>{const [a,b]=point(t);return drawMarker(t)&&Math.hypot(x-a,y-b)<9});const entityHits=activeEntities().filter(t=>hitEntity(t,x,y)).sort((a,b)=>(b.position[2]*(tilted()?.6:0)-b.position[1]*(tilted()?.8:1))-(a.position[2]*(tilted()?.6:0)-a.position[1]*(tilted()?.8:1)));select(markerHits.at(-1)||entityHits.at(-1)?.marker||hits.at(-1)||null)}drag=null});
 canvas.addEventListener('pointercancel',()=>drag=null);
 canvas.addEventListener('keydown',e=>{if(['ArrowLeft','ArrowRight','ArrowUp','ArrowDown','+','=','-','0'].includes(e.key)){e.preventDefault();if(e.key==='0')return fit();if(e.key==='+'||e.key==='=')return zoom(1.3);if(e.key==='-')return zoom(1/1.3);ox+=e.key==='ArrowLeft'?30:e.key==='ArrowRight'?-30:0;oy+=e.key==='ArrowUp'?30:e.key==='ArrowDown'?-30:0;draw()}});
 function saveView(){const p=new URLSearchParams({map:mapName,mode:$('#render-mode').value,markers:$('#show-markers').checked?'1':'0',graphics:$('#show-graphics').checked?'1':'0',fallback:$('#fallback-markers').checked?'1':'0',inactive:$('#show-inactive').checked?'1':'0',layers:[...visible].join(','),types:[...markerTypes].join(','),graphicTypes:[...graphicTypes].join(','),mq:$('#marker-search').value});if(selected)p.set('object',selected.id);history.replaceState(null,'','?'+p)}
 new ResizeObserver(resize).observe(canvas);resize();markerList();graphicsStatus();if(initial.has('object')){const t=objects.find(t=>t.id===initial.get('object'));if(t)focusObject(t,true)}saveView();if($('#show-graphics').checked)ensureGraphics();
 }catch(e){$('#stats').textContent=`Unable to display the map: ${e.message}`;console.error(e)}
})();
