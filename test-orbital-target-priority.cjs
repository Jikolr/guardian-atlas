const fs=require('node:fs');
const assert=require('node:assert/strict');
const source=fs.readFileSync('dist/orbital-lift.js','utf8');
const body=source.slice(source.indexOf(' function targetPriorityMarkup'),source.indexOf(' function weaponSkillEffectMarkup'));
const render=new Function('link',body+';return targetPriorityMarkup;')((table,id)=>`${table}/${id}`);
const db=JSON.parse(fs.readFileSync('dist/data/orbital-lift.json','utf8'));
const turrets=['it_magicschool_turret_laser','it_cw_passage_saul_turret'];
const expected=['it_lw_passage_fighter','it_dungeon_imp_fighter','it_demon_turing_male_assassin','it_cw_passage_saul_charge_target','it_lw_passage_waller',...turrets];
for(const enemy of Object.values(db.enemies)){
 const html=render(enemy.spec);
 assert.equal(Boolean(html),expected.includes(enemy.spec.Name),enemy.spec.Name);
 if(html){
  assert(html.includes('enemy-target-priority'));
  if(turrets.includes(enemy.spec.Name)){
   assert(html.includes('Target priority · Leader'));
   assert(html.includes('laser attack'));
   assert(html.includes('static-battleactions/1308'));
   assert(html.includes('TargetSearchType: Manual'));
  }else if(enemy.spec.Name==='it_lw_passage_waller'){
   assert(html.includes('Target priority · Leader'));
   assert(html.includes('method=31699'));
   assert(html.includes('static-battleais/35'));
   assert(html.includes('IsManual'));
   assert(!html.includes('gameplay interpretation'));
  }else if(enemy.spec.Name==='it_cw_passage_saul_charge_target'){
   assert(html.includes('Target priority · Leader'));
   assert(html.includes('method=31639'));
   assert(html.includes('has not been independently verified'));
  }else if(enemy.spec.Name==='it_demon_turing_male_assassin'){
   assert(html.includes('Ranged → Supporter → Melee → Tanker'));
   assert(html.includes('Teleport attack · AssassinStab'));
   assert(html.includes('method=29918'));
   assert(html.includes('method=13485'));
  }else{
   assert(html.includes('falls back to general target selection'));
   assert(html.includes('method=31701'));
  }
 }
}
assert.equal(render({Name:'unknown'}),'');
console.log('Target priority: exactly seven approved enemies are annotated; all other enemies unchanged.');
