"""Collect original website copy without rewriting game data or code."""
from pathlib import Path
from html.parser import HTMLParser
from html import unescape
import collections,gzip,hashlib,json,re,subprocess

ROOT=Path(__file__).parent
messages=collections.defaultdict(set)
def add(value,context,strict=False):
    value=re.sub(r'\s+',' ',unescape(value)).strip()
    if not value or not re.search('[A-Za-z]{2}',value) or len(value)>3000:return
    if re.fullmatch(r'[{}\d.,:;%+*/=<>|_\s-]+',value):return
    if value in {'GUARDIAN ATLAS','Guardian Atlas','Guardian Tales','use strict'}:return
    if re.match(r'^(?:https?:|data:|blob:|[.#][\w-]+|--[\w-]+)',value):return
    if re.fullmatch(r'[\w{}./?#=&+%:-]+\.(?:json|gz|webp|png|html|js|css|svg|zip|md|txt)(?:[?#].*)?',value):return
    if strict:
        if re.fullmatch(r'[\w{}./?#=&+%:-]+',value) and not re.match(r'^[A-Z][a-z]+(?: [A-Za-z]+)*$',value):return
        if re.search(r'(?:=>|document\.|querySelector|function\(|\.innerHTML|\[object)',value):return
        if re.search(r'(?:[\w-]+\s*=\s*["\']|prefers-reduced-motion|^window\.|^application/|^text/|^image/)',value):return
    messages[value].add(context)

class Copy(HTMLParser):
    def __init__(self,context,skip_articles=True):
        super().__init__(convert_charrefs=True);self.context=context;self.stack=[];self.skip_articles=skip_articles
    def handle_starttag(self,tag,attributes):
        attrs=dict(attributes);skip=tag in {'script','style','pre','code','textarea','svg'} or attrs.get('translate')=='no' or 'data-game-source' in attrs or 'data-i18n-ignore' in attrs or (self.skip_articles and 'article-body' in attrs.get('class','').split())
        inherited=any(row[1] for row in self.stack)
        if not skip and not inherited:
            for key in ('placeholder','title','aria-label','aria-description','alt'):
                if attrs.get(key):add(attrs[key],self.context+' @'+key)
        if tag not in {'area','base','br','col','embed','hr','img','input','link','meta','param','source','track','wbr'}:self.stack.append((tag,skip))
    def handle_startendtag(self,tag,attributes):self.handle_starttag(tag,attributes);self.handle_endtag(tag)
    def handle_endtag(self,tag):
        for i in range(len(self.stack)-1,-1,-1):
            if self.stack[i][0]==tag:self.stack=self.stack[:i];break
    def handle_data(self,value):
        if not any(row[1] for row in self.stack):add(value,self.context)

for file in sorted((ROOT/'dist').glob('*.html')):
    if file.name in {'logo-concepts.html','name-review.html'}:continue
    Copy(file.name).feed(file.read_text(encoding='utf8'))
for name in ('guide.html','index.html'):
    Copy('admin/'+name).feed((ROOT/'dist/admin'/name).read_text(encoding='utf8'))
raw=json.loads(subprocess.check_output(['node',str(ROOT/'extract_i18n_strings.cjs')],cwd=ROOT))
for row in raw:
    value=row['value'];context=row['file']+':'+str(row['line'])
    if re.search(r'<[A-Za-z/][^>]*>',value):Copy(context).feed(value)
    else:add(value,context,strict=True)

# Editorial copy is translated as complete Markdown, not fragmented DOM nodes.
editorial=set()
for file in (ROOT/'newsletter/posts').glob('*.json'):
    post=json.loads(file.read_text(encoding='utf8'))
    editorial.update([post['title'],post['summary'],post['title']+' · Guardian Atlas'])
for value in editorial:messages.pop(value,None)
profiles=json.loads(gzip.decompress((ROOT/'dist/data/characters.json.gz').read_bytes()))
for profile in profiles:
    if profile.get('name'):messages.pop(profile['name'],None)
for value in ['Language','Website language','Loading translation…','Translation could not be loaded. Please try again.','Original English','This article has changed since its translation. The original English is shown until the translation is updated.']:
    add(value,'site-language')
rows=[{'id':'m_'+hashlib.sha256(source.encode('utf8')).hexdigest()[:12],'source':source,'contexts':sorted(contexts)} for source,contexts in sorted(messages.items(),key=lambda item:item[0].lower())]
(ROOT/'i18n').mkdir(exist_ok=True)
(ROOT/'i18n/source.json').write_text(json.dumps({'messages':rows},ensure_ascii=False,indent=2),encoding='utf8')
chunks=ROOT/'i18n/source-chunks';chunks.mkdir(exist_ok=True)
for offset in range(0,len(rows),200):
    (chunks/f'{offset//200+1:02}.json').write_text(json.dumps(rows[offset:offset+200],ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({'messages':len(rows),'words':sum(len(row['source'].split()) for row in rows)}))
