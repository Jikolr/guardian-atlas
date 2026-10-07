
from pathlib import Path
import json,gzip,base64,shutil,html,collections
B=Path.cwd();D=B/'dist/data';O=B.parent/'guardian-analysis/exports/name-association-review';O.mkdir(parents=True,exist_ok=True);(O/'images').mkdir(exist_ok=True)
profiles=json.loads(gzip.decompress((D/'characters.json.gz').read_bytes()))
texts={r['id']:r['fields']['Text'] for r in json.loads(gzip.decompress((D/'text.json.gz').read_bytes()))}
# Analyst proposals: biographies provide supporting clues, not decoded localization joins.
raw="""invader_knight|Beth|1548
party_mad_panda|Mad Panda Trio|1597
lifeguard_yuze|Lifeguard Yuze|1567
future_knight|Future Knight|1556
uptown_lancer_girl|Lapice|1497
fire_bishop|Vishuvac|1537
rudolph|Rue|1550
librarian|Lahn|1533
surfer_sohee|Beach Sohee|1566
bakeneko|Mikke|1626
magical_girl|Haruka / Serena|1676
summer_rie|Beach Cleanup Hitter Rie|1666
first_bishop|Kahlor|1672
bridge_driver|V|1702
fire_harpy|Scintilla|1570
vampire_captain|Valencia|1599
kunoichi|Sumire|1602
demon_engineer|Vinette|1625
summer_shapira|Summer Shapira|1623
captain_rabbit|Carol|1582
desertelf_hunter|Rosetta|1609
exorcist_girl|Saya|1645
ms_chrome|Miss Chrom|1598
plague_doctor|Plague Doctor|1632
sheep_girl|Rey|1593
demon_operator|Crosselle|1600
guardian_angel|Angie|1631
demon_inspector|Odile|1629
wrestler|Callie|1662
idol_captain|Idol Captain Eva|1528
summer_loraine|Summer Loraine|1596
demon_ceo|Lilith|1563
white_druid|Kanna|1580
future_princess|Future Princess|1544
summer_amy|Summer Amy|1620
summer_android|AA72|1594
whiteday_girgas|White Day Girgas|1659
eternal_flame|Illuni|1674
mercenary|Orca|1578
ninja_leader|Natsume|1648
villain_android|Mk.2|1576
vampire|Karina|1477
demon_governor|Morrian|1624
demon_powergirl|Pymon|1603
hero_ai|H.E.R.O.S KAI|1616
sea_witch|Ara|1592
second_bishop|Lacrima|1692
festival_girl|Miya|1543
jade_shaman|Tasha|1653
half_vampire|Priscilla|1590
valentine_ameris|Valentine Ameris|1654
vampire_lord|Claude|1591
battleball_pitcher|Randi|1668
golem_rider|Alef|1542
flower_girl|Bari|1531
lady_thief|Lucy|1564
saintess|Clara|1583
adela_noble|Daisy|1655
white_beast|White Snow|1610
villain_redhood|Arabelle|1526
steam_princess|Aisha|1496
witch_coco|Lupina|1532
fallen_queen|Camilla / 1st Corps Commander|1614
priestess|Veronica|1557
cyborg_monk|Chun Ryeo|1617
nelluru|Nell|1686
slime_rimuru|Rimuru Tempest|1634
dokkaebi|Eunha|1621
sunyeo|Dabin|1642
succubus|Yuze|1494
slime_milim|Milim Nava|1635
boatracing_girl|Summer Rachel|1644
watcher|Yuna|1633
redhood|Elvira|1475
tanker|Craig|1491
gourry|Gourry Gabriev|1588
soulpower_girl|Dohwa|1649
slime_shuna|Shuna|1636
goat_girl|Toga|1639
steam_knight|Shapira|1498
dragon_daughter|Ameris|1618
milkyway_girl|Lena|1641
viking|Neva|1551
ghost_buster|Sohee|1487
blue_dragon|Yun|1637
mermaid|Sia|1619
pixy_girl|Cornet|1640
desert_slave|Marvin|1490
xellos|Xellos|1589
teatan_hero|Marianne|1486
knightcaptain|Eva|1474
innuit|Coco|1485
lina|Lina Inverse|1585
dragon_boy|Girgas|1501
demon_brother|Favi|1480
demon_sister|Lavi|1479
survivor|Catherine|1502
doll_girl|Ranpang|1493
maiden|Loraine|1478
mad_scientist|Gremory|1482"""
proposals={a:(b,int(c)) for a,b,c in (s.split('|') for s in raw.splitlines())}
rows=[]
for p in profiles:
 key=p['internal'];name=p['name'];bid=p.get('biographyId');evidence=p.get('evidence') or '';status='Existing association' if name else 'Unresolved'
 if key in proposals and not name:
  name,bid=proposals[key];status='Proposed · needs confirmation';evidence='Semantic comparison of the internal class/profile and the English biography; no localization-key join has been decoded.'
 if key=='invader_knight':status='User-confirmed';evidence='Confirmed by the user: invader_knight = Beth. Biography supports the Invader identity.'
 if p['status']=='Confirmed':status='Previously confirmed'
 if key=='magical_girl':status='Ambiguous';evidence='Two biographies describe magical girls: Haruka #1676 and Serena #1698. The shared class alone cannot identify each variant. Do not apply one name to the entire family.'
 if key=='teatan_hero' and p['id']==381:name='Marty Junior';bid=1552;status='Proposed · needs confirmation';evidence='Same internal class as Marianne, but separate origin 381. Biography #1552 identifies Marty Junior. Needs portrait confirmation.'
 if key=='china':name='Fei / Mei';bid=1488;status='Ambiguous';evidence='Shared class china. Biographies #1488 (Fei) and #1489 (Mei) are separate. Confirm each origin from its portrait.'
 if not name:evidence='No sufficiently supported candidate selected. The portrait is included so the reviewer can suggest a name.'
 if p['status']=='Confirmed' and not evidence:evidence=p['evidence']
 rows.append(dict(key='hero:'+str(p['id']),kind='Hero / character',id=p['id'],internal=key,name=name,status=status,evidence=evidence,biographyId=bid,quote=texts.get(bid,'')[:650],source='heroes.json → OriginId '+str(p['id'])+'; static-heroprofile.json; text.json.gz',image=p.get('image'),variants=[dict(id=v['id'],name=v['fields'].get('Name'),portrait=v['fields'].get('PortraitAssetName')) for v in p['variants']]))
