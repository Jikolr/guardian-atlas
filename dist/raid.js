'use strict';
(async()=>{
const $=s=>document.querySelector(s),esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const fmt=n=>Number(n).toLocaleString('en-US',{maximumFractionDigits:0}),prec=n=>Number(n).toLocaleString('en-US',{maximumFractionDigits:4});
const KEY='guardian-atlas-raid-v1',PROFILES='guardian-atlas-raid-profiles-v1';
const notice=(s,error=false)=>{$('#status').textContent=s;$('#status').classList.toggle('error',error);};
try{
const response=await fetch('data/raid-simulator.json');if(!response.ok)throw Error('Game catalogue could not load.');
const E=RaidEngine.create(await response.json());
const known={596:'Dabin',533:'Ameris',425:'Kamael',542:'Eunha',677:'Noel'};
for(const h of E.db.heroes)if(known[h.OriginId])h.displayName=known[h.OriginId];
let state=E.defaultState(),lastResult,storageAvailable=true,profiles={};
try{const saved=localStorage.getItem(KEY);if(saved)state=E.validate(JSON.parse(saved));profiles=JSON.parse(localStorage.getItem(PROFILES)||'{}');}catch(e){notice('Saved data could not be loaded; using a fresh setup. '+e.message,true);}
const origins=[...new Set(E.db.heroes.map(h=>h.OriginId))].map(id=>E.db.heroes.filter(h=>h.OriginId===id).sort((a,b)=>b.Rank-a.Rank)[0]).sort((a,b)=>a.displayName.localeCompare(b.displayName));
const field=(label,path,value,min=0,max=1000,step=.1)=>`<label>${esc(label)}<input type="number" data-path="${esc(path)}" value="${value}" min="${min}" max="${max}" step="${step}"></label>`;
const select=(label,path,value,choices)=>path.endsWith('.hero')?visualInput(label,'data-path',path,choices.find(x=>String(x[0])===String(value))?.[1]||'',choices.map(([v,t])=>({value:String(v),label:t,image:imagePath(E.heroes[v]?.image)}))):`<label>${esc(label)}<select data-path="${esc(path)}">${choices.map(([v,t])=>`<option value="${esc(v)}" ${String(value)===String(v)?'selected':''}>${esc(t)}</option>`).join('')}</select></label>`;
const itemLabel=i=>`${known[i.ExclusiveCharacterId]?known[i.ExclusiveCharacterId]+' EX · ':''}${i.Name} · #${i.Id}`;
const heroLabel=h=>`${h.displayName} · ${h.Class.replace(/_myth$/,'')} · #${h.OriginId}`;
const imagePath=p=>p?(p.startsWith('data/')?p:'data/visual/'+p):'';
function visualInput(label,attribute,path,value,rows){
 const key=attribute+'-'+path;ImagePicker.register(key,rows);
 return `<label>${esc(label)}<input type="search" ${attribute}="${esc(path)}" data-image-picker="${esc(key)}" data-committed="${esc(value)}" value="${esc(value)}" role="combobox" aria-autocomplete="list" aria-expanded="false" aria-controls="image-picker-menu" placeholder="Search name or ID…" autocomplete="off"></label>`;
}
function optionText(ref,merchLevel){
 const o=E.options[ref.OptionId];if(!o)return 'Unknown option #'+ref.OptionId;
 const level=merchLevel&&/^merch_(attack|hp|defense)_/.test(o.Name)?merchLevel-1:(ref.Level??ref.MaxLevel??0);
 const fields={TotalAttackScale:['ATK','AttackScale',100],SuperSkillScale:['Skill damage','AttackScale',100],CriticalChanceUp:['Critical chance','CriticalUp',1],CriticalMultiplierScaleUp:['Critical damage','CriticalUp',100],HpScale:['HP','HpScale',100],DefenseScale:['DEF','DefenseScale',100],RecoveryScale:['Heal','RecoveryScale',100],ElementalScale:[(o.Elemental||'Elemental')+' ATK','ElementalScale',100],ManaRegenScale:['Weapon skill regeneration','ManaRegenScale',100],Exorcism:['Mystic resistance','Exorcism',1]};
 const f=fields[o.Class];if(f)return f[0]+' +'+prec(((o[f[1]+'Base']||0)+(o[f[1]+'Add']||0)*level)*f[2])+(o.Class==='Exorcism'?'':'%');
 if(o.Class==='TargetConditionDamageBoost'){const k='BossModifierAdd' in o?'Boss':'Pvp';return (k==='Boss'?'Boss':'PvP')+' damage +'+prec(((o[k+'ModifierBase']||0)+(o[k+'ModifierAdd']||0)*level)*100)+'%';}
 if(o.Class==='TargetConditionProtection')return 'PvE damage reduction +'+prec(((o.PveModifierBase||0)+(o.PveModifierAdd||0)*level)*100)+'%';
 if(o.Class==='IntervalTrigger')return o.DamageType+' extra hit: '+prec(o.DamageRate*level*100)+'% every '+o.Interval+'s (proc not simulated)';
 if(o.Class==='GeneralIntervalInBattle'&&o.HpRecoveryAdd)return 'Recover '+prec(o.HpRecoveryAdd*level*100)+'% HP every '+o.Interval+'s';
 if(o.Class==='BuffOnKill')return 'On kill: ATK bonus (conditional; see source)';
 if(o.Class==='Buff'){const b=E.db.buffs.find(b=>b.Id===o.BuffId),f={TotalAttackScale:['ATK','AttackScale',100],HpScale:['HP','HpScale',100],DefenseScale:['DEF','DefenseScale',100],Critical:['Critical chance','Critical',1],ProjectileAttackScale:['Ranged damage','AttackScale',100],MeleeAttackScale:['Melee damage','AttackScale',100],SuperSkillScale:['Skill damage','AttackScale',100]}[b?.ClassName];if(f)return (o.IsForRelicSet?'Four-relic set: ':'Party: ')+f[0]+' +'+prec(((b[f[1]+'Base']||0)+(b[f[1]+'Add']||0)*level)*f[2])+'%';}
 const params=(o.DescParam||[]).map((p,j)=>{const keys=p.split('&'),type=o.DescParamType?.[j]||'';if(!keys.every(k=>typeof o[k]==='number'))return null;let v=keys.length===2?o[keys[0]]+o[keys[1]]*level:o[keys[0]]*(type.includes(':level')?level:1);if(type.toLowerCase().includes('percent'))v*=100;return p.replace(/Base.*|Add$/g,'').replace(/([a-z])([A-Z])/g,'$1 $2')+': '+prec(v)+(type.toLowerCase().includes('percent')?'%':'');}).filter(Boolean);
 return o.Name.replaceAll('_',' ')+(params.length?' · '+params.join(' · '):' · option level '+level)+' (see source for conditions)';
}
const damageCard=i=>i.Type==='orb'&&[...(i.Options||[]),...(i.StaticOptions||[])].some(r=>['TotalAttackScale','SuperSkillScale','CriticalChanceUp','BuffOnKill','ElementalScale'].includes(E.options[r.OptionId]?.Class));
function picker(label,path,value,rows){
 const id='list-'+path.replaceAll('.','-'),item=E.items[value],slot=state.team[Number(path.split('.')[1])],isWeapon=path.endsWith('.weapon');
 const bonuses=item&&!isWeapon?[...(item.Options||[]),...(item.StaticOptions||[])].map(r=>optionText(r,item.Type==='merch'?slot.merchLevel:0)):[];
 return `<div class="equipment-choice">${visualInput(label,'data-picker',path,value?itemLabel(item):'None',[{value:'None',label:'None'},...rows.map(i=>({value:itemLabel(i),label:itemLabel(i),image:imagePath(i.image),detail:!isWeapon?[...(i.Options||[]),...(i.StaticOptions||[])].map(r=>optionText(r,i.Type==='merch'?slot.merchLevel:0)).join(' · '):''}))])}${item?`<div class="selected-equipment">${item.image?`<img src="${esc(imagePath(item.image))}" alt="${esc(item.Name)}">`:'<span>Preview unavailable</span>'}<div><a href="index.html?table=static-items&q=${item.Id}">${esc(item.Name.replaceAll('_',' '))}</a>${!isWeapon?`<ul>${bonuses.map(b=>`<li>${esc(b)}</li>`).join('')||`<li>${item.Type==='relic'?'Choose substats below.':'No fixed bonus in this record.'}</li>`}</ul>`:''}</div></div>`:''}</div>`;
}
function get(path){return path.split('.').reduce((v,k)=>v[k],state);}
function set(path,value){const keys=path.split('.');const last=keys.pop();keys.reduce((v,k)=>v[k],state)[last]=value;}
function save(){try{localStorage.setItem(KEY,JSON.stringify(state));}catch{storageAvailable=false;notice('Local saving is unavailable. Use Download complete setup to keep your changes.',true);}}
function download(name,data){const a=document.createElement('a'),url=URL.createObjectURL(new Blob([JSON.stringify(data,null,2)],{type:'application/json'}));a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);}
function profileUI(){
 $('#profile-name').value=state.profile.name;
 const labels={heroCollection:'Hero collection ATK (%)',itemCollection:'Item collection ATK (%)',equipCostume:'Equipment costume ATK (%)',illustration:'Illustration costume ATK (%)',jewelBook:'Jewel knowledge ATK (%)',tower:'Strength Tower ATK (%)',guardian:'Guardian ATK (%)',extraAtk:'Other account ATK (%)'};
 $('#account-fields').innerHTML=Object.entries(labels).map(([k,l])=>field(l,'profile.'+k,state.profile[k])).join('');
 $('#weapon-books').innerHTML=Object.keys(state.profile.weaponBooks).map(k=>field(k,'profile.weaponBooks.'+k,state.profile.weaponBooks[k],0,100)).join('');
 $('#mastery-fields').innerHTML=Object.keys(state.profile.mastery).map(k=>field(k.replace('Atk',' ATK').replace('Skill',' skill damage')+' level','profile.mastery.'+k,state.profile.mastery[k],0,E.db.mastery.at(-1).SkillLevel,1)).join('');
 $('#profile-list').innerHTML='<option value="">Choose a profile…</option>'+Object.keys(profiles).map(k=>`<option value="${esc(k)}" translate="no">${esc(k)}</option>`).join('');
}
function relicUI(s,index){const r=E.items[s.relic];if(!r)return '<p class="muted">Select a relic to choose its stage-specific rolls. The selected item includes its evolution stage.</p>';
 const pools=[...(r.BaseOptions||[]),...(r.ChangeOptions||[])];
 return `<p class="fine">${esc((r.SetOption||[]).map(optionText).join(' · '))}</p><p class="fine">Choose each roll and its option level. The effect preview converts the option level into a percentage. Empty slots grant no bonus. Stage and roll ranges come from the selected relic record.</p><div class="relic-rolls">`+pools.map((pool,j)=>{
  if(!pool.length)return '';
  const v=s.relicOptions[j]||{OptionId:0,Level:0},o=E.options[v.OptionId],spec=pool.find(x=>x.OptionId===v.OptionId);
  let effect=o?optionText(v):'';
  return `<div class="relic-roll">${select((j<3?'Substat '+(j+1):j===3?'Special effect':'Stage / resistance bonus'),`team.${index}.relicOptions.${j}.OptionId`,v.OptionId,[[0,'No roll'],...pool.map(x=>[x.OptionId,optionText({OptionId:x.OptionId,Level:x.MaxLevel})+' max'])])}${field('Roll level'+(spec?` (${spec.MinLevel}–${spec.MaxLevel})`:''),`team.${index}.relicOptions.${j}.Level`,v.Level,spec?.MinLevel||0,spec?.MaxLevel||1000,1)}<span class="fine">${esc(effect)}</span></div>`;
 }).join('')+'</div>';
}
function teamUI(){
 $('#team-slots').innerHTML=state.team.map((s,i)=>{
  const h=E.heroes[s.hero],base=`team.${i}`,variants=h?E.db.heroes.filter(x=>x.OriginId===h.OriginId).sort((a,b)=>a.Rank-b.Rank):[];
  const heroChoices=visualInput('Hero','data-hero',String(i),h?heroLabel(h):'Empty slot',[{value:'Empty slot',label:'Empty slot'},...origins.map(x=>({value:heroLabel(x),label:heroLabel(x),image:imagePath(x.image),detail:x.ElementalType+' · '+E.stage(x)}))]);
  if(!h)return `<article class="slot"><h3>Slot ${i+1}</h3>${heroChoices}</article>`;
  const compatible=E.db.items.filter(x=>x.Type==='weapon'&&E.compatible(h,x));
  const weapons=compatible.filter(x=>!['accessory','shield'].includes(x.WeaponType));
  const equipment=[['weapon','Weapon',weapons],['shield','Shield / second equipment',compatible.filter(x=>x.WeaponType==='shield')],['accessory','Accessory',compatible.filter(x=>x.WeaponType==='accessory')],['card1','Card 1',E.db.items.filter(damageCard)],['card2','Card 2',E.db.items.filter(damageCard)],['merch','Merch',E.db.items.filter(x=>x.Type==='merch')],['jewel','Jewel',E.db.items.filter(x=>x.Type==='jewel')],['relic','Relic (evolution included)',E.db.items.filter(x=>x.Type==='relic')]];
  return `<article class="slot"><div class="slot-head">${h.image?`<img src="${esc(imagePath(h.image))}" alt="${esc(h.displayName)}">`:''}<div><strong>${esc(h.displayName)}</strong><div class="fine">${esc(E.stage(h))} · ${esc(h.ElementalType)} · ${esc(h.CoopClass)}</div></div><label><input type="radio" name="leader" data-leader="${i}" ${state.leader===i?'checked':''}>Leader</label></div><div class="field-grid">${heroChoices}${select('Evolution / stage',base+'.hero',s.hero,variants.map(x=>[x.Id,E.stage(x)+' · '+x.Name]))}${field('Hero level',base+'.level',s.level,1,E.heroCap(h),1)}${field('Weapon level',base+'.weaponLevel',s.weaponLevel,1,E.weaponCap(E.items[s.weapon]),1)}</div>${h.OriginId===368?'<div class="notice">'+field('Enemies within Beth’s passive range ('+(h.Rank===6?'4':'3')+' tiles)',base+'.nearbyEnemies',s.nearbyEnemies??1,0,3,1)+'<span class="fine">20% damage per nearby enemy, capped at 60%. Default: one nearby raid boss. Set 0 if outside the range. This changes damage, not prepared ATK / UI DPS.</span></div>':''}${E.effectRefs(s).some(r=>['LowHpDamageBoost','GourrySpecial'].includes(E.options[r.OptionId]?.Class))?'<div class="notice">'+field('Current HP (%) — damage passive',base+'.hpPercent',s.hpPercent??100,0,100,1)+'<span class="fine">HP at the moment of the hit. Defaults to full health; this changes damage without changing prepared ATK or UI DPS.</span></div>':''}<div class="toolbar"><button data-ex="${i}">Equip own max EX</button><button data-unarmed="${i}">Remove weapon</button></div><details ${i===0?'open':''}><summary>Equipment, cards, merch and relic</summary><div class="equipment-grid">${equipment.map(([key,label,rows])=>picker(label,base+'.'+key,s[key],rows)).join('')}</div>${field('Merch level',base+'.merchLevel',s.merchLevel,1,30,1)}</details><div class="relic-panel"><h3>Relic substats & stage bonus</h3><p class="fine">Choose three substats, a special effect and the stage bonus below. The roll level adjusts the value shown beside it; maximum values are labelled in each menu.</p>${relicUI(s,i)}<label class="checkbox"><input type="checkbox" data-boolean="${base}.relicSet" ${s.relicSet?'checked':''}>Include set bonus when all four equipped relics share this type</label></div><details><summary>Extra active bonuses and attack assumptions</summary><p class="muted">These are additional manual bonuses. Do not repeat a bonus already supplied by your equipment or account. They are useful for conditional effects not yet decoded.</p><div class="field-grid">${Object.keys(s.extra).map(k=>field(({atk:'Ordinary ATK',battleAtk:'Battle ATK',crit:'Critical chance',critDamage:'Extra critical damage',skill:'Skill damage',normal:'Normal damage',ranged:'Ranged damage',melee:'Melee damage',boss:'Boss damage'})[k]+' (%)',base+'.extra.'+k,s.extra[k])).join('')}</div><p class="fine">Attack coefficients are multiples of base attack-derived DPS, before critical chance. Use a manual override only when you know the coefficient; custom entries are never labelled verified.</p>${E.attackList(s).map(a=>{const o=s.attackOverrides[a.name]||{enabled:false,coefficient:a.coefficient||1,hits:a.ticks?.length||1};return `<div class="attack-editor"><strong>${esc(a.name)}</strong> <span class="badge ${a.status}">${a.status}</span><label class="checkbox"><input type="checkbox" data-override="${i}" data-action="${esc(a.name)}" data-key="enabled" ${o.enabled?'checked':''}>Use my coefficient</label><div class="field-grid"><label>Total DPS coefficient<input type="number" min="0" max="1000" step=".01" data-override="${i}" data-action="${esc(a.name)}" data-key="coefficient" value="${o.coefficient}"></label><label>Equal-sized hits<input type="number" min="1" max="100" step="1" data-override="${i}" data-action="${esc(a.name)}" data-key="hits" value="${o.hits}"></label></div></div>`;}).join('')}</details></article>`;
 }).join('');
}
const elementLabel=k=>({None:'Basic',Ice:'Water'}[k]||k);
function targetUI(){
 const b=E.bosses[state.boss];
 $('#boss-fields').innerHTML=visualInput('Raid boss record','data-path','boss',(b.Name.includes('nine_tailed_fox')?'Garam · ':'')+b.Name+' · #'+b.Id,E.db.bosses.map(b=>({value:String(b.Id),label:(b.Name.includes('nine_tailed_fox')?'Garam · ':'')+b.Name+' · #'+b.Id,image:imagePath(b.image),detail:elementLabel(b.ElementalType)})))+select('Boss element','element',state.element,['None','Fire','Ice','Earth','Light','Darkness','Nebula'].map(x=>[x,elementLabel(x)]))+select('Boss ailment','ailment',state.ailment,[['none','None'],['airborne','Airborne · ranged ×1.5'],['downed','Downed · melee ×1.5'],['injured','Injured · direct hits unchanged']]);
 $('#boss-info').textContent=`Base DEF ${fmt(b.StaticDef??b.Def)} · Permanent raid protection ${state.element==='None'?73:75}%. Changing element selects the regular-raid protection convention; it does not remove protection.`;
 const ds=E.availableDebuffs(state);state.debuffs=state.debuffs.filter(id=>ds.some(d=>d.id===id));
 $('#debuff-list').innerHTML=ds.length?ds.map(d=>`<label><input type="checkbox" data-debuff="${d.id}" ${state.debuffs.includes(d.id)?'checked':''}>${esc(d.label)}</label>`).join(''):'<p class="muted">No automatically modelled debuffs for this equipped team. See the coverage notes in each result.</p>';
 $('#effect-list').innerHTML=state.team.some(s=>E.heroes[s.hero]?.OriginId===596&&s.weapon)?`<label class="checkbox"><input type="checkbox" data-effect="dabin-role" ${state.effects.includes('dabin-role')?'checked':''}>Dabin’s role-hit buff is active (ordinary shot ×1.30)</label>`:'';
 $('#custom-debuffs').innerHTML=Object.entries({def:'Additional generic DEF reduction (%)',rangedDef:'Additional ranged DEF reduction (%)',meleeDef:'Additional melee DEF reduction (%)',resistance:'Additional resistance reduction (%)'}).map(([k,l])=>field(l,'customDebuffs.'+k,state.customDebuffs[k],0,k==='resistance'?100:99)).join('');
}
function activeBuffUI(){
 const available=E.availableBuffs(state);
 state.activeBuffs=(state.activeBuffs||[]).filter(r=>available.some(b=>b.id===r.id));
 const labels={battleAtk:'battle ATK',skill:'skill damage',crit:'critical chance',critDamage:'critical damage',ranged:'ranged damage',melee:'melee damage',normal:'normal attack damage',element:'elemental ATK',damageMultiplier:'conditional damage'};
 $('#active-buff-list').innerHTML=available.length?available.map(b=>{
  const selected=state.activeBuffs.find(r=>r.id===b.id),scope=b.scope==='Unknown'?(selected?.scope||'Unknown'):b.scope;
  const amount=b.value*(b.key==='crit'?1:100),effect='+'+prec(amount)+'% '+(b.element?elementLabel(b.element)+' ':'')+labels[b.key];
  return `<article class="buff-choice"><label class="checkbox"><input type="checkbox" data-active-buff="${esc(b.id)}" ${selected?'checked':''}><strong>${esc(b.hero)} · ${esc(effect)}</strong></label><p class="fine">${esc(b.trigger)} · ${b.duration?b.duration+'s':'Conditional window'} · ${b.scope==='Party'?(b.recipientElement?elementLabel(b.recipientElement)+' heroes only':'Whole team'):b.scope==='Self'?'Source hero only':'Recipient not decoded — choose below'}${b.maxStacks>1?' · per stack':''}</p>${b.scope==='Unknown'?`<label>Apply to (manual assumption)<select data-buff-scope="${esc(b.id)}"><option value="Unknown" ${scope==='Unknown'?'selected':''}>Choose recipient before applying</option><option value="Self" ${scope==='Self'?'selected':''}>Source hero only</option><option value="Party" ${scope==='Party'?'selected':''}>Whole team</option></select></label>`:''}${b.maxStacks>1?`<label>Active stacks<input type="number" min="1" max="${b.maxStacks}" step="1" value="${selected?.stacks||1}" data-buff-stacks="${esc(b.id)}"></label>`:''}<details><summary>Source record</summary><a href="index.html?table=${b.optionId?'static-options':'static-buffs'}&q=${b.optionId||b.buffId}">${esc(b.name)} · #${b.optionId||b.buffId}</a><p class="fine">${esc(b.source)}. ${b.optionId?'Damage multiplier traced in native code; activation and expiry are manual.':b.scope==='Unknown'?'Trigger / recipient interpretation needs script verification.':'Recipient is mapped from the action record; runtime timing is not replayed.'}</p></details></article>`;
 }).join(''):'<p class="muted">No supported temporary damage buffs found for this equipped team. Unknown script effects can still be entered under each hero’s extra active bonuses.</p>';
 const applied=state.team.map((s,i)=>{const h=E.heroes[s.hero];return h?h.displayName+': '+E.activeBuffEffects(state,i,available).length+' active contribution(s)':null;}).filter(Boolean);
 $('#active-buff-summary').textContent=applied.join(' · ');
}
function resultsUI(){
 const r=lastResult=E.calculate(state);
 $('#damage-results').innerHTML=r.heroes.map(v=>{
  const stats=[['Prepared ATK',fmt(v.atk)],['Estimated UI DPS',fmt(v.uiDps)],['Critical chance',prec(v.crit*100)+'%'],['Critical multiplier','×'+prec(v.critMultiplier)],['Skill multiplier','×'+prec(v.skill)]];
  const rows=v.results.map(a=>{
   const title=`${esc(a.name)}<small>${esc(a.kind==='weapon'?'Weapon skill':a.kind==='chain'?'Chain skill':a.kind==='leader'?'Leader skill':a.kind)} <span class="badge ${a.status}">${a.eventOnly?'Code-traced event':a.status==='verified'?'Code-traced formula':a.status==='resolved'?'Resolved data model':a.status}</span></small>`;
   if(a.unavailable)return `<tr><td>${title}</td><td colspan="3">${esc(a.unavailable)}</td></tr>`;
   if(!a.total)return `<tr><td>${title}</td><td colspan="3">Not calculated — coefficient unresolved</td></tr>`;
   return `<tr class="${a.hits.length>1?'total-row':''}"><td>${title}${a.hits.length>1?'<small>Full cast total · all hits connect</small>':!a.ticks?'<small>Aggregate · hit sequence unresolved</small>':(a.eventOnly?'<small>ONE EVENT ONLY — not a cast total or guaranteed extra hit</small>':'<small>1 modelled damage event</small>')}${a.validation?'<small>Validated scope: '+esc(a.validation)+'</small>':''}${a.hits.length===1&&a.hits[0].appliedAfter?.length?'<small>After this hit: '+esc(a.hits[0].appliedAfter.join(' · '))+'</small>':''}</td><td>${fmt(a.total.noncrit)}</td><td>${fmt(a.total.critical)}</td><td>${fmt(a.total.average)}</td></tr>`+(a.hits.length>1?a.hits.map((hit,i)=>`<tr><td>↳ Hit ${i+1}${a.timings?' · '+a.timings[i].toFixed(2)+' s':''}${hit.activeEffects?.length?'<small>Active: '+esc(hit.activeEffects.join(' · '))+'</small>':''}${hit.appliedAfter?.length?'<small>After this hit: '+esc(hit.appliedAfter.join(' · '))+'</small>':''}</td><td>${fmt(hit.noncrit)}</td><td>${fmt(hit.critical)}</td><td>${fmt(hit.average)}</td></tr>`).join(''):'');
  }).join('');
  const breakdown=v.results.filter(a=>a.total).map(a=>`<details><summary>${esc(a.name)} · calculation</summary><p class="fine">${esc(a.note)}</p>${a.breakdown.map(c=>`<div class="formula">Hit ${(c.hitIndex??0)+1} · ${esc(c.element)} weapon ATK after matching bonus: ${prec(c.weaponAttack)}
Hero raw coefficient ${v.h.Atk} × level growth ${prec(RaidEngine.growth(state.team[v.index].level,v.h.StatGrowthRate))}
Ordinary ATK group ×${prec(c.ordinary)} · Guardian / mastery ×${prec(v.account)}
Prepared ATK ${prec(c.atk)} → battlefield ATK ${prec(c.battleAtk)}
× weapon ATK-to-DPS ${prec(v.factor)} × attack coefficient ${prec(a.coefficient)}
× attack-type ${prec(c.typeFactor)} × skill ${prec(c.skillFactor)} × normal ${prec(c.normalFactor)}
× nearby-enemy passive ${prec(c.proximity??1)} × other damage passives ${prec(c.damageMultiplier??1)}
× boss damage ${prec(1+v.e.boss)} × role ${prec(c.role)} × ailment ${prec(c.ailment)}
× DEF mitigation 100 / (100 + ${prec(c.defense)})
× elemental matchup ${prec(c.matchup)} × resistance ${prec(c.resistance)}
× permanent protection remainder ${prec(1-c.protection)}
Critical result ×${prec(v.critMultiplier)} · average ×${prec(1+v.crit*(v.critMultiplier-1))}</div>`).join('')}</details>`).join('');
  const gaps=v.coverage.filter(c=>/Unresolved|Partial|Manual/.test(c.status));
  const coverage=`<p class="notice"><strong>Partial damage model</strong> · ${gaps.length} option entries need manual conditions or further tracing. Attack formulas and hit sequences also have their own limits below.</p><details><summary>Hero & equipment effect audit (${v.coverage.length} option entries)</summary><p class="fine">This audits the selected loadout. <a href="source-validation.html?hero=${v.h.OriginId}">Explore this hero’s source analysis</a>. A recovered base attack does not prove all its passive or EX effects are included. <a href="data/raid-effects-audit.json" download>Download the complete hero / equipment audit</a>.</p><ul class="warning-list">${v.coverage.map(c=>`<li><strong>${esc(c.status)}</strong> · <a href="index.html?table=static-options&q=${c.id}">${esc(c.name||String(c.id))}</a><br>${esc(c.source)} — ${esc(c.note)}</li>`).join('')}</ul></details>`;
  return `<article class="result-hero"><h3>${esc(v.h.displayName)} · ${esc(E.stage(v.h))}${state.leader===v.index?' · Leader':''}</h3>${coverage}<div class="stat-strip">${stats.map(([k,val])=>`<div class="stat"><span>${k}</span><strong>${val}</strong></div>`).join('')}</div><div class="table-scroll"><table><thead><tr><th>Attack / cast</th><th>Noncritical</th><th>All critical</th><th>Average</th></tr></thead><tbody>${rows}</tbody></table></div><details><summary>Coverage & effects not yet modelled (${v.warnings.length})</summary><p class="muted">The general stat pipeline is reconstructed. Scripted procs, stacks, transformations, dual-wield specifics and timing may require additional models. Chain/leader aggregate coefficients are estimates; their critical behavior and skill-bonus eligibility need action-specific checks. A missing effect is not assumed to grant zero in the real game.</p><ul class="warning-list">${v.warnings.map(t=>`<li>${esc(t)}</li>`).join('')}</ul></details><details><summary>Applied hero, equipment and party options</summary><ul class="fine">${[...v.e.sources,...r.party.sources].map(t=>`<li>${esc(t)}</li>`).join('')}</ul></details>${breakdown}</article>`;
 }).join('')||'<p>Choose at least one hero to calculate damage.</p>';
}
function render(){profileUI();teamUI();targetUI();activeBuffUI();resultsUI();save();}
function update(){targetUI();activeBuffUI();resultsUI();save();}
function relicDefaults(s){const r=E.items[s.relic];s.relicOptions=[...(r?.BaseOptions||[]),...(r?.ChangeOptions||[])].map(()=>({OptionId:0,Level:0}));}
function handleChange(event){
 const t=event.target;
 if(t.dataset.imagePicker&&event.isTrusted)return;
 try{
 if(t.dataset.activeBuff||t.dataset.buffScope||t.dataset.buffStacks){
  const id=t.dataset.activeBuff||t.dataset.buffScope||t.dataset.buffStacks,b=E.availableBuffs(state).find(b=>b.id===id);if(!b)return;
  let chosen=state.activeBuffs.find(r=>r.id===id);
  if(t.dataset.activeBuff&&!t.checked)state.activeBuffs=state.activeBuffs.filter(r=>r.id!==id);
  else{
   if(!chosen){chosen={id,stacks:1,scope:b.scope};state.activeBuffs.push(chosen);}
   if(t.dataset.buffScope)chosen.scope=t.value;
   if(t.dataset.buffStacks){if(!t.checkValidity())throw Error('Enter a valid whole-number stack count.');chosen.stacks=Number(t.value);}
  }
  activeBuffUI();resultsUI();save();
 }else if(t.dataset.hero!==undefined){const i=Number(t.dataset.hero);if(t.value==='Empty slot')state.team[i]=E.slot();else{const h=origins.find(h=>heroLabel(h)===t.value);if(!h)throw Error('Choose a hero from the name suggestions.');if(state.team.some((s,j)=>j!==i&&E.heroes[s.hero]?.OriginId===h.OriginId))throw Error('This hero is already in the team.');state.team[i]=E.slot(h.Id);}render();}
 else if(t.dataset.picker){const path=t.dataset.picker,key=path.split('.').at(-1),s=state.team[Number(path.split('.')[1])];const item=t.value==='None'?null:E.db.items.find(i=>itemLabel(i)===t.value);if(t.value!=='None'&&!item)throw Error('Choose an equipment item from the suggestions, or None.');
  const type={card1:'orb',card2:'orb',merch:'merch',relic:'relic',jewel:'jewel'}[key]||'weapon';if(item&&item.Type!==type)throw Error('That item belongs in another equipment slot.');
  if(item&&type==='orb'&&!damageCard(item))throw Error('Choose an ATK, skill damage or critical chance card.');
  if(item&&type==='weapon'&&(!E.compatible(E.heroes[s.hero],item)||(key==='accessory'&&item.WeaponType!=='accessory')||(key==='shield'&&item.WeaponType!=='shield')||(key==='weapon'&&['shield','accessory'].includes(item.WeaponType))))throw Error('This item is not compatible with that slot.');
  if(item&&((key==='card1'&&s.card2===item.Id)||(key==='card2'&&s.card1===item.Id)))throw Error('Use two different cards.');
  set(path,item?.Id||0);if(key==='weapon')s.weaponLevel=E.weaponCap(item);if(key==='relic')relicDefaults(s);teamUI();update();
 }else if(t.dataset.path){
  if(t.type==='number'&&!t.checkValidity())throw Error('Enter a number within the displayed range.');
  const path=t.dataset.path;let val=t.type==='number'||['boss'].includes(path)||path.includes('.hero')||path.includes('OptionId')?Number(t.value):t.value;
  if(!Number.isFinite(val)&&typeof val==='number')throw Error('Enter a valid number.');
  const previous=get(path);set(path,val);if(path.endsWith('.merchLevel'))teamUI();
  if(path.includes('.relicOptions.')&&path.endsWith('.Level')){const parts=path.split('.'),roll=state.team[Number(parts[1])].relicOptions[Number(parts[3])];const preview=t.closest('.relic-roll')?.querySelector('span');if(preview)preview.textContent=optionText(roll);}
  if(path==='boss')state.element=E.bosses[val].ElementalType;
  if(path.endsWith('.hero')){const s=state.team[Number(path.split('.')[1])];for(const key of ['weapon','shield','accessory'])if(!E.compatible(E.heroes[val],E.items[s[key]]))s[key]=0;if(E.items[s.weapon]?.ExclusiveCharacterId===E.heroes[previous]?.OriginId)s.weapon=E.bestWeapon(E.heroes[val]);s.level=Math.min(s.level,E.heroCap(E.heroes[val]));s.weaponLevel=Math.min(s.weaponLevel,E.weaponCap(E.items[s.weapon]));s.attackOverrides={};teamUI();}
  if(path.endsWith('OptionId')){const parts=path.split('.'),s=state.team[Number(parts[1])],j=Number(parts[3]),r=E.items[s.relic],pool=[...r.BaseOptions,...r.ChangeOptions][j];s.relicOptions[j].Level=pool.find(x=>x.OptionId===val)?.MaxLevel||0;teamUI();}
  update();
 }else if(t.dataset.boolean){set(t.dataset.boolean,t.checked);update();}
 else if(t.dataset.leader!==undefined){state.leader=Number(t.dataset.leader);update();}
 else if(t.dataset.debuff){state.debuffs=t.checked?[...state.debuffs,t.dataset.debuff]:state.debuffs.filter(x=>x!==t.dataset.debuff);update();}
 else if(t.dataset.effect){state.effects=t.checked?[...state.effects,t.dataset.effect]:state.effects.filter(x=>x!==t.dataset.effect);update();}
 else if(t.dataset.override!==undefined){if(t.type==='number'&&!t.checkValidity())throw Error('Invalid attack coefficient / hit count.');const s=state.team[Number(t.dataset.override)],a=E.attackList(s).find(a=>a.name===t.dataset.action);s.attackOverrides[t.dataset.action]||={enabled:false,coefficient:a?.coefficient||1,hits:a?.ticks?.length||1};s.attackOverrides[t.dataset.action][t.dataset.key]=t.type==='checkbox'?t.checked:Number(t.value);resultsUI();save();}
 }catch(e){notice(e.message,true);return;}
 if(t.matches('[data-path],[data-picker],[data-hero],[data-leader],[data-debuff],[data-effect],[data-override],[data-boolean]')&&storageAvailable)notice('Setup saved on this browser.');
}
document.addEventListener('change',handleChange);
document.addEventListener('input',e=>{
 const t=e.target;
 if(t.dataset.imagePicker)return;
 if(t.type==='number'&&!t.dataset.buffStacks&&t.value!==''&&t.checkValidity())handleChange(e);
 else if(t.dataset.picker&&(t.value==='None'||E.db.items.some(i=>itemLabel(i)===t.value)))handleChange(e);
 else if(t.dataset.hero!==undefined&&(t.value==='Empty slot'||origins.some(h=>heroLabel(h)===t.value)))handleChange(e);
});
document.addEventListener('click',e=>{const t=e.target.closest('button');if(!t)return;if(t.dataset.ex!==undefined){const s=state.team[Number(t.dataset.ex)];s.weapon=E.bestWeapon(E.heroes[s.hero]);s.weaponLevel=E.weaponCap(E.items[s.weapon]);render();}if(t.dataset.unarmed!==undefined){state.team[Number(t.dataset.unarmed)].weapon=0;render();}});
$('#max-profile').onclick=()=>{const mastery=state.profile.mastery,name=state.profile.name;state.profile=JSON.parse(JSON.stringify(E.maxProfile));state.profile.mastery=mastery;state.profile.name=name;render();notice('Snapshot maximum preset applied. Your mastery levels were kept. Check the editable collection assumptions.');};
$('#measured').onclick=()=>{state=E.measured();render();notice('Measured example loaded: Dabin + EX, teammates unarmed, Earth debuff only. Recorded hit: 513,669 critical.');};
$('#profile-name').oninput=()=>{state.profile.name=$('#profile-name').value.trim()||'My profile';save();};
$('#save-profile').onclick=()=>{try{profiles[state.profile.name]=JSON.parse(JSON.stringify(state.profile));localStorage.setItem(PROFILES,JSON.stringify(profiles));profileUI();notice('Account profile saved locally.');}catch{notice('Local saving unavailable. Download your profile instead.',true);}};
$('#load-profile').onclick=()=>{const p=profiles[$('#profile-list').value];if(!p){notice('Choose a saved profile first.',true);return;}try{state=E.validate({...state,profile:p});render();notice('Profile loaded; team preserved.');}catch(e){notice(e.message,true);}};
$('#export').onclick=()=>download('guardian-raid-setup.json',state);
$('#export-profile').onclick=()=>download('guardian-account-profile.json',{version:1,type:'guardian-account-profile',profile:state.profile});
$('#download-results').onclick=()=>download('guardian-raid-results.json',{snapshot:E.db.snapshot,setup:state,results:lastResult.heroes.map(v=>({hero:v.h.Id,preparedAtk:v.atk,crit:v.crit,critMultiplier:v.critMultiplier,attacks:v.results,coverage:v.coverage,warnings:v.warnings}))});
$('#import').onchange=async()=>{try{const f=$('#import').files[0];if(!f)return;if(f.size>2e6)throw Error('Setup file is too large (maximum 2 MB).');const data=JSON.parse(await f.text());state=E.validate(data.type==='guardian-account-profile'?{...state,profile:data.profile}:data);render();notice('Imported successfully.');}catch(e){notice('Import failed: '+e.message,true);}finally{$('#import').value='';}};
$('#clear-active-buffs').onclick=()=>{state.activeBuffs=[];update();};
$('#clear-debuffs').onclick=()=>{state.debuffs=[];for(const k in state.customDebuffs)state.customDebuffs[k]=0;update();};
$('#all-debuffs').onclick=()=>{state.debuffs=E.availableDebuffs(state).map(d=>d.id);update();};
render();$('#simulator').hidden=false;if(!$('#status').classList.contains('error'))notice('Ready. Changes save locally in this browser; download a setup to share or back it up.');
}catch(e){notice('Simulator could not start: '+e.message,true);}
})();
