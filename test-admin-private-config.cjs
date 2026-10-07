
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
(async()=>{const b=await chromium.launch({channel:'msedge',headless:true});try{const p=await b.newPage();let errors=[];p.on('pageerror',e=>errors.push(e.message));
await p.route('https://jikolr.github.io/guardian-atlas/admin/**',async route=>{const file=new URL(route.request().url()).pathname.split('/').pop()||'index.html';
if(file==='decap-cms.js'){await route.fulfill({contentType:'text/javascript',body:'window.CMS={init:c=>window.lastConfig=c,registerPreviewStyle:()=>{},registerPreviewTemplate:()=>{}};window.createClass=x=>x;'});return}
await route.fulfill({path:path.resolve('dist/admin',file),contentType:file.endsWith('.js')?'text/javascript':file.endsWith('.json')?'application/json':'text/html'});});
await p.goto('https://jikolr.github.io/guardian-atlas/admin/');const input=p.locator('input[type=url]');await input.waitFor();assert.equal(await input.inputValue(),'');
await input.fill('http://insecure.example');await p.locator('#start').click();assert((await p.locator('#status').innerText()).includes('valid HTTPS'));
await input.fill('https://auth.example');await p.locator('#start').click();assert.equal(await p.evaluate(()=>lastConfig.config.backend.base_url),'https://auth.example');await p.reload();await input.waitFor();assert.equal(await input.inputValue(),'https://auth.example');assert.deepEqual(errors,[]);console.log('PASS: private auth URL validation, CMS configuration and browser persistence.');
}finally{await b.close()}})().catch(e=>{console.error(e);process.exitCode=1});

