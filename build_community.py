"""Build Contacts and Raid videos; retain the last good YouTube feed offline."""
from pathlib import Path
from urllib.request import Request,urlopen
from urllib.parse import urlparse,parse_qs
from datetime import datetime,timezone
from html import escape as esc
import json,re,sys,xml.etree.ElementTree as ET
B=Path(__file__).resolve().parent;D=B/'dist';C=B/'community'
CHANNEL='UC8QGAiHxQWVmj8lWzeuFEYw'
FEED='https://www.youtube.com/feeds/videos.xml?channel_id='+CHANNEL
NS={'a':'http://www.w3.org/2005/Atom','yt':'http://www.youtube.com/xml/schemas/2015'}
def video_id(url):
 u=urlparse(url.strip());host=(u.hostname or '').lower()
 if u.scheme!='https' or u.username or u.password:raise ValueError('Use an HTTPS YouTube video URL')
 if host=='youtu.be':ident=u.path.strip('/')
 elif host in ('youtube.com','www.youtube.com','m.youtube.com'):
  parts=u.path.strip('/').split('/')
  ident=parse_qs(u.query).get('v',[''])[0] if u.path=='/watch' else parts[1] if len(parts)==2 and parts[0] in ('shorts','live','embed') else ''
 else:raise ValueError('Only YouTube video URLs are supported')
 if not re.fullmatch(r'[A-Za-z0-9_-]{11}',ident):raise ValueError('Invalid YouTube video ID')
 return ident
def parse_feed(raw):
 root=ET.fromstring(raw)
 if root.findtext('yt:channelId',namespaces=NS) not in (CHANNEL,CHANNEL[2:]):raise ValueError('Unexpected channel')
 rows=[]
 for e in root.findall('a:entry',NS):
  ident=video_id('https://youtu.be/'+e.findtext('yt:videoId',default='',namespaces=NS))
  rows.append({'id':ident,'title':e.findtext('a:title',default='',namespaces=NS),'date':e.findtext('a:published',default='',namespaces=NS)[:10],'creator':'Nihal','description':'','source':'channel','tags':[]})
 if not rows:raise ValueError('Empty feed')
 return sorted(rows,key=lambda v:v['date'],reverse=True)[:15]
def save(p,data):
 p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf8')
def refresh():
 cache=C/'youtube-cache.json'
 try:
  with urlopen(Request(FEED,headers={'User-Agent':'GuardianAtlas/1.0'}),timeout=20) as r:rows=parse_feed(r.read())
  result={'fetchedAt':datetime.now(timezone.utc).isoformat(),'feed':FEED,'videos':rows};save(cache,result)
 except Exception as e:
  print('YouTube refresh unavailable; retaining cached videos:',type(e).__name__,file=sys.stderr)
  result=json.loads(cache.read_text(encoding='utf8')) if cache.exists() else {'fetchedAt':None,'videos':[]}
 return result
def page(title,body):
 return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+esc(title)+' · Guardian Atlas</title><link rel="stylesheet" href="newsletter.css"><link rel="stylesheet" href="community.css"><link rel="stylesheet" href="site-nav.css"><script src="site-nav.js?v=20261007-downloads355" defer></script></head><body><a class="skip-link" href="#main-content">Skip to content</a><main id="main-content">'+body+'</main><script src="community.js" defer></script></body></html>'
def contact(p):
 if not re.fullmatch(r'[^\s<>@]+@[^\s<>@]+\.[^\s<>@]+',p['email']):raise ValueError('Invalid email')
 image=p['image']
 if not (image.startswith('uploads/') or image.startswith('https://')):raise ValueError('Invalid image')
 channel=p['channel'];u=urlparse(channel)
 if u.scheme!='https' or u.hostname not in ('www.youtube.com','youtube.com'):raise ValueError('Invalid channel URL')
 paragraphs=''.join('<p>'+esc(x)+'</p>' for x in p['bio'].split('\n\n') if x.strip())
 return page('Contacts',f'''<header class="community-heading"><p class="eyebrow">BEHIND GUARDIAN ATLAS</p><h1>Contacts</h1><p>Game files, raid runs, and a curiosity for how it all works.</p></header><section class="contact-layout"><div class="profile-art"><img src="{esc(image,quote=True)}" alt="Nihal's Lilith profile artwork" width="3508" height="3508"></div><div class="contact-copy"><h2>{esc(p['title'])}</h2>{paragraphs}<div class="contact-links"><div><span>Discord</span><strong id="discord-handle">{esc(p['discord'])}</strong><button id="copy-discord" type="button">Copy username</button></div><a href="mailto:{esc(p['email'],quote=True)}"><span>Email</span><strong>{esc(p['email'])}</strong><b aria-hidden="true">↗</b></a><a href="{esc(channel,quote=True)}" target="_blank" rel="noopener noreferrer"><span>YouTube</span><strong>Nihal · Guardian Tales</strong><b aria-hidden="true">↗</b></a></div><p id="copy-status" role="status"></p><p class="contact-note">Found something interesting, spotted an error, or have a raid idea to share? Get in touch.</p></div></section>''')
