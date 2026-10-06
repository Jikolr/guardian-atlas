const assert=require('node:assert/strict');
const {chromium}=require('C:/Users/alexandre.corbineau/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
(async()=>{const browser=await chromium.launch({headless:true,channel:'msedge'});try{
const page=await browser.newPage({viewport:{width:1440,height:1050}});const errors=[];page.on('pageerror',e=>errors.push(e.message));
await page.goto('http://127.0.0.1:8766/contacts.html');
assert.equal(await page.locator('h1').innerText(),'Contacts');
assert.equal(await page.locator('a[href="mailto:nihalguardiantales@gmail.com"]').count(),1);
assert.equal(await page.locator('#discord-handle').innerText(),'newhorizons');
await page.locator('.profile-art img').evaluate(i=>i.decode());
assert.equal(await page.locator('#site-sidebar a.current').innerText(),'Contacts');
await page.screenshot({path:'C:/Codex/guardian-analysis/contacts-preview.png',fullPage:true});
await page.goto('http://127.0.0.1:8766/raid-videos.html');
assert.equal(await page.locator('.video-card').count(),15);
assert.equal(await page.locator('iframe').count(),0);
await page.locator('#video-search').fill('Garam');assert((await page.locator('.video-card:visible').count())>0);
await page.locator('.play-video:visible').first().click();
assert((await page.locator('iframe').getAttribute('src')).startsWith('https://www.youtube-nocookie.com/embed/'));
await page.locator('#video-search').fill('no-match-xyz');assert.equal(await page.locator('iframe').count(),0);assert(await page.locator('#video-empty').isVisible());
await page.locator('#video-search').fill('');await page.locator('#video-source').selectOption('curated');assert.equal(await page.locator('.video-card:visible').count(),0);
await page.locator('#video-source').selectOption('all');
await page.screenshot({path:'C:/Codex/guardian-analysis/videos-preview.png',fullPage:true});
for(const name of ['contacts.html','raid-videos.html','logo-concepts.html']){
await page.setViewportSize({width:390,height:844});await page.goto('http://127.0.0.1:8766/'+name);
assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false,name+' mobile overflow');
}
await page.setViewportSize({width:1440,height:1000});await page.goto('http://127.0.0.1:8766/logo-concepts.html');
assert.equal(await page.locator('a[download]').count(),3);
await page.screenshot({path:'C:/Codex/guardian-analysis/logo-concepts-preview.png',fullPage:true});
assert.deepEqual(errors,[]);console.log('PASS: contacts, profile image, navigation, 15 videos, filtering, click-to-play, mobile layout, logo concepts');
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exit(1)});