bosses=json.loads((D/'raid-simulator.json').read_text(encoding='utf8'))['bosses']
names={'boss_mech':'Mad Panda','boss_demon':'Demon','boss_wolf':'Gast','boss_fox':'Garam','shadow_beast':'Shadow Beast','boss_harvester':'Harvester','monster_boss_admiral_s3_new_guild':'Marina','minotaurs':'Minotaur','boss_graboid':'Sandmonster','erina':'Erina','boss_sapa':'Viper Clan Leader','boss_snowman_general':'Snowman General','boss_portrait_raid':'Cursed Kamazone Director','boss_robot_knight':'Raid Robot','boss_evil_fairy':'Fairy','boss_lava_slime_king':'Lava Slime King','monster_boss_invader_director_guild':'Invader Director','boss_invader':'Invader Commander','monster_boss_invader_terrorist_fury_guild_v2':'Invader Terrorist','boss_minister':'Minister','boss_magwi_enhanced_guild':'Magwi','monster_boss_carmen_enhanced_guild':'Carmen','arachne_guild':'Arachne'}
groups=collections.defaultdict(list)
for b in bosses:groups[b.get('VisualName') or b['Class']].append(b)
for k,bs in groups.items():
 b=bs[0]
 rows.append(dict(key='boss:'+str(b['Id']),kind='Raid boss',id=b['Id'],internal=k,name=names.get(k,''),status='Boss label · needs confirmation',evidence='Candidate label based on the internal visual/class name and earlier boss research. Exact English display label has not been joined to localization. Grouped elemental variants share this visual key.',biographyId=None,quote='',source='raid-simulator.json → bosses (derived catalog); monsters.json #'+str(b['Id']),image=b.get('image'),variants=[dict(id=x['Id'],name=x['Name'],className=x['Class'],element=x.get('ElementalType')) for x in bs]))
