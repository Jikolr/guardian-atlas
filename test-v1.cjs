
const {chromium}=require('C:/Users/alexandre.corbineau/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs'),http=require('node:http'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve('dist');
const server=http.createServer((req,res)=>{const p=path.join(root,decodeURIComponent(new URL(req.url,'http://localhost').pathname).replace(/\/$/,'/index.html'));try{const stat=fs.statSync(p);res.setHeader('Content-Type',({'.js':'text/javascript','.css':'text/css','.json':'application/json','.svg':'image/svg+xml','.png':'image/png','.webp':'image/webp','.html':'text/html'})[path.extname(p)]||'application/octet-stream');res.setHeader('Content-Length',stat.size);fs.createReadStream(p).pipe(res)}catch{res.statusCode=404;res.end()}});
(async()=>{await new Promise(r=>server.listen(0,'127.0.0.1',r));const browser=await chromium.launch({channel:'msedge',headless:true});try{
const page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));const base='http://127.0.0.1:'+server.address().port;
await page.goto(base+'/');await page.waitForURL('**/home.html');assert.equal(await page.locator('h1').innerText(),'Find your way through Guardian Tales.');
for(const width of [1440,390]){await page.setViewportSize({width,height:900});for(const file of ['home.html','contacts.html','mastery-planner.html','characters.html','orbital-lift.html?floor=1325','files.html','help.html']){
await page.goto(base+'/'+file);await page.locator('#report-issue').waitFor();await page.waitForTimeout(350);
assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'Overflow '+file+' '+width);
if(width===390){await page.locator('#site-nav-toggle').click();assert.equal(await page.locator('#site-nav-toggle').getAttribute('aria-expanded'),'true');await page.keyboard.press('Escape');}
}
}
await page.goto(base+'/characters.html?q=demon%20slayer');
await page.locator('#directory .card').first().waitFor();assert((await page.locator('#directory').innerText()).includes('Andras'));
await page.locator('#site-nav-toggle').click();await page.locator('#report-issue').click();await page.locator('#issue-description').fill('The portrait seems wrong.');
const text=await page.locator('#issue-context').inputValue();assert(text.includes('https://jikolr.github.io/guardian-atlas/characters.html?q=demon+slayer'));assert(text.includes('The portrait seems wrong.'));assert(text.includes('demon slayer'));
assert((await page.locator('#issue-email').getAttribute('href')).startsWith('mailto:nihalguardiantales@gmail.com'));
await page.screenshot({path:'C:/Codex/guardian-analysis/v1-report-mobile.png',fullPage:true});
await page.keyboard.press('Escape');assert(!(await page.locator('#issue-dialog').isVisible()));
await page.goto(base+'/index.html?table=heroes');assert(page.url().includes('index.html?table=heroes'));
await page.goto(base+'/home.html');await page.setViewportSize({width:1440,height:1000});await page.screenshot({path:'C:/Codex/guardian-analysis/v1-home.png',fullPage:true});
assert.deepEqual(errors,[]);console.log('PASS: home routing, deep links, name search, issue context, desktop/mobile layouts and navigation.');
}finally{await browser.close();server.close()}})().catch(e=>{console.error(e);server.close();process.exitCode=1});