def card(v):
 ident=v['id'];label='FROM NIHAL' if v['source']=='channel' else 'COMMUNITY PICK'
 query=v['title']+' '+v['creator']+' '+(v.get('description') or '')+' '+' '.join((v.get('tags') or []))
 return f'''<article class="video-card" data-source="{v['source']}" data-search="{esc(query.lower(),quote=True)}"><div class="video-frame"><button class="play-video" data-video="{ident}" aria-label="Play {esc(v['title'],quote=True)}"><img src="https://i.ytimg.com/vi/{ident}/hqdefault.jpg" alt="" loading="lazy" width="480" height="360"><span class="play-symbol" aria-hidden="true">▶</span></button></div><div class="video-copy"><p class="eyebrow">{label}</p><h2>{esc(v['title'])}</h2><p class="video-meta">{esc(v['creator'])} · <time datetime="{esc(v['date'],quote=True)}">{esc(v['date'])}</time></p><p>{esc((v.get('description') or ''))}</p><a href="https://www.youtube.com/watch?v={ident}" target="_blank" rel="noopener noreferrer">Watch on YouTube ↗</a></div></article>'''
def main(offline=False):
 p=json.loads((C/'contact.json').read_text(encoding='utf8'));(D/'contacts.html').write_text(contact(p),encoding='utf8')
 cache=json.loads((C/'youtube-cache.json').read_text(encoding='utf8')) if offline else refresh()
 curated=[]
 for file in sorted((C/'videos').glob('*.json')):
  v=json.loads(file.read_text(encoding='utf8'))
  if not v.get('published',False):continue
  for field in ('title','creator','date'):
   if not isinstance(v.get(field),str) or not v[field].strip():raise ValueError(file.name+': missing '+field)
  datetime.strptime(v['date'],'%Y-%m-%d')
  curated.append({**v,'id':video_id(v['url']),'source':'curated'})
 ids=[v['id'] for v in curated]
 if len(ids)!=len(set(ids)):raise ValueError('Duplicate curated video')
 videos=sorted(curated+[v for v in cache['videos'] if v['id'] not in ids],key=lambda v:v['date'],reverse=True)
 stamp=(cache.get('fetchedAt') or '')[:10]
 body=f'''<header class="community-heading video-heading"><div><p class="eyebrow">WATCH. LEARN. TRY AGAIN.</p><h1>Raid videos</h1><p>Runs, team ideas and tutorials from Nihal, alongside selected videos from other creators.</p></div><a class="community-button" href="https://www.youtube.com/@Nihal-guardiantales/videos" target="_blank" rel="noopener noreferrer">Visit Nihal’s channel ↗</a></header><div class="video-controls"><label>Find a video<input id="video-search" type="search" placeholder="Boss, team, creator…"></label><label>Show<select id="video-source"><option value="all">All videos</option><option value="channel">Nihal’s latest videos</option><option value="curated">Community picks</option></select></label></div><p id="video-count" role="status">{len(videos)} videos</p><section class="video-grid" aria-label="Raid video library">{''.join(card(v) for v in videos)}</section><p id="video-empty" hidden>No videos match. Try another search or choose All videos.</p><footer class="community-footer"><p>Channel snapshot: {esc(stamp) if stamp else 'currently unavailable'}. Refreshed when the website is deployed. The channel link always leads to the newest uploads.</p><p>Players load only when you press Play. If a creator disables embedding, use Watch on YouTube.</p></footer>'''
 (D/'raid-videos.html').write_text(page('Raid videos',body),encoding='utf8')
 save(D/'data/raid-videos.json',{'fetchedAt':cache.get('fetchedAt'),'videos':videos})
 print('Built Contacts and Raid videos:',len(videos),'videos,',len(curated),'community picks')
if __name__=='__main__':main('--offline' in sys.argv)
