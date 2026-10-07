
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const assert=require('node:assert/strict');
(async()=>{const b=await chromium.launch({channel:'msedge',headless:true});try{const p=await b.newPage();let errors=[];p.on('pageerror',e=>errors.push(e.message));
await p.goto('http://127.0.0.1:8766/visual.html?tab=assets&q=Beth');await p.locator('#grid .card').first().waitFor();assert((await p.locator('#grid').innerText()).includes('invader_knight'));console.log('Beth graphics:',await p.locator('#summary').innerText());
await p.goto('http://127.0.0.1:8766/characters.html?q=Beth');await p.locator('#directory .card').first().waitFor();assert((await p.locator('#directory').innerText()).includes('Confirmed name'));
await p.goto('http://127.0.0.1:8766/visual.html?tab=monsters&q=Elphaba');await p.locator('#grid .card').first().waitFor();assert((await p.locator('#grid').innerText()).includes('Elphaba'));
await p.goto('http://127.0.0.1:8766/index.html?table=heroes&q=Beth&scope=name');await p.locator('#table-body tr').first().waitFor();assert((await p.locator('#table-body').innerText()).includes('Beth'));
assert.deepEqual(errors,[]);console.log('PASS: Beth gallery/directory/tables, Elphaba monsters, no browser errors.');}finally{await b.close()}})().catch(e=>{console.error(e);process.exitCode=1});

