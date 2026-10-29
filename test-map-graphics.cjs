// Real map interaction plus a small visual depth/alpha fixture for the renderer.
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),http=require('node:http'),zlib=require('node:zlib');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const root=path.resolve('dist'),output=process.env.ATLAS_GRAPHICS_QA||path.join(require('node:os').tmpdir(),'guardian-atlas-map-graphics');
fs.mkdirSync(output,{recursive:true});
const server=http.createServer((req,res)=>{
 const target=path.resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname));
 if(!target.startsWith(root+path.sep)){res.writeHead(403).end();return;}
 try{const stat=fs.statSync(target);res.setHeader('Content-Type',({'.js':'text/javascript','.css':'text/css','.json':'application/json','.svg':'image/svg+xml','.png':'image/png','.webp':'image/webp','.html':'text/html'})[path.extname(target)]||'application/octet-stream');res.setHeader('Content-Length',stat.size);fs.createReadStream(target).pipe(res);}catch{res.writeHead(404).end();}
});
(async()=>{
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));const base='http://127.0.0.1:'+server.address().port;
 const browser=await chromium.launch({channel:'msedge',headless:true,args:['--enable-unsafe-swiftshader','--use-angle=swiftshader']});
 try{
  const index=JSON.parse(zlib.gunzipSync(fs.readFileSync(path.join(root,'data/visual/map-entities/index.json.gz'))));
  const mapName='short_story_invader2',entry=index.maps[mapName];assert(entry,'new story map has an artwork manifest');
  const manifest=JSON.parse(zlib.gunzipSync(fs.readFileSync(path.join(root,'data/visual/map-entities',entry.path))));
  const map=JSON.parse(zlib.gunzipSync(fs.readFileSync(path.join(root,'data/visual/maps',mapName+'.json.gz'))));
  const placement=manifest.placements.find(p=>p.id==='m:3:20')||manifest.placements.find(p=>{if(p.inactive||!p.id.startsWith('m:'))return false;const [,l,i]=p.id.split(':').map(Number);return map.layers[l].events[i].position[0]<500;});
  assert(placement,'at least one real on-map character image is available');
  const graphic=index.graphics[placement.graphic];
  const page=await browser.newPage({viewport:{width:1440,height:1000}}),errors=[],requests=[];
  page.on('pageerror',e=>errors.push(e.message));page.on('request',r=>requests.push(r.url()));
  await page.goto(base+'/map-preview.html?map='+mapName);
  await page.locator('#marker-results button').first().waitFor({timeout:60000});
  assert(!requests.some(url=>url.includes('/map-entities/')),'markers-only view does not download placement artwork');
  await page.locator('#render-mode').selectOption('top');await page.locator('#fit').click();
  await page.evaluate(()=>window.scrollTo(0,250));const mapBox=await page.locator('#map').boundingBox();
  async function coordinates(x,y){await page.mouse.move(mapBox.x+x,mapBox.y+y);return (await page.locator('#coords').innerText()).match(/-?\d+(?:\.\d+)?/g).map(Number);}
  const cornerA=await coordinates(1,1),cornerB=await coordinates(mapBox.width-1,mapBox.height-1);
  const floors=map.layers.filter(layer=>/^floor(?:_|\d|$)/.test(layer.name)).flatMap(layer=>layer.tiles);
  assert(floors.every(tile=>tile.position[0]>=cornerA[0]-.2&&tile.position[0]<=cornerB[0]+.2&&tile.position[2]<=cornerA[1]+.2&&tile.position[2]>=cornerB[1]-.2),'Fit map includes floor_playroom and other floor layers');
  await page.locator('#render-mode').selectOption('art');
  await page.locator('#show-graphics').check();
  await page.waitForFunction(()=>document.querySelector('#graphics-status')?.dataset.state==='ready',null,{timeout:120000});
  assert(requests.some(url=>url.endsWith('/map-entities/'+graphic.image)),'native character image was requested');
  await page.locator('#show-markers').uncheck();await page.locator('#fallback-markers').uncheck();
  await page.locator('#objects').selectOption(placement.id);
  await page.locator('#inspector img').evaluate(img=>img.decode());
  assert((await page.locator('#inspector').innerText()).includes(placement.record.name));
  assert((await page.locator('#inspector a').getAttribute('href')).includes('record='+placement.record.id));
  const snapshot=()=>page.locator('#map').evaluate(canvas=>canvas.toDataURL());
  const withArt=await snapshot();await page.locator('#show-graphics').uncheck();assert.notEqual(await snapshot(),withArt,'game graphics change the actual map pixels');await page.locator('#show-graphics').check();
  const opaque=await page.locator('#inspector img').evaluate(image=>{const c=document.createElement('canvas');c.width=image.naturalWidth;c.height=image.naturalHeight;const x=c.getContext('2d');x.drawImage(image,0,0);const pixels=x.getImageData(0,0,c.width,c.height).data;let result=null,distance=Infinity;for(let y=0;y<c.height;y++)for(let x=0;x<c.width;x++){const d=(x-c.width/2)**2+(y-c.height/2)**2;if(pixels[(y*c.width+x)*4+3]>250&&d<distance){distance=d;result=[(x+.5)/c.width,(y+.5)/c.height];}}return result;});
  assert(opaque);await page.locator('#objects').selectOption('');
  const hitBox=await page.locator('#map').boundingBox(),flip=!!placement.flipX,anchorX=flip?1-graphic.anchor[0]:graphic.anchor[0];
  await page.locator('#map').click({position:{x:hitBox.width/2+((flip?1-opaque[0]:opaque[0])-anchorX)*graphic.worldWidth*48,y:hitBox.height/2+(opaque[1]-graphic.anchor[1])*graphic.worldHeight*48}});
  assert.equal(await page.locator('#objects').inputValue(),placement.id,'clicking the character image selects its source placement');
  await page.locator('#fallback-markers').check();
  const withFallback=await snapshot(),cameraLayer=map.layers.findIndex(layer=>layer.name.includes('camera'));
  if(cameraLayer>=0){await page.locator(`[data-layer="${cameraLayer}"]`).uncheck();assert.equal(await snapshot(),withFallback,'graphics-only fallback does not draw nonvisual camera markers');await page.locator(`[data-layer="${cameraLayer}"]`).check();}
  await page.locator('#fallback-markers').uncheck();
  const category=placement.category in {npcs:1,monsters:1,collectibles:1,objects:1}?placement.category:'objects';
  await page.locator(`[data-graphic-type="${category}"]`).uncheck();const hidden=await snapshot();await page.locator(`[data-graphic-type="${category}"]`).check();assert.notEqual(await snapshot(),hidden,'category toggle changes rendered pixels');
  const layer=placement.id.split(':')[1];await page.locator(`[data-layer="${layer}"]`).uncheck();assert(!await page.locator(`#marker-results [data-marker="${placement.id}"]`).count(),'source layer hides placement results');await page.locator(`[data-layer="${layer}"]`).check();
  for(const mode of ['top','layout','art']){await page.locator('#render-mode').selectOption(mode);await page.locator('#objects').selectOption(placement.id);assert((await snapshot()).length>1000);}
  const collectible=manifest.placements.find(p=>p.category==='collectibles'&&!p.id.startsWith('m:'));
  assert(collectible,'story map exposes a native collectible tile graphic');
  await page.locator('#objects').selectOption(collectible.id);await page.locator('#inspector img').evaluate(img=>img.decode());
  assert((await page.locator('#inspector').innerText()).includes('Coins / collectibles'));
  const withCollectible=await snapshot();await page.locator('[data-graphic-type="collectibles"]').uncheck();assert.notEqual(await snapshot(),withCollectible,'collectible category controls real tile graphics');await page.locator('[data-graphic-type="collectibles"]').check();
  await page.locator('#objects').selectOption(placement.id);
  await page.screenshot({path:path.join(output,'map-game-graphics-desktop.png'),fullPage:true});
  const url=page.url();assert(url.includes('graphics=1')&&url.includes('markers=0'));
  await page.reload();await page.waitForFunction(()=>document.querySelector('#graphics-status')?.dataset.state==='ready',null,{timeout:120000});
  assert(await page.locator('#show-graphics').isChecked());assert.equal(await page.locator('#show-markers').isChecked(),false,'URL restore keeps graphics-only view while artwork is loading');assert.equal(await page.locator('#objects').inputValue(),placement.id);
  await page.setViewportSize({width:390,height:844});assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'map page fits mobile width');
  await page.screenshot({path:path.join(output,'map-game-graphics-mobile.png'),fullPage:true});
  for(const otherMap of ['invader_reporter','afterworld_1_1','ancientdungeon_red_1_1']){
   await page.goto(base+'/map-preview.html?map='+otherMap+'&graphics=1&markers=0');
   await page.waitForFunction(()=>document.querySelector('#graphics-status')?.dataset.state==='ready',null,{timeout:120000});
   assert((await page.locator('#graphics-status').innerText()).includes('artwork placements'),otherMap+' artwork status');
   assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),otherMap+' fits mobile');
   if(otherMap==='afterworld_1_1'){
    const before=await page.locator('#graphics-status').innerText();await page.locator('#show-inactive').check();const after=await page.locator('#graphics-status').innerText();
    assert.notEqual(before,after,'native inactive placements are excluded until explicitly enabled');
   }
  }
  // A resolved sprite missing from disk must become inspectable fallback data.
  const failure=await browser.newPage();await failure.route('**/map-entities/'+graphic.image,route=>route.abort());
  await failure.goto(base+'/map-preview.html?map='+mapName+'&graphics=1&markers=0&object='+encodeURIComponent(placement.id));
  await failure.waitForFunction(()=>document.querySelector('#graphics-status')?.dataset.state==='ready',null,{timeout:120000});
  assert((await failure.locator('#inspector').innerText()).includes('could not be loaded'),'missing artwork has an explicit inspectable fallback');await failure.close();
  // Test actual rasterized wall occlusion with a billboard in front and behind.
  const depth=await browser.newPage({viewport:{width:240,height:240}});
  await depth.goto(base+'/map-art.js');
  await depth.setContent('<canvas id="out" width="200" height="200"></canvas>');await depth.addScriptTag({url:base+'/map-art.js'});
  const scene={materials:{red:{texture:'red.png',scale:[1,1],offset:[0,0]}},meshes:{wall:[{material:'red',vertices:[[-1,0,0],[1,0,0],[-1,2,0],[1,2,0]],uv:[[0,0],[1,0],[0,1],[1,1]],triangles:[[0,1,2],[2,1,3]]}]}};
  await depth.route('**/data/visual/tilesets.json',route=>route.fulfill({json:{fixture:{path:'fixture/scene.json.gz'}}}));
  await depth.route('**/data/visual/fixture/scene.json.gz',route=>route.fulfill({body:zlib.gzipSync(JSON.stringify(scene))}));
  await depth.route('**/data/visual/fixture/red.png',async route=>{
   const b64=await depth.evaluate(()=>{const c=document.createElement('canvas');c.width=c.height=1;const x=c.getContext('2d');x.fillStyle='#f00';x.fillRect(0,0,1,1);return c.toDataURL().split(',')[1];});await route.fulfill({body:Buffer.from(b64,'base64'),contentType:'image/png'});
  });
  const pixels=await depth.evaluate(async()=>{
   const art=await createMapArt([{tileset:'fixture',name:'wall',position:[0,0,0],rotation:0,layer:0}]);
   const c=document.createElement('canvas');c.width=c.height=4;const cx=c.getContext('2d');cx.fillStyle='#0f0';cx.fillRect(0,0,4,4);cx.clearRect(0,0,2,2);
   const image=new Image();image.src=c.toDataURL();await image.decode();
   const out=document.querySelector('#out').getContext('2d'),sample=z=>{out.clearRect(0,0,200,200);out.drawImage(art.render({width:200,height:200,scale:50,ox:100,oy:160,visible:new Set([0]),tilted:true,entities:[{position:[0,0,z],layer:0,image,worldWidth:1.5,worldHeight:2,anchor:[.5,1]}]}),0,0);return [...out.getImageData(100,110,1,1).data];};
   return {behind:sample(1),front:sample(-.2)};
  });
  assert(pixels.behind[0]>240&&pixels.behind[1]<20,'wall occludes the character behind it');assert(pixels.front[1]>240&&pixels.front[0]<20,'character in front covers the wall');await depth.close();
  assert.deepEqual(errors,[]);
  console.log(JSON.stringify({status:'passed',map:mapName,placement:placement.id,checks:['all floor layers fit','lazy loading','original images','source inspector','sprite picking','graphics and category toggles','nonvisual markers excluded from graphics-only view','collectible tile graphics','layer filtering','three views','URL restore','mobile layout','old and empty map support','native inactive toggle','missing-image fallback','wall depth occlusion'],output}));
 }finally{await browser.close();server.close();}
})().catch(error=>{console.error(error);server.close();process.exitCode=1;});