missing=[]
for r in rows:
 p=D/'visual'/str(r['image'])
 if r['image'] and p.is_file():
  dest=O/'images'/p.name;shutil.copyfile(p,dest);r['imageFile']='images/'+p.name;r['imageData']='data:image/webp;base64,'+base64.b64encode(p.read_bytes()).decode()
 else:r['imageFile']=None;r['imageData']=None;missing.append(r['key'])
rows.sort(key=lambda r:(not bool(r['name']),r['kind'],r['name'].lower(),r['id']))
public=[{k:v for k,v in r.items() if k!='imageData'} for r in rows]
(O/'associations.json').write_text(json.dumps(public,ensure_ascii=False,indent=2),encoding='utf-8')
counts=dict(entries=len(rows),named=sum(bool(r['name']) for r in rows),unresolved=sum(not r['name'] for r in rows),bossFamilies=len(groups),missingImages=missing)
(O/'summary.json').write_text(json.dumps(counts,indent=2),encoding='utf-8')
md=['# Name association review — Guardian Atlas','Date: 2026-10-06. Data snapshot: 3.55.0.','This is a review report, not an update to the live aliases. No complete localization-key mapping has been decoded. Hero candidates use internal identities and biography clues; boss labels are proposals. Confirm each portrait and correct the name if needed.','Scope: all '+str(len(profiles))+' existing character profiles and '+str(len(groups))+' raid-boss visual families; not every NPC/enemy in the game.','Review decisions in report.html remain in your browser until you export them. The HTML embeds the images and works offline.','']
for r in rows:
 md+=['## '+(r['name'] or 'Name unknown')+' — '+r['key'],'Internal: `'+r['internal']+'` | Status: '+r['status']]
 if r['imageFile']:md+=['![Portrait]('+r['imageFile']+')']
 else:md+=['No linked portrait available.']
 md+=[r['evidence'],'Sources: '+r['source']]
 if r['quote']:md+=['English text #'+str(r['biographyId'])+': '+r['quote']]
 md+=['']
