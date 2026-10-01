'use strict';
(async () => {
 const $=s=>document.querySelector(s), esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 const num=n=>Number(n||0).toLocaleString('es-ES',{useGrouping:'always',maximumFractionDigits:6}), link=(t,id)=>`index.html?table=${t}&record=${id}#${t}`;
 const picture=(path,name)=>path?`<img src="data/visual/${esc(path)}" alt="${esc(name)}">`:`<span class="image-fallback">${esc(name)}</span>`;

 function scaledStats(s, floor, options = []) {
  const f32=Math.fround, level=floor.StandardLevel, growth=Number(s.StatGrowthRate);
  if(!Number.isInteger(level)||level<0||!Number.isFinite(growth)||growth<=0||
     ![s.Hp,s.Atk,s.Def].every(v=>typeof v==='number'&&Number.isFinite(v)))return null;
  const g=f32(growth), hp=f32(f32(s.Hp)*f32(f32(g*g)**level));
  const factor=f32(g**level);
  const verified=options.length===1&&[200022,200010].includes(options[0].OptionId)&&options[0].Level===1;
  const parameters={200001:[1.5,0.25],200021:[1.5,0.25],200022:[1.5,0.25],200010:[2.75,0.375]};
  // Mortar ATK/DEF defaults are a user-requested extrapolation, not source parameters.
  const attackParameters={200001:[0.3,0.05],200021:[0.3,0.05],200022:[0.3,0.05],200010:[0.5,0.05]};
  const quantize=q=>q===0?0:Math.ceil(q*10-1e-9)/10;
  let bonus=0,attackBonus=0,unknown=false,combatUnknown=false;
  for(const option of options){
   const p=parameters[option.OptionId];
   if(!p||!Number.isInteger(option.Level)||option.Level<0){unknown=true;combatUnknown=true;continue;}
   // Shared quantization is a working hypothesis, not recovered runtime constants.
   bonus+=quantize(p[0]+p[1]*option.Level);
   const a=attackParameters[option.OptionId];
   if(a)attackBonus+=quantize(a[0]+a[1]*option.Level);
   else combatUnknown=true;
  }
  const hpMultiplier=1+bonus;
  const atkMultiplier=1+attackBonus,defMultiplier=1;
  return {level:level+1,hp:Math.trunc(f32(hp*f32(hpMultiplier))),hpMultiplier,atkMultiplier,defMultiplier,
   atk:f32(f32(f32(s.Atk)*factor)*f32(atkMultiplier)),def:f32(f32(s.Def)*factor),
   combatElite:combatUnknown?'incomplete':options.length?'estimated':'none',
   mortarParametersAssumed:options.some(o=>o.OptionId===200001),
   elite:verified?'verified':unknown?'unverified':options.length?'estimated':'none'};
 }
 const statNumber=n=>Number(n).toLocaleString('es-ES',{useGrouping:'always',maximumFractionDigits:2});
 function statsMarkup(s,f,m){
  const v=scaledStats(s,f,m.Options||[]);
  if(!v)return '<p class="fine">Level-scaled stats unavailable: missing source values.</p>';
  const hpLabel=v.elite==='unverified'?'HP (unknown modifiers excluded)':'HP';
  return '<p class="enemy-level">Level '+v.level+'</p><dl class="enemy-stats"><div><dt>'+hpLabel+'</dt><dd>'+statNumber(v.hp)+
   '</dd></div><div><dt>ATK</dt><dd>'+statNumber(v.atk)+'</dd></div><div><dt>DEF</dt><dd>'+statNumber(v.def)+'</dd></div></dl>'+
   '<p class="fine">'+(v.elite==='none'?'':'Elite multipliers: HP ×'+statNumber(v.hpMultiplier)+' / ATK ×'+statNumber(v.atkMultiplier)+' / DEF ×'+statNumber(v.defMultiplier)+'. ')+
   (v.combatElite==='incomplete'?'Unknown option modifiers excluded. ':'')+
   'HP / ATK / DEF include level scaling but exclude equipment and other buffs.</p>';
 }
 window.orbitalStatScaling={calculate:scaledStats};

 function weaponStats(item,level,scales){
  if(!item||!Number.isInteger(level)||level<0)return null;
  const growth=item.StatGrowthRate,scale=item.LevelScale?scales[level]:1;
  if(!Number.isFinite(growth)||!Number.isFinite(scale)||item.UseAlterStats)return null;
  const f=Math.fround,factor=f(f(growth)**level);
  const calc=value=>Number.isFinite(value)?f(f(f(value)*f(scale))*factor):null;
  return {internalLevel:level,level:level+1,growth,scale,growthFactor:factor,attack:calc(item.Damage),defense:calc(item.Defense),assumption:'Weapon internal level = floor StandardLevel; equipment component only, not final damage.'};
 }
 let equipment={items:{},scales:{}},equipmentError=false;
 function weaponMarkup(s,f){
  const slots=['DefaultWeapon1'].filter(k=>s[k]>0);
  if(!slots.length)return '<p class="fine">No default weapon assigned.</p>';
  return slots.map(slot=>{
   const label='Weapon';
   const id=s[slot],item=equipment.items[id],v=weaponStats(item,f.StandardLevel,equipment.scales);
   if(!item)return `<p class="fine">${label}: <a href="${link('static-items',id)}">Item ${id} →</a> · ${equipmentError?'Equipment data unavailable':'Record unavailable'}</p>`;
   return `<details class="weapon-details"><summary>${equipment.media?.[id]?.image?'<span class="weapon-icon">'+picture(equipment.media[id].image,item.Name)+'</span>':''}<strong>${label}: ${esc(item.Name)}</strong>${Number.isFinite(item.Critical)&&item.Critical>0?`<span class="weapon-crit" title="Base weapon critical chance; not verified final combat chance." aria-label="Base weapon critical chance: ${num(item.Critical)} percent">CRIT ${num(item.Critical)}%</span>`:''}</summary><p>${v&&v.attack!==null?'Weapon ATK '+statNumber(v.attack):''}${v&&v.defense!==null?'Equipment DEF '+statNumber(v.defense):''}${!v?'Scaled stats unavailable':''} · <a href="${link('static-items',id)}">Item ${id} →</a></p><p class="fine">${Number.isFinite(item.Damage)?'Base Damage '+num(item.Damage):'Base DEF '+num(item.Defense)} · Growth ×${num(item.StatGrowthRate)} per level${v?' · Growth factor ×'+num(v.growthFactor)+' · Level-scale factor ×'+num(v.scale):''}</p><details><summary>Calculation & source</summary><p class="fine">Equipment level assumed equal to monster level (${f.StandardLevel+1}); internal exponent ${f.StandardLevel}. Base × growth^${f.StandardLevel} × level-scale factor. Separate equipment component: not added to the displayed monster ATK/DEF; excludes elite bonuses, options and final damage calculations.</p><pre>${esc(JSON.stringify(item,null,2))}</pre><a href="${link('static-itemlevelscalefactor',f.StandardLevel)}">Level-scale source →</a></details></details>`;
  }).join('');
 }
 window.orbitalWeaponScaling={calculate:weaponStats};
 let debuffData={enemies:{}},debuffError=false;
 function debuffMarkup(s){
  const entries=debuffData.enemies[s.Id]||[];
  if(!entries.length)return `<p class="fine">${debuffError?'Debuff data unavailable.':'No directly linked stat debuff found in this scan; other effects may exist.'}</p>`;
  const labels={SymbolDefenseScale:'DEF reduction',DefenseScale:'DEF reduction',MeleeDefenseScale:'Melee DEF reduction',ProjectileDefenseScale:'Ranged DEF reduction',TotalAttackScale:'ATK reduction',SymbolAttackScale:'ATK reduction',DamageResistance:'Resistance reduction'};
  return `<details class="enemy-debuffs"><summary><strong>Enemy debuffs (${entries.length})</strong></summary><p class="fine">Referenced by this tower variant’s actions, not weapon properties. Combat activation and final magnitude are not verified. Script/projectile-only effects may be missing.</p>${entries.map(e=>{const b=e.record;
   const prefix=b.ClassName==='DamageResistance'?'Resistance':/AttackScale$/.test(b.ClassName)?'AttackScale':/DefenseScale$/.test(b.ClassName)?'DefenseScale':null;
   const base=prefix?b[prefix+'Base']??0:0,add=prefix?b[prefix+'Add']??0:0,factor=prefix==='Resistance'?1:100;
   const levels=[...new Set(e.references.map(r=>r.level).filter(Number.isFinite))];
   const pct=value=>num(Math.abs(value)*factor)+'%';
   const magnitude=!prefix?'':add===0?pct(base):levels.length===1&&e.references.every(r=>Number.isFinite(r.level))?pct(base+add*levels[0]):pct(base)+' + '+pct(add)+' × buff level (level unspecified)';
   return `<section><p><strong>${esc(b.Elemental?b.Elemental+' resistance reduction':labels[b.ClassName]||b.ClassName)}</strong>${magnitude? ' · '+esc(magnitude):''} · ${Number.isFinite(b.Duration)?num(b.Duration)+' s':'Duration unspecified'}${b.StackCap?' · Stack cap '+num(b.StackCap):''}</p><p class="fine">Source parameters: ${Object.entries(b).filter(([k,v])=>typeof v==='number'&&/^(AttackScale|DefenseScale|Resistance)(Base|Add)$/.test(k)).map(([k,v])=>esc(k)+' = '+num(v)).join(' · ')}</p><details><summary>Action references & source</summary><p class="fine">Displayed percentages use Base + Add × buff level. Scale fields are converted to percent (×100); Resistance fields already use percentage points. Missing nonzero-Add levels are shown as a formula, not assumed. Values do not imply a matching change in final damage; stacking and combat activation are not verified.</p>${e.references.map(r=>`<p class="fine"><a href="${link('static-battlestyles',r.styleId)}">Tower battle style →</a> · <a href="${link('static-battleactions',r.actionId)}">${esc(r.action)} →</a> · ${esc(r.field)}${r.level!==null?' · Buff level '+r.level:' · Buff level not specified in this reference'}</p>`).join('')}<a href="${link('static-buffs',e.id)}">${esc(b.Name)} · Buff ${e.id} →</a><pre>${esc(JSON.stringify(b,null,2))}</pre></details></section>`;}).join('')}</details>`;
 }
 let db,current,filtered=[],roomData={entries:[]},roomError=false;
 function showRecordRoom(f){
  let panel=$('#record-room-panel');
  if(!panel){panel=document.createElement('section');panel.id='record-room-panel';$('.formation-layout').after(panel);}
  const active=f.FloorType==='RecordRoom';
  $('.formation-layout').hidden=active;panel.hidden=!active;
  if(!active)return;
  const entries=roomData.entries.filter(e=>e.floor===f.Floor);
  const letters=[...new Set(entries.map(e=>e.record))].sort();
  panel.innerHTML=`<div class="record-room-layout"><section class="formation-panel"><h3>Record Room</h3><img class="record-room-art" src="data/visual/map-thumbnails/tower_recordroom.webp" alt="Tower record room map"><p><a href="map-preview.html?map=tower_recordroom&mode=art&markers=1&layers=0,1,2,3,4,5&types=npcs,monsters,events,camera,other#map">Explore map & console positions →</a></p><div class="record-room-buttons" aria-label="Choose a record"></div></section><article class="floor-data record-room-reader"><h3 id="room-record-title"></h3><div id="room-dialogue"></div><details id="room-source"><summary>Text keys & source</summary><p class="fine"></p><pre></pre></details></article></div>`;
  const render=letter=>{
   const parts=entries.filter(e=>e.record===letter).sort((a,b)=>a.order-b.order);
   $('#room-record-title').textContent='Record '+letter;
   $('#room-dialogue').innerHTML=parts.map(e=>'<p>'+esc(e.text)+'</p>').join('');
   $('#room-source p').hidden=true;
   $('#room-source pre').textContent=parts.map(e=>e.key+'\n'+e.raw).join('\n\n');
   panel.querySelectorAll('.record-room-buttons button').forEach(b=>b.setAttribute('aria-pressed',String(b.textContent==='Record '+letter)));
  };
  for(const letter of letters){const button=document.createElement('button');button.type='button';button.textContent='Record '+letter;button.onclick=()=>render(letter);panel.querySelector('.record-room-buttons').append(button);}
  if(letters.length)render(letters[0]);
  else{const noRecords=[951,1251,1351,1451].includes(f.Floor);$('#room-record-title').textContent=noRecords?'No records':'Records unavailable';$('#room-dialogue').textContent=noRecords?'A broken console.':roomError?'Record data could not be loaded.':'Texts for this floor have not been recovered yet.';$('#room-source').hidden=true;}
 }
 // Reviewed tower-specific chain: monster 105287 -> style 784 -> action 1291 -> buff 55002.
 // Descriptive only: these parameters are not included in the displayed monster stats.
function specialEffectMarkup(s){
  return roleSpecialEffectMarkup(s)+weaponSkillEffectMarkup(s)+targetPriorityMarkup(s);
 }
 function targetPriorityMarkup(s){
  if(['it_magicschool_turret_laser','it_cw_passage_saul_turret'].includes(s.Name))return `<section class="enemy-special-effect enemy-target-priority"><h4>Target priority · Leader</h4><p><strong>Prioritizes the party leader with its laser attack.</strong></p><details><summary>Evidence & source</summary><p class="fine">Action: LaserNew:turretdarkness · TargetSearchType: Manual. This targeting parameter is configured on the attack, rather than the general DoNothing AI. It does not establish taunt immunity.</p><p><a href="${link('static-battleactions',1308)}">Laser attack parameters →</a></p></details></section>`;
  if(s.Name==='it_lw_passage_waller')return `<section class="enemy-special-effect enemy-target-priority"><h4>Target priority · Leader</h4><p><strong>Prioritizes the party leader.</strong></p><details><summary>Evidence & source</summary><p class="fine">AI: Waller · TargetSearchType: Manual. SearchManualTarget uses SearchManualCharacterTargets, which checks the controller’s IsManual flag. This does not establish taunt immunity.</p><p><a href="${link('static-battleais',35)}">AI configuration →</a> · <a href="research.html?section=code&entry=2912&method=31699#code">SearchManualTarget →</a> · <a href="research.html?section=code&entry=6093&method=57403#code">Manual-target filter →</a></p></details></section>`;
  if(s.Name==='it_cw_passage_saul_charge_target')return `<section class="enemy-special-effect enemy-target-priority"><h4>Target priority · Leader</h4><p><strong>Prioritizes the party leader.</strong></p><details><summary>Evidence & source</summary><p class="fine">Observed in game. WaveCharger.ChangeTarget selects the first eligible target returned by SearchManualCharacterTargets, which checks the controller’s IsManual flag. The identification of this target as the party leader is based on gameplay observations; the controller assignment in Infinity Tower has not been independently verified. This does not establish taunt immunity.</p><p><a href="research.html?section=code&entry=2909&method=31639#code">WaveCharger target selection →</a> · <a href="research.html?section=code&entry=6093&method=57403#code">Manual-target filter →</a></p></details></section>`;
  if(s.Name==='it_demon_turing_male_assassin')return `<section class="enemy-special-effect enemy-target-priority"><h4>Target priority</h4><p><strong>Ranged → Supporter → Melee → Tanker</strong><br>Prefers eligible opponents of the highest-priority combat role. Unlike the Fighter enemies, this selection uses combat roles rather than weapon type.</p><p><strong>Teleport attack · AssassinStab</strong><br>Its Assassin AI selects the target; AssassinStab handles the teleport and strike. This lets it bypass the frontline to attack a preferred target. The teleport belongs to the enemy’s battle action, not its equipped weapon.</p><details><summary>Evidence & source</summary><p class="fine">AI: Assassin. DefaultClassPriorites: [0, 2, 4, 1, 3]. Melee = 2 · Projectile (Ranged) = 4 · Tanker = 1 · Supporter = 3. ChangeTargetByPriority retains candidates with the highest value before selecting a target. These values are separate from the monster’s AggroModifier fields. Priority applies among eligible targets and does not establish immunity to taunt.</p><p><a href="${link('static-battleais',9)}">AI configuration →</a> · <a href="${link('static-battlestyles',798)}">Enemy battle style →</a> · <a href="${link('static-battleactions',1327)}">AssassinStab →</a></p><p><a href="research.html?section=code&entry=2749&method=29918#code">Target selection →</a> · <a href="research.html?section=code&entry=1450&method=13485#code">Teleport positioning →</a></p></details></section>`;
  if(!['it_lw_passage_fighter','it_dungeon_imp_fighter'].includes(s.Name))return '';
  return `<section class="enemy-special-effect enemy-target-priority"><h4>Target priority</h4><p><strong>Prefers opponents with ranged weapons.</strong><br>Checks the target’s weapon type, not their combat role. Supporters with ranged weapons can also be selected. If no eligible ranged-weapon target is found, falls back to general target selection.</p><details><summary>Evidence & source</summary><p class="fine">AI: Following:Fighter · TargetSearchType: Remote. SearchRemoteTarget selects the first eligible candidate whose WeaponTypeSpec.IsRemote is true; otherwise it calls SearchTarget. This is not a fixed ranking of combat roles and does not establish taunt immunity.</p><p><a href="${link('static-battleais',2)}">AI configuration →</a> · <a href="research.html?section=code&entry=2912&method=31701#code">SearchRemoteTarget →</a></p></details></section>`;
 }
 function weaponSkillEffectMarkup(s){
  // Exact Tower spec mappings, including styles with UseSuper=false whose casts were observed in game.
  const skills={
   it_boss_twohand_warrior_mirror_rift:['CwpKnightThunderStrike',936,846],
   it_boss_tanker_mirror_rift:['CwpTankerChargeImpact',943,823],
   it_boss_succubus_mirror_rift:['CwpSuccubusHeartBreaker',954,851],
   it_boss_innuit_mirror_rift:['CwpInnuitIceStorm',953,838],
   it_boss_ghost_buster_mirror_rift:['CwpGhostBusterMagitonChain',955,858],
   it_boss_swindler_mirror_rift:['CwpSwindlerMeteorStrike',951,832],
   it_mirror_ninja_leader_myth_rift_challenge:['CwpNinjaLeader',1071,1431],
   it_boss_uptown_lancer_girl_mirror_rift:['CwpUptownLancerGirl',973,857],
   it_mirror_twins_android_myth_rift_challenge:['CwpTwinsAndroid',1080,1437],
   it_boss_future_knight_mirror_rift:['CwpFutureKnight',977,898],
   it_boss_future_princess_mirror_tower:['CwpFuturePrincess',969,886]
  };
  const skill=skills[s.Name];
  if(!skill)return '';
  const [action,id,style]=skill;
  const manaCosts={936:[85,0],943:[70,0],954:[70,0],953:[123,3],955:[94,1],951:[132,2],1071:[90,3],973:[75,0.25],1080:[100,4],977:[70,1.25],969:[135,0]};
  const [base,add]=manaCosts[id];
  const seconds=value=>new Intl.NumberFormat('de-DE',{maximumFractionDigits:3}).format(value);
  const cooldown=add?`${seconds(base/10)} − ${seconds(add/10)} × L`:seconds(base/10);
  const label=action.replace(/^Cwp/,'').replace(/([a-z])([A-Z])/g,'$1 $2');
  return `<section class="enemy-special-effect"><h4>Special effect · Weapon skill</h4><p><strong>${esc(label)}</strong><br>Theoretical cooldown: ${cooldown} s</p>${add?'<p class="fine">L = internal skill level (unknown), not monster level or floor.</p>':''}<p class="fine">Assumes 10 mana/s without modifiers. Actual cast intervals are not verified.</p><details><summary>Parameters & source</summary><p class="fine">Recharge estimate = (ManaCostBase − ManaCostAdd × L) / 10. ManaCostBase: ${seconds(base)} · ManaCostAdd: ${seconds(add)}. Assumes recovery is active and ManaRegenScale = 1; AI, animations and interruptions may delay casting. No value is assumed for L${add?'':'; this skill’s cost does not depend on L'}.</p><p class="fine">Action: ${esc(action)}. Assigned directly by this Infinity Tower enemy’s battle style. Activation has been reported in game. UseSuper is not used to hide this skill.</p><p><a href="${link('static-battleactions',id)}">Weapon skill action →</a> · <a href="${link('static-battlestyles',style)}">Enemy battle style →</a> · <a href="research.html?section=code&entry=1196&method=11773#code">Base mana recovery →</a> · <a href="research.html?section=code&entry=2660&method=28869#code">Mana recovery calculation →</a></p></details></section>`;
 }
 function roleSpecialEffectMarkup(s){
  const roleEffects={
   it_boss_future_princess_mirror_tower:{title:'Taunt & ally defense boost',cooldown:10,description:'Taunts nearby opponents and grants nearby living allies +30% DEF for 5 seconds.',details:'Radius: 3.3 game units. Adds threat equal to the caster’s DPS × 2.8 once per eligible opponent. The script applies the defense buff to friendly targets in range; whether this search includes the caster has not been confirmed. The 5-second duration belongs to the defense buff, not the taunt.',action:113,buff:330362,style:886},
   it_tanker_mirror_rift:{title:'Taunt',cooldown:6,description:'Generates threat around the caster.',details:'RoundAggro:Tanker parameters: AggroRadius = 3.3 game units; AggroMultiplier = 2; Cooltime = 6. These are configured parameters, not a verified fixed-duration forced target effect.',action:24,style:821},
   it_boss_tanker_mirror_rift:{title:'Taunt',cooldown:6,description:'Generates threat around the caster.',details:'RoundAggro:Tanker parameters: AggroRadius = 3.3 game units; AggroMultiplier = 2; Cooltime = 6. These are configured parameters, not a verified fixed-duration forced target effect.',action:24,style:823},
   it_mirror_boatracing_girl_myth_rift:{title:'Taunt & counter barrier',cooldown:7,description:'Generates threat on the selected target and activates a counter barrier.',details:'Adds threat equal to the caster’s DPS × 4 if a target is selected. Barrier buff: configured duration 0.7 seconds; BarrierBase = 1. This parameter is not an HP shield percentage. The script removes the buff when the action state ends; options may change the counter behavior.',action:433,buff:3305990,style:1394},
   it_mirror_demon_governor_myth_rift:{title:'Threat & self shield',cooldown:8,description:'Attacks opponents and gains a shield equal to 2.5% of its own max HP per application, up to 4 applications per activation (10% total).',details:'The script adds extra threat equal to caster DPS × (2 − 0.4) = caster DPS × 1.6, separately from damage. Shield applications depend on eligible targets hit; the 10% maximum is not guaranteed on every cast. ShieldRatio = 0.025; MaxShieldCount = 4. This shield is not added to displayed HP.',action:346,style:1410},
   it_boss_future_knight_mirror_rift:{title:'Self barrier',cooldown:7,description:'Applies a barrier to itself with a configured duration of 3 seconds.',details:'RoleFutureKnight applies buff_future_knight_role to the caster. BarrierBase = 1; this is not an HP shield percentage. This is a secondary role action, not the CwpFutureKnight weapon skill, and does not establish that skill’s cooldown.',action:138,buff:330389,style:898}
  };
  const effect=roleEffects[s.Name];
  if(effect)return `<section class="enemy-special-effect"><h4>Special effect · ${esc(effect.title)}</h4><p><strong>Configured cooldown: ${effect.cooldown} seconds</strong><br>${esc(effect.description)}</p><details><summary>Parameters & source</summary><p class="fine">${esc(effect.details)}</p><p class="fine">AI and combat conditions can delay activation. Temporary buffs are not included in the displayed HP / ATK / DEF.</p><p><a href="${link('static-battleactions',effect.action)}">Action parameters →</a>${effect.buff?` · <a href="${link('static-buffs',effect.buff)}">Buff parameters →</a>`:''} · <a href="${link('static-battlestyles',effect.style)}">Enemy battle style →</a></p></details></section>`;
  if(s.Name==='it_robot_tanker_mirror_rift')return `<section class="enemy-special-effect"><h4>Special effect · Taunt & defense boost</h4><p><strong>Taunt nearby opponents · Cooldown: 6 seconds</strong><br>Grants itself +50% DEF for 3 seconds.</p><details><summary>Parameters & source</summary><p class="fine">Taunt radius: 3.15 game units · Action duration: 0.4 seconds. Adds threat equal to the caster’s DPS × 2.8 once per eligible target per activation; this is not damage or a fixed-duration forced target effect.</p><p class="fine">The 6-second cooldown is the configured value; AI and combat conditions can delay activation. The 3-second duration applies to the defense buff. This temporary buff is not included in the displayed DEF.</p><p><a href="${link('static-battleactions',99)}">RoleTacticalShield:RobotTanker →</a> · <a href="${link('static-buffs',330353)}">Defense buff 330353 →</a> · <a href="${link('static-battlestyles',891)}">Mirror Robot Tanker battle style →</a></p></details></section>`;
  if(!['it_cw_passage_saul_debuff_poi','it_debuff_poi'].includes(s.Name))return '';
  return `<section class="enemy-special-effect"><h4>Special effect · Poison</h4><p>Periodic damage · 10 seconds · every 2 seconds (5 ticks).</p><details><summary>Parameters & source</summary><p class="fine">Preparation: 12 seconds. Applied buff level: 30. Damage type: Dps. Exact damage per tick is not verified.</p><p class="fine">DamageBase: 0 · DamageAdd: 0.02 · Action AtkModifierBase: 0.3. These are source parameters, not a percentage of the target’s HP.</p><p><a href="${link('static-battleactions',1291)}">WholeTargeting:poi →</a> · <a href="${link('static-buffs',55002)}">Poison buff 55002 →</a> · <a href="${link('static-battlestyles',784)}">Tower battle style →</a></p></details></section>`;
 }
 function healingMarkup(s,f,m){
  if(s.Name==='it_maiden_mirror_rift'){
   const weapon=equipment.items[s.DefaultWeapon1],level=f.StandardLevel;
   if(!weapon||!Number.isInteger(level)||level<0||![weapon.Recovery,weapon.StatGrowthRate,s.Recovery].every(Number.isFinite)||weapon.StatGrowthRate<=0)return '';
   // Recovery-based working model matches the reported 67,606 heal on floor 800.
   const amount=Math.trunc(weapon.Recovery*Math.pow(weapon.StatGrowthRate,level)*s.Recovery);
return `<section class="enemy-special-effect enemy-healing"><h4>Special effect · Healing</h4><p><strong>Area heal: ${statNumber(amount)} HP per recipient</strong><br>Recovery-based healing for allies in range, including itself; not a percentage of recipient HP.</p><p class="fine">Debuff cleanse · Configured cooldown: 5 s · Base uses: 6.</p><details><summary>Calculation & source</summary><p class="fine">Working model: trunc(weapon Recovery × weapon growth^StandardLevel × caster Recovery). ${num(weapon.Recovery)} × ${num(weapon.StatGrowthRate)}^${level} × ${num(s.Recovery)}. No elite HP multiplier or item level-scale factor is applied. Healing modifiers, missing HP and combat rounding may affect the result.</p><p class="fine">RoundHeal:Maiden: HealMultiplier = 1, CureOnHeal = true, Cooltime = 5, UseCount = 6. AI timing and active options may change casting intervals or available uses. No unconfirmed shield effect is included.</p><a href="${link('static-battleactions',19)}">RoundHeal:Maiden →</a> · <a href="${link('static-battlestyles',845)}">Tower battle style →</a> · <a href="${link('static-items',s.DefaultWeapon1)}">Recovery source →</a></details></section>`;
  }
  if(['healer_default','healer_archer'].includes(s.Class)){
   // Caster-based healing excludes elite HP bonuses (Saul comparison on floor 1317).
   const stats=scaledStats(s,f,[]);
   if(!stats)return '';
   const longRest=s.Class==='healer_archer',actionId=longRest?1200:1197,styleId=longRest?738:735;
   const amount=statNumber(Math.floor(stats.hp*0.8));
   return `<section class="enemy-special-effect enemy-healing"><h4>Special effect · Healing</h4><p><strong>Ally heal: ${amount} HP per recipient</strong><br>80% of the healer’s level-scaled HP before elite bonuses. The base amount is the same for each recipient, regardless of their max HP.</p><details><summary>Calculation & source</summary><p class="fine">Base heal = floor(healer HP before elite bonuses × 0.8). Elite HP multipliers do not increase this amount. Supported by the normal/elite Saul comparison on floor 1317; applied as a shared rule to these healer classes. Combat rounding may differ.</p><p class="fine">Preparation: 2 seconds · RestTime: ${longRest?5:0.5} · HealDistance: 2.75 · HealModifierBase: 0.8.</p><a href="${link('static-battleactions',actionId)}">${longRest?'MonsterHealNew:LongRest':'MonsterHealNew'} →</a> · <a href="${link('static-battlestyles',styleId)}">Healer battle style →</a></details></section>`;
  }
  if(s.Name!=='it_mirror_kamael_myth_rift')return '';
  const own=scaledStats(s,f,m.Options||[]);
  if(!own)return '';
  const heal=(hp,ratio)=>statNumber(Math.floor(hp*ratio));
  const targets=f.Monsters.map(target=>{
   const enemy=db.enemies[target.MonsterId];
   const stats=scaledStats(enemy.spec,f,target.Options||[]);
   return stats?`<li><span>P${target.Position} · ${esc(enemy.name)}</span><strong>${heal(stats.hp,0.06)} HP</strong></li>`:'';
  }).join('');
  return `<section class="enemy-special-effect enemy-healing"><h4>Special effect · Healing</h4><p><strong>Normal attack · Self: ${heal(own.hp,0.04)} HP</strong><br>4% of Kamael’s max HP per healing application.</p><p><strong>Finisher · Party heal</strong><br>6% of each recipient’s own max HP, including Kamael.</p><details><summary>Healing per floor enemy</summary><ul class="healing-targets">${targets}</ul></details><details><summary>Calculation & source</summary><p class="fine">Normal: floor(Kamael max HP × 0.04). Finisher: floor(recipient max HP × 0.06). Uses this floor’s calculated HP, including assigned elite modifiers. Base healing before healing modifiers and missing-HP limits; combat rounding may differ. Listed enemies are potential recipients, not a guarantee that all are eligible at the moment of casting.</p><p class="fine">ManualKamael: HealRatio = 0.04; BreakHealRatio = 0.06. The script heals the owner during drain and uses each target’s max HP for the party finisher. Option-based HealMultiplier can modify these ratios.</p><a href="${link('static-battleactions',181)}">ManualKamael action →</a> · <a href="${link('static-battlestyles',1408)}">Mirror Kamael battle style →</a></details></section>`;
 }
 function show(f){
  current=f;$('#floor-view').hidden=false;$('#floor-number').value=$('#floor-list').value=f.Floor;
  showRecordRoom(f);
  $('#floor-title').textContent='Floor '+num(f.Floor);$('#floor-meta').textContent=`${f.FloorType} · Monster level ${f.StandardLevel+1}`;
  document.title=`Orbital Lift · Floor ${f.Floor} · Guardian Atlas`;history.replaceState(null,'',location.pathname+'?floor='+f.Floor);
  $('#previous').disabled=filtered.indexOf(f)<=0;$('#next').disabled=filtered.indexOf(f)>=filtered.length-1;
  const slots=new Map(Array.from({length:20},(_,i)=>[i+1,[]]));
  f.Monsters.forEach((m,i)=>{if(!slots.has(m.Position))slots.set(m.Position,[]);slots.get(m.Position).push({m,i});});
  $('#formation').innerHTML=[...slots].sort((a,b)=>a[0]-b[0]).map(([p,entries])=>`<div class="position-cell"><span class="slot-label">P${p}</span>${entries.length?`<div class="slot-enemies" style="--occupants:${entries.length}">${entries.map(({m,i})=>{const e=db.enemies[m.MonsterId];return `<button class="tile ${m.Options?.length?'option':''}" data-enemy="${i}" aria-label="Position ${p}: ${esc(e.name)}" title="${esc(e.name)}">${picture(e.image,e.name)}${m.Options?.length?'<span class="option-marker">★</span>':''}</button>`;}).join('')}</div>`:'<span class="empty-marker">◇</span>'}</div>`).join('');
  $('#formation-count').textContent=`${f.Monsters.length} of ${f.Monsters.length} enemies shown · select a portrait for details`;
  $('#enemies').innerHTML=f.Monsters.map((m,i)=>{const e=db.enemies[m.MonsterId],s=e.spec;return `<article class="enemy" id="enemy-${i}" data-enemy="${i}"><header class="enemy-header">${picture(e.image,e.name)}<div><h3>${esc(e.name)}</h3><p class="position">Position ${m.Position} · ${esc(s.ElementalType||'Unknown')} · ${esc(e.tower.Class)} / ${esc(e.tower.CoopClass)}</p><p class="fine">${esc(s.Name)} · Spec ${e.tower.SpecId}</p></div></header><div class="enemy-body">${statsMarkup(s,f,m)}<p>Source base HP ${num(s.Hp)} · ATK ${num(s.Atk)} · DEF ${num(s.Def)} · Mass ${num(s.Mass)}</p>${weaponMarkup(s,f)}${specialEffectMarkup(s)}${healingMarkup(s,f,m)}${debuffMarkup(s)}${(m.Options||[]).map(o=>{const op=db.options[o.OptionId]||{};return `<details><summary class="tag">Stage option: ${esc(String(op.Name||o.OptionId).replaceAll('_',' '))} · Lv ${o.Level}</summary><pre>${esc(JSON.stringify(op,null,2))}</pre><a href="${link('static-options',o.OptionId)}">Option source →</a></details>`;}).join('')}<a href="${link('monsters',e.tower.SpecId)}">Enemy record →</a></div></article>`;}).join('')||`<p class="floor-data">No enemies are assigned in the source record for this ${esc(f.FloorType)} floor.</p>`;
  $('#rewards').innerHTML=(f.Rewards||[]).map(r=>{const it=db.items[r.ItemId],name=it?.media?.name||it?.record?.Name||'Item '+r.ItemId;return `<a class="reward" href="${link('static-items',r.ItemId)}">${it?.media?.image?picture(it.media.image,''):''}${num(r.Amount)} × ${esc(name)}</a>`;}).join('')||'No reward stored.';
  $('#raw-floor').textContent=JSON.stringify(f,null,2);$('#source-floor').href=link('static-infinitytowerfloors',f.Id);
  $('#floor-view').querySelectorAll('img').forEach(img=>img.onerror=()=>{const fallback=document.createElement('span');fallback.className='image-fallback';fallback.textContent=img.alt||'Image unavailable';img.replaceWith(fallback);});
 }
 function filter(){const q=$('#enemy-search').value.trim().toLowerCase(),type=$('#floor-type').value,elite=$('#enemy-elite').value;filtered=db.floors.filter(f=>(!type||f.FloorType===type)&&((!q&&!elite)||f.Monsters.some(m=>{const e=db.enemies[m.MonsterId];const isElite=(m.Options||[]).some(o=>String(db.options[o.OptionId]?.Name||'').startsWith('elite_'));return `${e.name} ${e.spec.Name}`.toLowerCase().includes(q)&&(!elite||(elite==='elite'?isElite:!isElite));})));$('#status').textContent=`${num(filtered.length)} matching floors · ${num(db.floors.length)} stored floors`;$('#floor-list').innerHTML=filtered.map(f=>`<option value="${f.Floor}">Floor ${f.Floor} · ${esc(f.FloorType)}</option>`).join('');$('#floor-view').hidden=!filtered.length;$('#previous').disabled=$('#next').disabled=!filtered.length;if(filtered.length)show(filtered.includes(current)?current:filtered[0]);}
 try{
  const response=await fetch('data/orbital-lift.json');if(!response.ok)throw Error('Floor data unavailable');db=await response.json();
  try{const response=await fetch('data/record-room-texts.json?v=complete-records-1',{cache:'no-cache'});if(!response.ok)throw Error('Record data unavailable');roomData=await response.json();}catch(e){roomError=true;}
  try{const response=await fetch('data/orbital-weapons.json');if(!response.ok)throw Error('Weapon data unavailable');equipment=await response.json();}catch(e){equipmentError=true;}
  try{const response=await fetch('data/orbital-debuffs.json?v=exorcist-mark-1');if(!response.ok)throw Error('Debuff data unavailable');debuffData=await response.json();}catch(e){debuffError=true;}
  $('#floor-number').max=Math.max(...db.floors.map(f=>f.Floor));$('#floor-type').innerHTML+=[...new Set(db.floors.map(f=>f.FloorType))].map(t=>`<option>${esc(t)}</option>`).join('');
  current=db.floors.find(f=>f.Floor===Number(new URLSearchParams(location.search).get('floor')||1325))||db.floors[0];filter();
  $('#enemy-elite').onchange=$('#floor-type').onchange=$('#enemy-search').oninput=filter;
  $('#floor-controls').onsubmit=e=>{e.preventDefault();const f=db.floors.find(f=>f.Floor===Number($('#floor-number').value));if(!f){$('#status').textContent='This floor is not present in the data.';return;}current=f;$('#enemy-elite').value=$('#floor-type').value=$('#enemy-search').value='';filter();};
  $('#floor-list').onchange=()=>show(filtered.find(f=>f.Floor===Number($('#floor-list').value)));
  $('#previous').onclick=()=>show(filtered[filtered.indexOf(current)-1]);$('#next').onclick=()=>show(filtered[filtered.indexOf(current)+1]);
  $('#floor-view').onclick=e=>{const t=e.target.closest('button[data-enemy]');if(!t)return;document.querySelectorAll('[data-enemy]').forEach(el=>el.classList.toggle('selected',el.dataset.enemy===t.dataset.enemy));$('#enemy-'+t.dataset.enemy)?.scrollIntoView({behavior:'smooth',block:'nearest'});};
  $('#download').onclick=()=>{const url=URL.createObjectURL(new Blob([JSON.stringify({floor:current,enemies:current.Monsters.map(m=>({...m,...db.enemies[m.MonsterId],scaledStats:scaledStats(db.enemies[m.MonsterId].spec,current,m.Options||[])}))},null,2)],{type:'application/json'})),a=document.createElement('a');a.href=url;a.download=`orbital-lift-floor-${current.Floor}.json`;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);};
  window.addEventListener('popstate',()=>{const f=db.floors.find(f=>f.Floor===Number(new URLSearchParams(location.search).get('floor')));if(f){current=f;$('#enemy-elite').value=$('#floor-type').value=$('#enemy-search').value='';filter();}});
 }catch(e){$('#status').textContent='Could not load Orbital Lift: '+e.message;}
})();
