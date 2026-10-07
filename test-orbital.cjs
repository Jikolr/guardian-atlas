const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
(async()=>{
 const root=path.join(__dirname,'dist/data');
 const db=JSON.parse(fs.readFileSync(path.join(root,'orbital-lift.json')));
 const source=JSON.parse(fs.readFileSync(path.join(root,'static-infinitytowerfloors.json')));
 assert.deepEqual(db.floors,source.map(r=>r.fields));
 for(const f of db.floors)for(const m of f.Monsters){const e=db.enemies[m.MonsterId];assert.ok(e?.spec?.Id);if(e.image)assert.ok(fs.existsSync(path.join(root,'visual',e.image)),e.image);}
 const browser=await chromium.launch({headless:true,channel:"msedge"});
 try{
 const page=await browser.newPage({viewport:{width:1440,height:1000}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto('http://127.0.0.1:8765/orbital-lift.html?floor=1323');
 await page.waitForSelector('#formation .position-cell');
 const report=await page.evaluate(floors=>{
  const select=document.querySelector('#floor-list');let total=0;
  for(const floor of floors){
   select.value=floor.Floor;select.dispatchEvent(new Event('change'));
   const tiles=[...document.querySelectorAll('#formation button[data-enemy]')];
   if(tiles.length!==floor.Monsters.length)throw Error('Missing enemy on '+floor.Floor);
   for(let i=0;i<floor.Monsters.length;i++){
    const tile=tiles.find(t=>Number(t.dataset.enemy)===i);
    if(!tile||tile.parentElement.parentElement.querySelector('.slot-label').textContent!=='P'+floor.Monsters[i].Position)throw Error('Wrong position '+floor.Floor);
   }total+=tiles.length;
  }return {floors:floors.length,enemies:total};
 },db.floors);
 for(const width of [1440,390]){
  await page.setViewportSize({width,height:1000});
  for(const floor of [1323,1325]){
   await page.selectOption('#floor-list',String(floor));
   const boxes=await page.locator('.position-cell').evaluateAll(els=>els.map(e=>{const r=e.getBoundingClientRect();return {w:r.width,h:r.height};}));
   assert.ok(boxes.every(b=>Math.abs(b.w-b.h)<1&&Math.abs(b.w-boxes[0].w)<1));
   assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
  }
 }
 assert.deepEqual(errors,[]);
 console.log(JSON.stringify({...report,viewports:[1440,390],equalSquareCells:true,noPageErrors:true}));
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});

