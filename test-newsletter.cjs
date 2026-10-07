const assert=require('node:assert/strict');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
(async()=>{
 const browser=await chromium.launch({headless:true,channel:'msedge'});
 try{
  const page=await browser.newPage({viewport:{width:1440,height:1040}}),errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  for(const [file,title] of [['newsletter.html','Newsletter'],['newsletter-v355.html','v3.55 deep dive'],['newsletter-atlas-update.html','Guardian Altas update']]){
   await page.goto('http://127.0.0.1:8765/'+file);
   assert.equal(await page.locator('h1').innerText(),title);
   assert.equal(await page.locator('#site-sidebar nav h2').first().innerText(),'NEWSLETTER');
   const nav=await page.locator('#site-sidebar').innerText();
   assert(nav.includes('INGAME DATAS'));assert(!nav.includes('Game rules & code'));assert(!nav.includes('XP & progression'));assert(!nav.includes('Reports & evidence'));
   assert.equal(await page.locator('#site-sidebar a.current').innerText(),'Latest posts');
   for(const a of await page.locator('.article-toc a').all()){
    const href=await a.getAttribute('href');assert.equal(await page.locator(href).count(),1);
   }
   await page.locator('main img').evaluateAll(images=>Promise.all(images.map(i=>i.decode())));
   if(file==='newsletter.html'){
    assert.equal(await page.locator('.post-card').count(),2);
    await page.screenshot({path:'../guardian-analysis/updates/3.55.0/newsletter-desktop.png',fullPage:true});
   }
   if(file==='newsletter-v355.html')await page.screenshot({path:'../guardian-analysis/updates/3.55.0/newsletter-article.png'});
   await page.setViewportSize({width:390,height:844});
   assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false,file+' mobile overflow');
   await page.locator('#site-nav-toggle').click();await page.locator('#site-nav-close').click();
   if(file==='newsletter-v355.html')await page.screenshot({path:'../guardian-analysis/updates/3.55.0/newsletter-mobile.png'});
   await page.setViewportSize({width:1440,height:1040});
  }
  for(const file of ['REPORT_v355.md','REPORT_v355_explique.md','ANNEXE_LUA_v355.md','Reports-update-3.55.0.md','v355-evidence.json']){
   const res=await page.request.get('http://127.0.0.1:8765/downloads/newsletter/'+file);assert(res.ok(),file);
  }
  await page.goto('http://127.0.0.1:8765/characters.html?q=Astoria');
  await page.waitForFunction(()=>document.querySelector('#directory')?.textContent.includes('Astoria'));
  assert((await page.locator('#directory').innerText()).includes('Confirmed'));
  await page.goto('http://127.0.0.1:8765/visual.html?q=Astoria');
  await page.waitForFunction(()=>document.querySelectorAll('#grid .card').length>0);
  assert.deepEqual(errors,[]);
  console.log('PASS: newsletter navigation, both articles, contents anchors, desktop/mobile layout, source downloads and Astoria searches.');
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exit(1)});
