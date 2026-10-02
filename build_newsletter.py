"""Render the local editorial archive. Add an entry and HTML body in newsletter/ to publish another post."""
from pathlib import Path
from html import escape
import json,re,math,shutil
B=Path(__file__).resolve().parent;W=B/'dist';D=W/'data';S=B/'newsletter'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def write(p,v):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,ensure_ascii=False,separators=(',',':')),encoding='utf8')
posts=read(S/'posts.json');media=read(D/'visual/record-media.json')
astoria='data/visual/'+media['heroes:701']['image'];seira='data/visual/'+media['heroes:695']['image']
def page(title,description,body):return f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="description" content="{escape(description,quote=True)}"><title>{escape(title)} · Guardian Atlas</title><link rel="stylesheet" href="newsletter.css"><link rel="stylesheet" href="site-nav.css"><script src="site-nav.js" defer></script></head><body><a class="skip-link" href="#main-content">Skip to content</a><main id="main-content">{body}</main></body></html>'''
for i,p in enumerate(posts):
    body=(S/p['body']).read_text(encoding='utf8').replace('{{astoria_image}}',astoria).replace('{{seira_image}}',seira)
    headings=re.findall(r'<h2 id="([^"]+)">([^<]+)</h2>',body)
    words=len(re.sub('<[^>]+>',' ',body).split());p['minutes']=math.ceil(words/220)
    other=posts[1-i] if len(posts)==2 else None
    footer=f'<aside class="next-post"><span>Keep reading</span><a href="newsletter-{other["slug"]}.html">{escape(other["title"])} →</a><p>{escape(other["summary"])}</p></aside>' if other else ''
    header=f'''<a class="back" href="newsletter.html">← All posts</a><header class="article-heading"><p class="eyebrow">NEWSLETTER / {escape(p['category'].upper())}</p><h1>{escape(p['title'])}</h1><p class="post-meta"><time datetime="{p['date']}">2 October 2026</time><span>·</span>{p['minutes']} min read<span>·</span>Guardian Atlas</p></header>'''
    toc='<aside class="article-toc" aria-label="On this page"><h2>On this page</h2><nav>'+''.join(f'<a href="#{ident}">{escape(title)}</a>' for ident,title in headings)+'</nav><button type="button" onclick="window.print()">Print / save as PDF</button></aside>'
    html=page(p['title'],p['summary'],header+'<div class="article-layout">'+toc+'<article class="article-body">'+body+footer+'</article></div>')
    (W/f'newsletter-{p["slug"]}.html').write_text(html,encoding='utf8')
cards=[]
for i,p in enumerate(posts):
    art=f'<div class="post-art portrait-art"><img src="{astoria}" width="100" height="100" alt="Astoria"><span>3.55</span></div>' if p['image']=='astoria' else '<div class="post-art code-art" aria-hidden="true"><span class="code-line">controller = …</span><strong>785</strong><span>more Lua paths to explore</span></div>'
    cards.append(f'''<a class="post-card" href="newsletter-{p['slug']}.html">{art}<div class="post-card-body"><p class="eyebrow">{escape(p['category'])} <span>· 02 OCT 2026</span></p><h2>{escape(p['title'])}</h2><p>{escape(p['summary'])}</p><span class="read-link">Read article <span aria-hidden="true">↗</span><small>{p['minutes']} min read</small></span></div></a>''')
listing='<header class="newsletter-heading"><p class="eyebrow">THE GUARDIAN ATLAS JOURNAL</p><h1>Newsletter</h1><p>Inside the game files.<br>Behind the website updates.</p><div class="edition-label">Game analysis &amp; site news · 2 posts</div></header><section class="post-grid" aria-label="Latest posts">'+''.join(cards)+'</section><footer class="newsletter-footer">Independent analysis of recovered game data. Source links and interpretation limits are included in each article.</footer>'
(W/'newsletter.html').write_text(page('Newsletter','Game-file deep dives and updates from Guardian Atlas.',listing),encoding='utf8')
write(D/'newsletter.json',posts)

# Ship the supplied research as supporting material; it is never executed.
downloads=W/'downloads/newsletter';downloads.mkdir(parents=True,exist_ok=True)
for src in [B.parent/'guardian-update-review/REPORT_v355_explique.md',B.parent/'guardian-update-review/ANNEXE_LUA_v355.md',Path('C:/Users/alexandre.corbineau/Downloads/REPORT_v355.md'),Path('C:/Users/alexandre.corbineau/Downloads/Reports-update-3.55.0.md')]:
    shutil.copyfile(src,downloads/src.name)
run=B.parent/'guardian-update-review/outputs/20261002-144030-522b69'
changes=[json.loads(l) for l in (run/'changes.jsonl').read_text(encoding='utf8').splitlines()]
focus=[]
for c in changes:
    if c['path'] in ['install/files/static_data/battleactions','install/files/static_data/buffs','install/files/static_data/heroes','install/files/static_data/items','install/files/static_data/projectiles','install/files/static_data/seasondate']:
        focus.append({k:c[k] for k in ['path','before_sha256','after_sha256','field_changes']})
    if c['path']=='install/files/static_data/exps2':
        sections=[]
        for d in c['field_changes']:
            before={r['Level']:r for r in d['before']};after={r['Level']:r for r in d['after']};changed=[]
            for lv in before.keys()&after.keys():
                fields={k:{'before':before[lv].get(k),'after':after[lv].get(k)} for k in before[lv].keys()|after[lv].keys() if before[lv].get(k)!=after[lv].get(k)}
                if fields:changed.append({'level':lv,'fields':fields})
            assert len(changed)==151 and all(set(r['fields'])=={'ScarecrowTotalDmg'} for r in changed)
            sections.append({'section':d['path'],'changedLevels':sorted(changed,key=lambda r:r['level'])})
        focus.append({'path':c['path'],'sections':sections})
    if c['path']=='install/files/GameScript/base/battle_init.encrypted':focus.append({'path':c['path'],'diff':(run/c['text_diff']).read_text(encoding='utf8')})
write(downloads/'v355-evidence.json',{'comparisonRun':run.name,'scope':'Selected source differences supporting the newsletter; not a complete patch inventory.','changes':focus})

# Keep downloadable site catalogs accurate after the editorial/name updates.
catalog=read(D/'file-catalog.json');exports={r['path']:r for r in catalog['files'] if r['section']=='exports'}
for p in list(downloads.iterdir())+[D/'newsletter.json']:
    rel=p.relative_to(W).as_posix();exports[rel]={'section':'exports','path':rel,'url':rel,'bytes':p.stat().st_size,'kind':'Newsletter source / evidence'}
for r in catalog['files']:
    if r.get('url') and (W/r['url']).is_file():r['bytes']=(W/r['url']).stat().st_size
catalog['files']=[r for r in catalog['files'] if r['section']!='exports']+list(exports.values());write(D/'file-catalog.json',catalog)
print('Built',[(p['title'],p['minutes']) for p in posts])