(O/'REPORT.md').write_text('\n\n'.join(md),encoding='utf-8')
payload=json.dumps(rows,ensure_ascii=False).replace('<','\\u003c')
template="""<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Name association review · Guardian Atlas</title><style>*{box-sizing:border-box}body{background:#0b1420;color:#eaf1fb;font:16px/1.6 system-ui;margin:0;padding:28px}main{max-width:1250px;margin:auto}h1{color:#ffcf63}p{max-width:95ch}button,select,input{font:inherit;padding:10px;background:#182a3c;color:#eef4ff;border:1px solid #63778a;border-radius:6px}button{cursor:pointer}a{color:#ffcf63}.toolbar{display:flex;gap:12px;flex-wrap:wrap;position:sticky;top:0;background:#0b1420;padding:12px 0;z-index:2}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:20px}.card{background:#142234;border:1px solid #35495e;border-radius:12px;padding:20px;overflow-wrap:anywhere}.portrait{width:100%;height:190px;object-fit:contain;background:#0a1320;border-radius:8px}.badge{color:#ffcf63;font-size:13px}h2{font-size:23px;line-height:1.25}code{color:#a7d4ff}blockquote{margin:12px 0;padding-left:12px;border-left:2px solid #63778a;font-size:13px;color:#b9cde0}.review{display:grid;gap:8px}.review label{font-size:13px}.review input,.review select{width:100%}summary{cursor:pointer}pre{white-space:pre-wrap;font-size:12px}.notice{border-left:3px solid #ffcf63;padding:15px;background:#182a3c}@media(max-width:450px){body{padding:14px}.grid{grid-template-columns:1fr}}@media print{.toolbar,.review{display:none}.card{break-inside:avoid}.grid{display:block}}</style><main><h1>Who is behind the internal name?</h1><p>Illustrated review · 6 October 2026 · game data 3.55.0</p><p class="notice">These are proposals for visual confirmation, not newly verified aliases. Biographies support many matches, but the localization-key link remains undecoded. Several origins share one class name: confirm origins separately. Boss labels may be approximate. Unresolved profiles are included without inventing a name.</p><p>Choose Confirm / Reject / Correct, add the correct name if needed, then <strong>Export decisions</strong> and send the JSON back. Choices save only in this browser; they do not modify the website. This standalone report includes its pictures and works offline.</p><div class="toolbar"><input id="q" type="search" aria-label="Search names" placeholder="Beth, invader_knight…"><select id="scope" aria-label="Filter"><option value="all">All entries</option><option value="hero">Characters</option><option value="boss">Raid bosses</option><option value="unknown">Unknown names</option><option value="pending">Not reviewed</option></select><button id="export">Export decisions</button><button id="print">Print / PDF</button></div><p id="status" role="status"></p><div id="grid" class="grid"></div></main><script id="dataset" type="application/json">PAYLOAD</script><script>
const rows=JSON.parse(document.getElementById('dataset').textContent),key='atlas-name-review-355-v1';let decisions={};try{decisions=JSON.parse(localStorage.getItem(key)||'{}')}catch{}
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const grid=document.getElementById('grid'),status=document.getElementById('status');
function render(){const q=document.getElementById('q').value.toLowerCase().replaceAll('_',' '),scope=document.getElementById('scope').value;const selected=rows.filter(r=>(r.name+' '+r.internal+' '+r.id).toLowerCase().replaceAll('_',' ').includes(q)&&(scope==='all'||scope==='hero'&&r.kind!=='Raid boss'||scope==='boss'&&r.kind==='Raid boss'||scope==='unknown'&&!r.name||scope==='pending'&&!decisions[r.key]?.decision));status.textContent=selected.length+' entries shown / '+rows.length+' · '+Object.values(decisions).filter(d=>d.decision).length+' reviewed';grid.innerHTML=selected.map(r=>{const d=decisions[r.key]||{};return '<article class="card" data-key="'+r.key+'">'+(r.imageData?'<img class="portrait" src="'+r.imageData+'" loading="lazy" alt="Portrait for '+esc(r.internal)+'">':'<p class="portrait">No linked portrait available</p>')+'<p class="badge">'+esc(r.status)+'</p><h2>'+esc(r.name||'Name unknown')+'</h2><code>'+esc(r.internal)+'</code><p>'+esc(r.kind)+' · #'+r.id+'</p><p>'+esc(r.evidence)+'</p>'+(r.quote?'<details><summary>Biography evidence #'+r.biographyId+'</summary><blockquote>'+esc(r.quote)+'</blockquote></details>':'')+'<details><summary>Sources and variants ('+r.variants.length+')</summary><p>'+esc(r.source)+'</p><pre>'+esc(JSON.stringify(r.variants,null,2))+'</pre></details><div class="review"><label>Your decision<select data-field="decision">'+[['','Not reviewed'],['confirm','Confirm'],['reject','Reject'],['correct','Correct / suggest name']].map(([v,l])=>'<option value="'+v+'"'+(d.decision===v?' selected':'')+'>'+l+'</option>').join('')+'</select></label><label>Correct name / note<input data-field="note" value="'+esc(d.note||'')+'"></label></div></article>'}).join('')}
grid.addEventListener('change',e=>{const field=e.target.dataset.field;if(!field)return;const id=e.target.closest('[data-key]').dataset.key;decisions[id]={...decisions[id],[field]:e.target.value};try{localStorage.setItem(key,JSON.stringify(decisions))}catch{status.textContent='Browser storage unavailable. Export before closing.'}});
document.getElementById('q').oninput=render;document.getElementById('scope').onchange=render;document.getElementById('print').onclick=()=>print();document.getElementById('export').onclick=()=>{const blob=new Blob([JSON.stringify({version:1,snapshot:'3.55.0',decisions:rows.filter(r=>decisions[r.key]).map(r=>({key:r.key,internal:r.internal,proposedName:r.name,...decisions[r.key]}))},null,2)],{type:'application/json'});const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download='name-review-decisions.json';a.click();setTimeout(()=>URL.revokeObjectURL(a.href),1000)};render();
</script></html>"""
report=template.replace('PAYLOAD',payload)
(O/'report.html').write_text(report,encoding='utf-8');(B/'dist/name-review.html').write_text(report,encoding='utf-8')
print(json.dumps(counts));print('Report:',O/'report.html')

