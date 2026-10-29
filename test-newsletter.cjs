const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path'),os=require('node:os');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const output=fs.mkdtempSync(path.join(os.tmpdir(),'guardian-newsletter-'));
const base=process.env.ATLAS_TEST_BASE||'http://127.0.0.1:8765';
const published=JSON.parse(fs.readFileSync(path.join(__dirname,'dist/data/newsletter.json')));
(async()=>{
 const browser=await chromium.launch({headless:true,channel:'msedge'});
 try{
  const page=await browser.newPage({viewport:{width:1440,height:1040}}),errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  for(const [file,title] of [['newsletter.html','Newsletter'],...published.map(post=>['newsletter-'+post.slug+'.html',post.title])]){
   await page.goto(base+'/'+file);
   assert.equal(await page.locator('h1').innerText(),title);
   assert((await page.locator('#site-sidebar nav h2').allInnerTexts()).includes('NEWSLETTER'));
   const nav=await page.locator('#site-sidebar').innerText();
   assert(nav.includes('INGAME DATAS'));assert(!nav.includes('Game rules & code'));assert(!nav.includes('XP & progression'));assert(!nav.includes('Reports & evidence'));
   assert.equal(await page.locator('#site-sidebar a.current').innerText(),'Latest posts');
   for(const a of await page.locator('.article-toc a').all()){
    const href=await a.getAttribute('href');assert.equal(await page.locator(href).count(),1);
   }
   await page.locator('main img').evaluateAll(images=>Promise.all(images.map(i=>i.decode())));
   if(file==='newsletter.html'){
    assert.equal(await page.locator('.post-card').count(),published.length);
    assert.equal(await page.locator('.post-card').first().getAttribute('href'),'newsletter-'+published[0].slug+'.html');
    await page.screenshot({path:path.join(output,'newsletter-desktop.png'),fullPage:true});
   }
   if(file==='newsletter-v357.html'){
    assert((await page.locator('.article-body').innerText()).includes('indaver_journalist'));
    assert((await page.locator('.article-body').innerText()).includes('Visible: false'));
    assert((await page.locator('.article-body img').count())>=8);
    for(const href of await page.locator('.article-body a').evaluateAll(links=>links.map(a=>a.getAttribute('href')))){
     if(!href||href.startsWith('https:')||href.startsWith('#'))continue;
     const response=await page.request.get(new URL(href,page.url()).href);assert(response.ok(),href);
    }
    await page.screenshot({path:path.join(output,'newsletter-v357-desktop.png')});
   }
   if(file==='newsletter-v355.html')await page.screenshot({path:path.join(output,'newsletter-v355-desktop.png')});
   await page.setViewportSize({width:390,height:844});
   assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false,file+' mobile overflow');
   await page.locator('#site-nav-toggle').click();await page.locator('#site-nav-close').click();
   if(file==='newsletter-v357.html')await page.screenshot({path:path.join(output,'newsletter-v357-mobile.png'),animations:'disabled'});
   await page.setViewportSize({width:1440,height:1040});
  }
  for(const file of ['REPORT_v355.md','REPORT_v355_explique.md','ANNEXE_LUA_v355.md','Reports-update-3.55.0.md','v355-evidence.json','v357-evidence.json']){
   const res=await page.request.get(base+'/downloads/newsletter/'+file);assert(res.ok(),file);
  }
  await page.goto(base+'/characters.html?q=Astoria');
  await page.waitForFunction(()=>document.querySelector('#directory')?.textContent.includes('Astoria'));
  assert((await page.locator('#directory').innerText()).includes('Confirmed'));
  await page.goto(base+'/visual.html?q=Astoria');
  await page.waitForFunction(()=>document.querySelectorAll('#grid .card').length>0);
  assert.deepEqual(errors,[]);
  console.log('PASS: newsletter navigation, current published articles, illustrations/links, contents anchors, desktop/mobile layout, source downloads and Astoria searches. Screenshots: '+output);
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exit(1)});
