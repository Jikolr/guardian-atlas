// Exercise newly imported content in the real UI. Uses an existing local server.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const work=process.argv[2];assert(work,'Pass the snapshot output directory');
const output=path.join(work,'validation');fs.mkdirSync(output,{recursive:true});
const origin=process.env.ATLAS_TEST_ORIGIN||'http://127.0.0.1:8766';
(async()=>{
 const browser=await chromium.launch({channel:'msedge',headless:true});
 const errors=[],failed=[];const checks=[];
 try{
  const page=await browser.newPage({viewport:{width:1440,height:1000}});
  page.on('pageerror',e=>errors.push(e.message));
  page.on('response',r=>{if(r.url().startsWith(origin)&&r.status()>=400)failed.push({url:r.url(),status:r.status()});});
  await page.goto(origin+'/index.html?table=heroes&q=indaver_journalist&scope=name');
  await page.locator('#table-body tr').first().waitFor();
  assert((await page.locator('#table-body').innerText()).includes('indaver_journalist'));
  assert.equal(await page.locator('#table-body tr').count(),4);checks.push('new hero variants searchable');
  await page.goto(origin+'/character.html?id=707');
  await page.locator('#profile h1').waitFor();
  assert((await page.locator('#profile').innerText()).includes('indaver_journalist'));
  const image=page.locator('#profile img').first();await image.waitFor();
  assert(await image.evaluate(e=>e.complete&&e.naturalWidth>0));
  await page.screenshot({path:path.join(output,'new-character.png'),fullPage:true});checks.push('new character profile and portrait');
  const db=JSON.parse(fs.readFileSync('dist/data/orbital-lift.json'));
  const actions=JSON.parse(fs.readFileSync('dist/data/static-battleactions.json'));
  for(const [enemy,action] of [['it_magicschool_turret_laser','LaserNew:turretdarkness'],['it_demon_turing_male_assassin','AssassinStab'],['it_debuff_poi','WholeTargeting:poi']]){
   const floor=db.floors.find(f=>f.Monsters.some(m=>db.enemies[m.MonsterId].spec.Name===enemy));assert(floor,enemy);
   const position=floor.Monsters.findIndex(m=>db.enemies[m.MonsterId].spec.Name===enemy);
   await page.goto(origin+'/orbital-lift.html?floor='+floor.Floor);
   const source=page.locator('#enemy-'+position+' a[href*="static-battleactions"]').first();await source.waitFor({state:'attached'});
   const id=new URL(await source.getAttribute('href'),origin).searchParams.get('record');
   assert.equal(actions.find(r=>String(r.id)===id)?.fields.Name,action,enemy);
  }
  checks.push('Orbital evidence links resolve current action names');
  await page.goto(origin+'/research.html#scripts');
  await page.locator('#collection-search').fill('InvaderReporter2');
  await page.waitForFunction(()=>document.querySelector('#collection-status')?.textContent.startsWith('21 of'));
  await page.locator('#collection-list button').first().click();
  await page.locator('#collection-detail .source-line').first().waitFor();checks.push('new Lua sources load');
  for(const name of ['short_story_invader2','invader_reporter','prologue1']){
   await page.goto(origin+'/map-preview.html?map='+name);
   await page.waitForFunction(name=>document.querySelector('h1')?.textContent===name,name);
   await page.locator('#marker-results button').first().waitFor({timeout:60000});
   assert((await page.locator('#layers').innerText()).length>0);
   checks.push('map '+name+' loads with placements');
   if(name==='short_story_invader2')await page.screenshot({path:path.join(output,'new-map.png'),fullPage:true});
  }
  await page.goto(origin+'/research.html#maps');
  await page.locator('#collection-search').fill('short_story_invader2');
  await page.waitForFunction(()=>document.querySelectorAll('#collection-list button').length===1);
  await page.locator('#collection-list button').click();
  await page.locator('#collection-detail .source-line').first().waitFor();checks.push('gzip research map detail');
  await page.setViewportSize({width:390,height:844});
  await page.goto(origin+'/characters.html?q=indaver_journalist');
  await page.locator('#directory .card').first().waitFor();
  assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1));checks.push('mobile character directory');
  assert.deepEqual(errors,[]);assert.deepEqual(failed,[]);
  const report={status:'passed',checks,pageErrors:errors,failedRequests:failed};
  fs.writeFileSync(path.join(output,'browser-update.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report));
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1});
