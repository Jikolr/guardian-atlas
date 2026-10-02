"""One-time migration; never overwrite an article already edited in the CMS."""
from pathlib import Path
import sys,json,re
B=Path(__file__).resolve().parent
sys.path.insert(0,str(B/'.editor-deps'))
from markdownify import markdownify
from bs4 import BeautifulSoup
out=B/'newsletter/posts';out.mkdir(exist_ok=True)
media=json.loads((B/'dist/data/visual/record-media.json').read_text(encoding='utf8'))
for p in json.loads((B/'newsletter/posts.json').read_text(encoding='utf8')):
    path=out/(p['slug']+'.json')
    if path.exists():continue
    html=(B/'newsletter'/p['body']).read_text(encoding='utf8')
    for token,ident in [('astoria_image','heroes:701'),('seira_image','heroes:695')]:
        html=html.replace('{{'+token+'}}','data/visual/'+media[ident]['image'])
    html=re.sub(r'&(?!#\d+;|#x[0-9a-fA-F]+;|[a-zA-Z]+;)', '&amp;', html)
    soup=BeautifulSoup(html,'html.parser')
    p['anchors']={h.get_text():h['id'] for h in soup.select('h2[id]')}
    # Captions are meaningful text, preserve them outside Markdown tables.
    for caption in soup.select('caption'):
        caption.parent.insert_before(soup.new_tag('p'))
        caption.parent.previous_sibling.string=caption.get_text()
        caption.decompose()
    p['body']=markdownify(str(soup),heading_style='ATX',bullets='-',strip=['span'])
    p['published']=True
    p['cover']='data/visual/'+media['heroes:701']['image'] if p['image']=='astoria' else ''
    path.write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
