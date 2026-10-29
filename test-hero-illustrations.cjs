// Exercises gallery navigation, real PNG alpha downloads and failure states in a browser.
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),http=require('node:http'),zlib=require('node:zlib'),crypto=require('node:crypto');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const root=path.resolve('dist'),output=process.env.ATLAS_ILLUSTRATIONS_QA||path.join(require('node:os').tmpdir(),'guardian-atlas-hero-illustrations');
fs.mkdirSync(output,{recursive:true});
const server=http.createServer((req,res)=>{
  const target=path.resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname));
  if(!target.startsWith(root+path.sep)){res.writeHead(403).end();return;}
  try{const stat=fs.statSync(target);res.setHeader('Content-Type',({'.js':'text/javascript','.css':'text/css','.json':'application/json','.svg':'image/svg+xml','.png':'image/png','.webp':'image/webp','.html':'text/html'})[path.extname(target)]||'application/octet-stream');res.setHeader('Content-Length',stat.size);fs.createReadStream(target).pipe(res);}catch{res.writeHead(404).end();}
});
const fixture={version:'test fixture',packs:[{label:'All PNGs',url:'test-illustrations/collection.zip',bytes:1520000000}],illustrations:[
  {id:'indaver_journalist',heroName:'Amelia Gray',variant:'Standard',heroId:123,sourceBundle:'illusts/illust_indaver_journalist',notes:['Fixture data: test image, not game artwork.'],preview:'test-illustrations/amelia-preview.png',files:{character:{url:'test-illustrations/amelia-character.png',preview:'test-illustrations/amelia-preview.png',width:32,height:48,bytes:1250000},effects:{url:'test-illustrations/amelia-effects.png',width:32,height:48},effectsOnly:{url:'test-illustrations/amelia-effects-only.png',width:32,height:48}}},
  {id:'indaver_journalist_myth',heroName:'Amelia Gray',variant:'Myth',sourceBundle:'illusts/illust_indaver_journalist_myth',preview:'test-illustrations/amelia-myth.png',files:{character:{url:'test-illustrations/amelia-myth.png',width:32,height:48}}},
  {id:'only_character',heroName:'Character without effects',variant:'Standard',preview:'test-illustrations/no-effects.png',files:{character:{url:'test-illustrations/no-effects.png',width:32,height:48}}},
  {id:'unavailable',heroName:'Unavailable illustration',variant:'Additional artwork',status:'unavailable',notes:['No verified export.']},
  {id:'missing_image',heroName:'Missing preview',variant:'Additional artwork',preview:'test-illustrations/missing.png',files:{character:{url:'test-illustrations/missing.png'}}},
  ...Array.from({length:25},(_,i)=>({id:'fixture_'+i,heroName:'Pagination hero '+String(i).padStart(2,'0'),variant:'Standard',preview:'test-illustrations/page-'+i+'.png',files:{character:{url:'test-illustrations/page-'+i+'.png',width:32,height:48}}}))
]};
(async()=>{
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));const base='http://127.0.0.1:'+server.address().port;
  const browser=await chromium.launch({channel:process.env.PLAYWRIGHT_CHANNEL||'msedge',headless:true});
  try{
    const maker=await browser.newPage();
    const png64=await maker.evaluate(()=>{const c=document.createElement('canvas');c.width=32;c.height=48;const x=c.getContext('2d');x.fillStyle='#f6c85f';x.fillRect(8,8,16,32);x.fillStyle='#acdeff80';x.fillRect(2,4,8,10);return c.toDataURL().split(',')[1];});await maker.close();const png=Buffer.from(png64,'base64');
    const page=await browser.newPage({viewport:{width:1440,height:1000}}),errors=[],requests=[];
    page.on('pageerror',error=>errors.push(error.message));page.on('request',r=>requests.push(r.url()));
    await page.route('**/data/hero-illustrations/index.json',route=>route.fulfill({json:fixture}));
    await page.route('**/test-illustrations/*.png',route=>route.request().url().endsWith('/missing.png')?route.fulfill({status:404}):route.fulfill({body:png,contentType:'image/png'}));
    await page.goto(base+'/hero-illustrations.html');await page.locator('#illustration-grid[aria-busy="false"]').waitFor();
    assert.equal(await page.locator('.illustration-card').count(),24,'pagination caps initial DOM and image requests');
    assert(await page.locator('nav[aria-label="Explore"] a[href="hero-illustrations.html"]').getAttribute('aria-current')==='page');
    assert(!requests.some(url=>url.endsWith('amelia-character.png')),'grid loads a compact preview instead of the full-resolution PNG');
    assert(await page.locator('#collection-packs a').isVisible());assert((await page.locator('#collection-packs a').innerText()).includes('1.52 GB ZIP'));
    await page.locator('#illustration-next').click();assert.equal(await page.locator('.illustration-card').count(),6);assert(page.url().includes('page=2'));
    await page.locator('#illustration-search').fill('indaver_journalist');await page.waitForFunction(()=>document.querySelectorAll('.illustration-card').length===2);
    await page.locator('#illustration-variant').selectOption('Myth');assert.equal(await page.locator('.illustration-card').count(),1);
    await page.locator('#illustration-variant').selectOption('');await page.locator('#illustration-artwork').selectOption('effects');assert.equal(await page.locator('.illustration-card').count(),1);
    await page.locator('[data-id="indaver_journalist"]').click();await page.locator('#detail-image').evaluate(image=>image.decode());
    assert((await page.locator('#detail-size').innerText()).includes('1.3 MB'));assert.equal(await page.locator('#detail-view option').count(),3);assert(page.url().includes('id=indaver_journalist'));
    assert(!requests.some(url=>url.endsWith('amelia-character.png')),'opening the inspector still uses its compact preview');
    await page.locator('#detail-full-preview').click();await page.locator('#detail-image').evaluate(image=>image.decode());assert((await page.locator('#detail-image').getAttribute('src')).endsWith('/amelia-character.png'));assert(await page.locator('#detail-full-preview').isDisabled(),'full image is loaded only on request');
    await page.locator('[name="preview-background"][value="light"]').check();assert.equal(await page.locator('#detail-canvas').getAttribute('data-background'),'light');
    await page.locator('#detail-view').selectOption('effects');await page.locator('#detail-image').evaluate(image=>image.decode());assert((await page.locator('#detail-image').getAttribute('src')).endsWith('/amelia-effects.png'));
    const download=page.waitForEvent('download');await page.locator('#detail-download').click();const downloaded=await download;assert(downloaded.suggestedFilename().endsWith('.png'));const downloadedPath=path.join(output,'fixture-transparent.png');await downloaded.saveAs(downloadedPath);assert.deepEqual(fs.readFileSync(downloadedPath),png,'PNG download preserves exact original bytes including alpha');
    const alpha=await page.locator('#detail-image').evaluate(image=>{const c=document.createElement('canvas');c.width=image.naturalWidth;c.height=image.naturalHeight;const x=c.getContext('2d');x.drawImage(image,0,0);const d=x.getImageData(0,0,c.width,c.height).data;return{corner:d[3],opaque:d[(20*c.width+16)*4+3],partial:d[(5*c.width+3)*4+3]};});assert.equal(alpha.corner,0);assert.equal(alpha.opaque,255);assert(alpha.partial>0&&alpha.partial<255);
    await page.reload();await page.locator('#illustration-detail[open]').waitFor();assert.equal(await page.locator('#detail-view').inputValue(),'effects','deep link restores version');
    await page.keyboard.press('Escape');await page.locator('#illustration-detail').waitFor({state:'hidden'});await page.waitForFunction(()=>!new URL(location.href).searchParams.has('id'));
    await page.locator('#illustration-reset').click();await page.locator('#illustration-search').fill('only_character');await page.waitForFunction(()=>document.querySelectorAll('.illustration-card').length===1);await page.locator('.illustration-card-button').click();assert.equal(await page.locator('#detail-view option').count(),1,'does not invent an effects version');assert(await page.locator('#detail-view').isDisabled());await page.locator('#detail-close').click();
    assert.equal(await page.evaluate(()=>document.activeElement.dataset.id),'only_character','closing the dialog restores keyboard focus');
    await page.locator('#illustration-search').fill('unavailable');await page.waitForFunction(()=>document.querySelector('[data-id="unavailable"]'));await page.locator('[data-id="unavailable"]').click();assert(await page.locator('#detail-download').isDisabled());assert((await page.locator('#detail-image-state').innerText()).includes('No verified export'));await page.locator('#detail-close').click();
    await page.locator('#illustration-search').fill('missing_image');await page.waitForFunction(()=>document.querySelector('[data-id="missing_image"]'));await page.locator('[data-id="missing_image"]').click();await page.waitForFunction(()=>document.querySelector('#detail-image-state').textContent.includes('could not be loaded'));const failedDownload=await page.locator('#detail-download').click();await page.waitForFunction(()=>document.querySelector('#detail-download-status').textContent.includes('could not be prepared'));await page.locator('#detail-close').click();
    await page.locator('#illustration-search').fill('no match exists');await page.locator('#illustration-empty').waitFor();await page.locator('#illustration-reset').click();
    await page.setViewportSize({width:390,height:844});assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'gallery fits a narrow mobile screen');
    await page.locator('[data-id="indaver_journalist"]').click();assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'illustration inspector fits a narrow mobile screen');assert(await page.locator('#detail-download').isVisible());await page.locator('#detail-close').click();
    assert.deepEqual(errors,[],'gallery has no JavaScript errors');await page.close();
    const failure=await browser.newPage();await failure.route('**/data/hero-illustrations/index.json',route=>route.fulfill({status:503}));await failure.goto(base+'/hero-illustrations.html');await failure.locator('#collection-error').waitFor();assert((await failure.locator('#collection-error').innerText()).includes('503'));await failure.close();
    const gzip=await browser.newPage();await gzip.route('**/data/hero-illustrations/index.json',route=>route.fulfill({status:404}));await gzip.route('**/data/hero-illustrations/index.json.gz',route=>route.fulfill({body:zlib.gzipSync(JSON.stringify(fixture))}));await gzip.route('**/test-illustrations/*.png',route=>route.fulfill({body:png,contentType:'image/png'}));await gzip.goto(base+'/hero-illustrations.html');await gzip.locator('.illustration-card').first().waitFor();await gzip.close();
    // Model release hosting on another origin with no CORS headers and attachment disposition.
    const nativeRequests=[];
    const remoteServer=http.createServer((req,res)=>{nativeRequests.push(req.headers['sec-fetch-dest']);res.setHeader('Content-Type','image/png');res.setHeader('Content-Disposition','attachment; filename="native-remote.png"');res.end(png);});
    await new Promise(resolve=>remoteServer.listen(0,'127.0.0.1',resolve));
    try{
      const remoteURL='http://127.0.0.1:'+remoteServer.address().port+'/native.png',entry=structuredClone(fixture.illustrations[0]);entry.files.character.url=remoteURL;entry.files.character.format='png';
      const remote=await browser.newPage();await remote.route('**/data/hero-illustrations/index.json',route=>route.fulfill({json:{illustrations:[entry]}}));await remote.route('**/test-illustrations/*.png',route=>route.fulfill({body:png,contentType:'image/png'}));
      await remote.goto(base+'/hero-illustrations.html?id='+entry.id);await remote.locator('#detail-image').evaluate(image=>image.decode());assert.equal(nativeRequests.length,0);
      await remote.locator('#detail-full-preview').click();await remote.locator('#detail-image').evaluate(image=>image.decode());assert(nativeRequests.includes('image'),'native cross-origin preview is an ordinary image request');
      const event=remote.waitForEvent('download',{timeout:10000});await remote.locator('#detail-download').click();const download=await event,target=path.join(output,'native-remote.png');await download.saveAs(target);assert.deepEqual(fs.readFileSync(target),png,'cross-origin attachment downloads without CORS');assert(!nativeRequests.includes('empty'),'cross-origin PNG does not use fetch');await remote.close();
    }finally{remoteServer.close();}
    const catalogPath=path.join(root,'data/hero-illustrations/index.json');
    if(fs.existsSync(catalogPath)){
      const liveBase=process.env.ATLAS_ILLUSTRATIONS_LOCAL_BASE||base;
      const catalog=await(await fetch(liveBase+'/data/hero-illustrations/index.json')).json(),rows=catalog.illustrations||[];assert(rows.length>100,'real collection covers the hero catalogue');
      const live=await browser.newPage({viewport:{width:1440,height:1000}}),liveErrors=[];live.on('pageerror',error=>liveErrors.push(error.message));
      await live.goto(liveBase+'/hero-illustrations.html');await live.locator('.illustration-card').first().waitFor();
      const localPreviews=rows.flatMap(row=>[row.preview,...Object.values(row.files||{}).map(file=>file.preview)]).filter(value=>typeof value==='string'&&!/^https?:/.test(value));
      assert(localPreviews.length>=rows.length,'every illustration has a local preview');for(const value of localPreviews)assert(fs.existsSync(path.resolve(root,value)),value+' exists');
      await live.locator('.card-picture img').evaluateAll(images=>Promise.all(images.map(image=>{image.loading='eager';return image.decode();})));
      await live.screenshot({path:path.join(output,'gallery-desktop.png'),fullPage:true});
      for(const id of [rows.find(row=>/indaver_journalist.*myth/.test(row.id))?.id,rows.find(row=>!/indaver_journalist/.test(row.id)&&row.files?.character)?.id].filter(Boolean)){
        await live.goto(liveBase+'/hero-illustrations.html?id='+encodeURIComponent(id));await live.locator('#illustration-detail[open]').waitFor();await live.locator('#detail-image').evaluate(image=>image.decode());
        for(const value of await live.locator('#detail-view option').evaluateAll(options=>options.map(option=>option.value))){
          await live.locator('#detail-view').selectOption(value);await live.locator('#detail-image').evaluate(image=>image.decode());
          if((process.env.ATLAS_ILLUSTRATIONS_LOCAL_BASE||process.env.ATLAS_ILLUSTRATIONS_FULL_REMOTE)&&/indaver_journalist/.test(id)){
            const file=rows.find(row=>row.id===id).files[value];await live.locator('#detail-full-preview').click();await live.locator('#detail-image').evaluate(image=>image.decode());
            assert.equal(await live.locator('#detail-image').evaluate(image=>image.naturalWidth),file.width,'explicit full-resolution preview uses the native PNG');
            for(const background of ['dark','light']){await live.locator('[name="preview-background"][value="'+background+'"]').check();await live.screenshot({path:path.join(output,'amelia-myth-'+value+'-'+background+'.png')});}
            await live.locator('[name="preview-background"][value="checker"]').check();
          }
          if(process.env.ATLAS_ILLUSTRATIONS_LOCAL_BASE&&/indaver_journalist/.test(id)){
            const file=rows.find(row=>row.id===id).files[value];assert.equal(new URL(file.url,liveBase).origin,new URL(liveBase).origin,'real download test stays on the local preview server');
            const event=live.waitForEvent('download');await live.locator('#detail-download').click();const download=await event,target=path.join(output,download.suggestedFilename());await download.saveAs(target);const bytes=fs.readFileSync(target);
            assert.deepEqual([...bytes.subarray(0,8)],[137,80,78,71,13,10,26,10],'real download is a PNG');assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'),file.sha256,'download is exactly the verified native PNG');
            const transparent=await live.evaluate(async url=>{const bitmap=await createImageBitmap(await(await fetch(url)).blob()),c=document.createElement('canvas');c.width=bitmap.width;c.height=bitmap.height;const x=c.getContext('2d');x.drawImage(bitmap,0,0);const corners=[[0,0],[c.width-1,0],[0,c.height-1],[c.width-1,c.height-1]].map(([a,b])=>x.getImageData(a,b,1,1).data[3]);const size=[c.width,c.height];bitmap.close();c.width=c.height=0;return{corners,size};},file.url);
            assert(transparent.corners.some(alpha=>alpha===0),'actual exported PNG has transparent outside pixels');assert.deepEqual(transparent.size,[file.width,file.height]);
          }
        }
      }
      await live.locator('#detail-view').selectOption('character');await live.locator('#detail-image').evaluate(image=>image.decode());await live.screenshot({path:path.join(output,'gallery-detail-desktop.png')});await live.setViewportSize({width:390,height:844});assert(await live.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1));await live.screenshot({path:path.join(output,'gallery-detail-mobile.png')});await live.locator('#detail-close').click();await live.waitForFunction(()=>document.querySelector('#site-sidebar').getBoundingClientRect().right<=1);await live.screenshot({path:path.join(output,'gallery-mobile-viewport.png'),animations:'disabled'});await live.screenshot({path:path.join(output,'gallery-mobile.png'),fullPage:true,animations:'disabled'});assert.deepEqual(liveErrors,[]);await live.close();
      console.log('Real illustration catalogue and preview smoke checks passed: '+rows.length+' illustrations.');
    }else console.log('Real catalogue not generated yet; fixture interaction and alpha checks passed.');
    console.log('Hero illustrations browser checks passed. Output: '+output);
  }finally{await browser.close();server.close();}
})().catch(error=>{console.error(error);server.close();process.exitCode=1;});
