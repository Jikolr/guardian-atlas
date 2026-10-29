// Real-page checks for language switching, dynamic views, persistence, source fidelity and failures.
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),http=require('node:http'),zlib=require('node:zlib'),os=require('node:os');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const root=path.resolve('dist'),locales=['es','fr','ja','ko','zh-Hans','zh-Hant','id'];
const packs=Object.fromEntries(locales.map(locale=>[locale,JSON.parse(zlib.gunzipSync(fs.readFileSync(path.join(root,'data/i18n',locale+'.json.gz'))))]));
const posts=JSON.parse(fs.readFileSync(path.join(root,'data/newsletter.json'))),articleSlugs=posts.map(post=>post.slug);
const output=fs.mkdtempSync(path.join(os.tmpdir(),'guardian-i18n-'));
const server=http.createServer((req,res)=>{
  const target=path.resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname));
  if(!target.startsWith(root+path.sep)){res.writeHead(403).end();return;}
  try{const stat=fs.statSync(target);res.setHeader('Content-Type',({'.js':'text/javascript','.css':'text/css','.json':'application/json','.svg':'image/svg+xml','.png':'image/png','.webp':'image/webp','.html':'text/html'})[path.extname(target)]||'application/octet-stream');res.setHeader('Content-Length',stat.size);fs.createReadStream(target).pipe(res);}catch{res.writeHead(404).end();}
});
const language=async(page,locale)=>{await page.locator('#site-language-select').selectOption(locale);await page.waitForFunction(expected=>window.AtlasI18n?.locale===expected,locale);await page.waitForFunction(()=>!document.querySelector('#site-language-bar').hasAttribute('data-i18n-loading'));};
(async()=>{
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const base=process.env.ATLAS_TEST_BASE||'http://127.0.0.1:'+server.address().port;
  const browser=await chromium.launch({channel:process.env.PLAYWRIGHT_CHANNEL||'msedge',headless:true});
  try{
    const context=await browser.newContext({viewport:{width:1440,height:1000}}),page=await context.newPage(),errors=[],requests=[];
    page.on('pageerror',error=>errors.push(error.message));page.on('request',request=>requests.push(request.url()));
    await page.goto(base+'/home.html');await page.locator('#site-language-select').waitFor();
    assert.equal(await page.locator('#site-language-select option').count(),8);
    assert(!requests.some(url=>url.includes('/data/i18n/')),'English does not fetch translation packs');
    const englishNav=await page.locator('#site-sidebar').innerText();
    for(const locale of locales){
      await language(page,locale);
      assert.equal(await page.locator('html').getAttribute('lang'),locale);
      assert.equal(await page.locator('#site-sidebar a[href="hero-illustrations.html"]').innerText(),packs[locale].messages['Hero illustrations']);
      assert.equal(await page.locator('#site-language-select').getAttribute('aria-label'),packs[locale].messages['Website language']);
    }
    await language(page,'en');assert.equal(await page.locator('#site-sidebar').innerText(),englishNav,'English restores original text');
    for(const slug of articleSlugs){
      await page.goto(base+'/newsletter-'+slug+'.html');await page.locator('#site-language-select').waitFor();
      const original=await page.locator('.article-body').innerHTML(),refs=await page.locator('.article-body a,.article-body img').evaluateAll(nodes=>nodes.map(node=>node.getAttribute('href')||node.getAttribute('src'))),ids=await page.locator('.article-body h2').evaluateAll(nodes=>nodes.map(node=>node.id));
      for(const locale of locales){
        await language(page,locale);
        assert.equal(await page.locator('h1').innerText(),packs[locale].articles[slug].title);
        assert.equal(await page.locator('.article-body').getAttribute('lang'),locale);
        assert.deepEqual(await page.locator('.article-body h2').evaluateAll(nodes=>nodes.map(node=>node.id)),ids,'translated sections retain original deep links');
        assert.deepEqual(await page.locator('.article-body a,.article-body img').evaluateAll(nodes=>nodes.map(node=>node.getAttribute('href')||node.getAttribute('src'))),refs,'evidence links and illustrations remain unchanged');
        for(const link of await page.locator('.article-toc a').all())assert.equal(await page.locator(await link.getAttribute('href')).count(),1);
      }
      await language(page,'en');assert.equal(await page.locator('.article-body').innerHTML(),original);
    }
    await language(page,'fr');await page.reload();await page.waitForFunction(()=>AtlasI18n.locale==='fr');
    assert.equal(await page.locator('h1').innerText(),packs.fr.articles[articleSlugs.at(-1)].title,'choice survives reload');
    await page.goto(base+'/hero-illustrations.html');await page.locator('.illustration-card').first().waitFor();await page.waitForFunction(()=>AtlasI18n.locale==='fr');
    await page.locator('#illustration-search').fill('indaver_journalist');
    await page.waitForFunction(()=>document.querySelectorAll('.illustration-card').length===2);
    await page.waitForFunction(()=>!document.querySelector('#illustration-count').textContent.includes('in collection'));
    await page.locator('#illustration-variant').selectOption('Myth');assert.equal(await page.locator('.illustration-card').count(),1,'translated options retain their source values');
    await page.locator('.illustration-card-button').click();
    assert.equal(await page.locator('#detail-id').innerText(),'indaver_journalist_myth');
    await page.waitForFunction(expected=>document.querySelector('#detail-copy-link').textContent===expected,packs.fr.messages['Copy illustration link']);
    await page.locator('#detail-close').click();
    await page.goto(base+'/orbital-lift.html?floor=51');await page.locator('.record-room-buttons button').first().waitFor();await page.waitForFunction(()=>AtlasI18n.locale==='fr');
    const records=page.locator('.record-room-buttons button');assert(await records.count()>1);
    const secondRecord=await records.nth(1).getAttribute('data-record');await records.nth(1).click();
    assert.equal(await records.nth(1).getAttribute('aria-pressed'),'true','record selection uses stable values after translation');
    assert.equal(await page.locator('.record-room-buttons [aria-pressed="true"]').count(),1);
    const originalDialogue=JSON.parse(fs.readFileSync(path.join(root,'data/record-room-texts.json'))).entries.filter(entry=>entry.floor===51&&entry.record===secondRecord).sort((a,b)=>a.order-b.order).map(entry=>entry.text);
    assert.deepEqual(await page.locator('#room-dialogue p').allTextContents(),originalDialogue,'recovered dialogue remains exact');
    await page.goto(base+'/map-preview.html?map=short_story_invader2');await page.locator('#marker-results button').first().waitFor({timeout:60000});await page.waitForFunction(()=>AtlasI18n.locale==='fr');
    await page.waitForFunction(expected=>document.querySelector('#fit').textContent===expected,packs.fr.messages['Fit map']);
    await page.locator('#render-mode').selectOption('layout');assert.equal(await page.locator('#render-mode').inputValue(),'layout');await page.locator('#fit').click();
    const markers=await page.locator('#marker-results button').count();await page.locator('#marker-search').fill('minimap');
    await page.waitForFunction(previous=>document.querySelectorAll('#marker-results button').length<previous,markers);
    assert(await page.locator('#marker-results button').count()>0,'source identifier search works with translated controls');
    await page.goto(base+'/index.html');await page.locator('#datasets button').first().waitFor({state:'attached'});await page.locator('.site-tables summary').click();await page.locator('#table-body tr').first().waitFor();await page.waitForFunction(()=>AtlasI18n.locale==='fr');
    await page.locator('#dataset-search').fill(packs.fr.messages['Heroes']);await page.waitForFunction(()=>document.querySelectorAll('#datasets button').length>0);
    assert(await page.locator('#datasets button[data-kind="heroes"]').count(),'dataset search accepts the localized title');
    const rawTable=await page.locator('#table-body').innerHTML();await language(page,'ja');assert.equal(await page.locator('#table-body').innerHTML(),rawTable,'raw table values remain untouched');await language(page,'fr');
    await page.evaluate(()=>{const fragment=document.createElement('section');fragment.id='i18n-source-test';fragment.innerHTML='<pre>Character</pre><code>Language</code><span data-game-source>Language</span><span translate="no">Language</span><input value="Language" placeholder="Language"><button title="Language">Language</button><select><option>Heroes</option></select><span id="dynamic-message">Page 2 of 12</span>';document.querySelector('main').append(fragment);});
    await page.waitForFunction(expected=>document.querySelector('#i18n-source-test button').textContent===expected,packs.fr.messages.Language);
    assert.deepEqual(await page.locator('#i18n-source-test pre,#i18n-source-test code,#i18n-source-test [data-game-source],#i18n-source-test [translate="no"]').allTextContents(),['Character','Language','Language','Language']);
    assert.equal(await page.locator('#i18n-source-test input').inputValue(),'Language');
    assert.equal(await page.locator('#i18n-source-test input').getAttribute('placeholder'),packs.fr.messages.Language);
    assert.equal(await page.locator('#i18n-source-test select').inputValue(),'Heroes','implicit option values are preserved before translating labels');
    assert.equal(await page.locator('#i18n-source-test option').innerText(),packs.fr.messages.Heroes);
    assert.equal(await page.locator('#dynamic-message').innerText(),packs.fr.messages['Page {0} of {1}'].replace('{0}','2').replace('{1}','12'));
    await page.locator('#dynamic-message').evaluate(node=>{node.textContent='Page 4 of 15';});
    await page.waitForFunction(()=>!document.querySelector('#dynamic-message').textContent.startsWith('Page 4 of'));
    await language(page,'ja');await language(page,'en');assert.equal(await page.locator('#dynamic-message').innerText(),'Page 4 of 15','rerendered English source is retained');
    await page.locator('#i18n-source-test').evaluate(node=>node.remove());
    await page.goto(base+'/newsletter-'+articleSlugs[0]+'.html?lang=zh-Hant');await page.waitForFunction(()=>AtlasI18n.locale==='zh-Hant');
    await language(page,'fr');assert.equal(new URL(page.url()).searchParams.get('lang'),'fr','explicit language URL tracks choice');
    await page.screenshot({path:path.join(output,'newsletter-fr-desktop.png')});
    for(const locale of locales){
      await language(page,locale);await page.setViewportSize({width:390,height:844});
      assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),locale+' article fits mobile');
      const select=await page.locator('#site-language-select').boundingBox(),toggle=await page.locator('#site-nav-toggle').boundingBox();assert(select.x>toggle.x+toggle.width,'mobile menu and language control do not overlap');
      await page.locator('#site-nav-toggle').click();await page.locator('#site-nav-close').click();
    }
    await page.screenshot({path:path.join(output,'newsletter-id-mobile.png')});
    // A corrected English source must never be covered by an outdated translation.
    await language(page,'en');await page.locator('.article-body').evaluate(node=>{node.dataset.sourceHash='new-revision';});await language(page,'ko');
    assert.equal(await page.locator('.article-body').getAttribute('lang'),'en');assert(await page.locator('.article-language-notice').isVisible());
    assert.deepEqual(errors,[]);
    await context.close();
    const deepLink=await browser.newPage();await deepLink.goto(base+'/character.html?id=707&lang=fr');await deepLink.waitForFunction(()=>window.AtlasI18n?.locale==='fr');
    assert(!(await deepLink.locator('.profile-heading').innerText()).includes('Internal name only'),'identity prefix translates while source ID is preserved');
    await deepLink.goto(base+'/hero-illustrations.html?lang=zh-Hant');await deepLink.waitForFunction(()=>window.AtlasI18n?.locale==='zh-Hant');await deepLink.locator('.illustration-card').first().waitFor();
    assert((await deepLink.locator('#collection-packs').innerText()).includes(packs['zh-Hant'].messages['All character PNGs']));
    await deepLink.locator('.illustration-card-button').first().click();
    assert((await deepLink.locator('.preview-backgrounds').innerText()).includes(packs['zh-Hant'].messages['Light background']));await deepLink.close();
    const failure=await browser.newPage();await failure.route('**/data/i18n/fr.json.gz*',route=>route.fulfill({status:503}));
    await failure.goto(base+'/home.html');await failure.locator('#site-language-select').selectOption('fr');
    await failure.waitForFunction(()=>document.querySelector('#site-language-status').textContent.includes('could not'));
    assert.equal(await failure.evaluate(()=>AtlasI18n.locale),'en');assert.equal(await failure.locator('#site-language-select').inputValue(),'en');
    await failure.unroute('**/data/i18n/fr.json.gz*');await language(failure,'fr');await failure.close();
    const race=await browser.newPage();let release;
    await race.route('**/data/i18n/fr.json.gz*',async route=>{await new Promise(resolve=>{release=resolve});await route.fulfill({body:fs.readFileSync(path.join(root,'data/i18n/fr.json.gz'))});});
    await race.goto(base+'/home.html');await race.locator('#site-language-select').selectOption('fr');
    while(!release)await new Promise(resolve=>setTimeout(resolve,10));
    await language(race,'ja');release();await race.waitForLoadState('networkidle');
    assert.equal(await race.evaluate(()=>AtlasI18n.locale),'ja','slow previous request cannot undo newer choice');await race.close();
    console.log('PASS: 7 languages, '+articleSlugs.length*locales.length+' translated articles, dynamic controls, source fidelity, persistence, mobile layout, failures and stale/racing requests. Screenshots: '+output);
  }finally{await browser.close();server.close();}
})().catch(error=>{console.error(error);server.close();process.exitCode=1;});
